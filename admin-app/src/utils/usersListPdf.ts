import type { UserListItem } from "@/features/users/api";
import { displayValue, formatDateTime } from "@/lib/formatters";

export interface UsersListPdfOptions {
  title?: string;
  subtitle?: string;
}

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function toUpperDisplay(value?: string | number | boolean | null): string {
  const text = displayValue(value);
  return text === "N/A" ? text : text.toUpperCase();
}

function formatBrandModel(user: UserListItem): string {
  const brand = String(user.brand ?? "").trim();
  const model = String(user.model ?? "").trim();
  const combined = [brand, model].filter(Boolean).join(" ");
  if (combined) return combined;
  return displayValue(user.device_name);
}

function resolveEmail(user: UserListItem): string {
  const email = String(
    user.email ?? (user as { um_email?: string | null }).um_email ?? "",
  ).trim();
  return email || "N/A";
}

function isEmailVerified(user: UserListItem): boolean {
  const value = user.is_verified;
  if (typeof value === "boolean") return value;
  if (typeof value === "number") return value === 1;
  if (typeof value === "string") {
    const normalized = String(value).trim().toLowerCase();
    return ["1", "true", "yes", "y"].includes(normalized);
  }
  return false;
}

function resolveStatus(user: UserListItem): string {
  const status = String(user.status || "ACTIVE")
    .trim()
    .toUpperCase();
  return status || "ACTIVE";
}

function statusBadge(status: string): string {
  const tone =
    status === "ACTIVE"
      ? "badge-active"
      : status === "INACTIVE"
        ? "badge-inactive"
        : status === "BLOCKED"
          ? "badge-blocked"
          : status === "DELETED"
            ? "badge-deleted"
            : "badge-default";
  return `<span class="badge ${tone}">${escapeHtml(status)}</span>`;
}

function emailCell(user: UserListItem): string {
  const email = resolveEmail(user);
  const verified = isEmailVerified(user) && email !== "N/A";
  return `
    <span class="email-cell">
      <span>${escapeHtml(email)}</span>
      ${
        verified
          ? '<span class="verified-tick" title="Email verified">✓</span>'
          : ""
      }
    </span>`;
}

function buildDocument(
  users: UserListItem[],
  { title = "Users List", subtitle }: UsersListPdfOptions,
): string {
  const generatedAt = formatDateTime(new Date().toISOString());
  const withEmail = users.filter((user) => resolveEmail(user) !== "N/A").length;
  const activeCount = users.filter(
    (user) => resolveStatus(user) === "ACTIVE",
  ).length;
  const withDevice = users.filter((user) => {
    const brand = String(user.brand ?? "").trim();
    const model = String(user.model ?? "").trim();
    const deviceName = String(user.device_name ?? "").trim();
    return Boolean(brand || model || deviceName);
  }).length;

  const rows = users
    .map((user, index) => {
      const status = resolveStatus(user);
      return `
        <tr>
          <td class="col-sno">${escapeHtml(index + 1)}</td>
          <td class="col-name">
            <div class="name-cell">
              <strong>${escapeHtml(toUpperDisplay(user.name))}</strong>
            </div>
          </td>
          <td class="col-status">${statusBadge(status)}</td>
          <td class="col-email">${emailCell(user)}</td>
          <td class="col-mobile">${escapeHtml(displayValue(user.mobile))}</td>
          <td class="col-city">${escapeHtml(toUpperDisplay(user.city))}</td>
          <td class="col-device">${escapeHtml(formatBrandModel(user))}</td>
        </tr>`;
    })
    .join("");

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Moi Kanakku - ${escapeHtml(title)}</title>
  <style>
    @page { size: A4 landscape; margin: 10mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      color: #0f172a;
      font-family: Inter, Segoe UI, Arial, sans-serif;
      font-size: 10px;
      background: #ffffff;
    }
    .report-content { position: relative; z-index: 1; }
    header {
      align-items: center;
      border-bottom: 3px solid #2563eb;
      display: flex;
      gap: 20px;
      justify-content: space-between;
      margin-bottom: 14px;
      padding-bottom: 14px;
    }
    .header-left {
      align-items: flex-start;
      display: flex;
      flex: 1 1 auto;
      flex-direction: column;
      justify-content: center;
      text-align: left;
    }
    .header-right {
      align-items: center;
      display: flex;
      flex: 0 0 auto;
      gap: 12px;
      justify-content: flex-end;
    }
    .brand-logo { height: 56px; object-fit: contain; width: 56px; }
    .brand-wordmark { height: 40px; max-width: 280px; object-fit: contain; }
    .header-copy h1 {
      font-size: 24px;
      letter-spacing: -0.02em;
      margin: 0 0 4px;
    }
    .meta { color: #64748b; font-size: 10px; line-height: 1.45; }
    .summary {
      display: grid;
      gap: 10px;
      grid-template-columns: repeat(4, 1fr);
      margin: 0 0 16px;
    }
    .summary-card {
      border: 0;
      border-radius: 12px;
      color: white;
      min-height: 68px;
      padding: 12px 14px;
    }
    .summary-card strong {
      display: block;
      font-size: 22px;
      line-height: 1.1;
    }
    .summary-card span {
      color: rgba(255,255,255,0.9);
      display: block;
      font-size: 9px;
      font-weight: 700;
      letter-spacing: 0.8px;
      margin-top: 7px;
      text-transform: uppercase;
    }
    .card-blue { background: linear-gradient(135deg, #2563eb, #1d4ed8); }
    .card-emerald { background: linear-gradient(135deg, #059669, #047857); }
    .card-violet { background: linear-gradient(135deg, #7c3aed, #6d28d9); }
    .card-amber { background: linear-gradient(135deg, #d97706, #b45309); }
    .table-shell {
      background: #f8fafc;
      border: 1px solid #dbe4f0;
      border-radius: 14px;
      overflow: hidden;
      padding: 10px;
    }
    table {
      border-collapse: collapse;
      table-layout: fixed;
      width: 100%;
    }
    th, td {
      border: 1px solid #cbd5e1;
      padding: 7px 8px;
      text-align: left;
      vertical-align: middle;
      word-break: break-word;
    }
    th {
      background: linear-gradient(135deg, #1d4ed8, #2563eb);
      color: white;
      font-size: 8px;
      letter-spacing: 0.6px;
      text-transform: uppercase;
    }
    td { background: white; font-size: 9.5px; }
    tr:nth-child(even) td { background: #f8fafc; }
    .col-sno { text-align: center; width: 48px; }
    .col-name { width: 16%; }
    .col-status { text-align: center; width: 11%; }
    .col-email { width: 22%; }
    .col-mobile { width: 12%; }
    .col-city { width: 12%; }
    .col-device { width: 18%; }
    .name-cell strong { color: #0f172a; font-size: 10px; }
    .email-cell {
      align-items: center;
      display: inline-flex;
      gap: 6px;
      max-width: 100%;
    }
    .verified-tick {
      align-items: center;
      background: #dcfce7;
      border: 1px solid #86efac;
      border-radius: 999px;
      color: #15803d;
      display: inline-flex;
      flex-shrink: 0;
      font-size: 11px;
      font-weight: 800;
      height: 16px;
      justify-content: center;
      line-height: 1;
      width: 16px;
    }
    .badge {
      border-radius: 999px;
      display: inline-block;
      font-size: 8px;
      font-weight: 700;
      letter-spacing: 0.4px;
      padding: 3px 8px;
      text-transform: uppercase;
    }
    .badge-active { background: #dcfce7; color: #166534; }
    .badge-inactive { background: #fef3c7; color: #92400e; }
    .badge-blocked { background: #fee2e2; color: #991b1b; }
    .badge-deleted { background: #e2e8f0; color: #334155; }
    .badge-default { background: #e0e7ff; color: #3730a3; }
    .empty {
      color: #64748b;
      padding: 28px 12px;
      text-align: center;
    }
    footer {
      border-top: 1px solid #cbd5e1;
      color: #64748b;
      font-size: 8px;
      margin-top: 14px;
      padding-bottom: 10px;
      padding-top: 8px;
    }
    @media print {
      tr { break-inside: avoid; }
    }
  </style>
</head>
<body>
  <div class="report-content">
    <header>
      <div class="header-left header-copy">
        <h1>${escapeHtml(title)}</h1>
        <div class="meta">
          Generated on ${escapeHtml(generatedAt)}
          ${subtitle ? `<br />${escapeHtml(subtitle)}` : ""}
        </div>
      </div>
      <div class="header-right">
        <img src="/logo-new.png" alt="" class="brand-logo" />
        <img src="/label-dark.png" alt="Moi Kanakku" class="brand-wordmark" />
      </div>
    </header>

    <div class="summary">
      <div class="summary-card card-blue"><strong>${users.length}</strong><span>Total Users</span></div>
      <div class="summary-card card-emerald"><strong>${activeCount}</strong><span>Active Users</span></div>
      <div class="summary-card card-violet"><strong>${withEmail}</strong><span>With Email</span></div>
      <div class="summary-card card-amber"><strong>${withDevice}</strong><span>With Device Info</span></div>
    </div>

    <section class="table-shell">
      <table>
        <thead>
          <tr>
            <th class="col-sno">S.No</th>
            <th class="col-name">Full Name</th>
            <th class="col-status">Status</th>
            <th class="col-email">Email</th>
            <th class="col-mobile">Mobile</th>
            <th class="col-city">City</th>
            <th class="col-device">Brand &amp; Model</th>
          </tr>
        </thead>
        <tbody>
          ${
            rows ||
            `<tr><td class="empty" colspan="7">No users found for this export.</td></tr>`
          }
        </tbody>
      </table>
    </section>

    <footer>Confidential administrative export · Moi Kanakku · G.K Tech</footer>
  </div>
</body>
</html>`;
}

export function exportUsersListToPDF(
  users: UserListItem[],
  options: UsersListPdfOptions = {},
): void {
  const printWindow = window.open("", "_blank", "width=1280,height=860");
  if (!printWindow) {
    throw new Error(
      "The PDF window was blocked. Please allow pop-ups and try again.",
    );
  }

  printWindow.document.open();
  printWindow.document.write(buildDocument(users, options));
  printWindow.document.close();
  printWindow.focus();
  printWindow.addEventListener("load", () => {
    printWindow.print();
  });
}
