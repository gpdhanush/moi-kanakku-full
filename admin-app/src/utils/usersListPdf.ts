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
    const normalized = value.trim().toLowerCase();
    return ["1", "true", "yes", "y"].includes(normalized);
  }
  return false;
}

function verifiedBadge(verified: boolean): string {
  return verified
    ? `<span class="badge badge-yes">Verified</span>`
    : `<span class="badge badge-no">Not Verified</span>`;
}

function buildDocument(
  users: UserListItem[],
  { title = "Users Directory", subtitle }: UsersListPdfOptions,
): string {
  const generatedAt = formatDateTime(new Date().toISOString());
  const withEmail = users.filter((user) => resolveEmail(user) !== "N/A").length;
  const verifiedCount = users.filter((user) => isEmailVerified(user)).length;
  const withDevice = users.filter((user) => {
    const brand = String(user.brand ?? "").trim();
    const model = String(user.model ?? "").trim();
    const deviceName = String(user.device_name ?? "").trim();
    return Boolean(brand || model || deviceName);
  }).length;

  const rows = users
    .map((user, index) => {
      const verified = isEmailVerified(user);
      return `
        <tr>
          <td class="col-sno">${escapeHtml(index + 1)}</td>
          <td class="col-name">
            <div class="name-cell">
              <strong>${escapeHtml(displayValue(user.name))}</strong>
            </div>
          </td>
          <td class="col-email">${escapeHtml(resolveEmail(user))}</td>
          <td class="col-mobile">${escapeHtml(displayValue(user.mobile))}</td>
          <td class="col-city">${escapeHtml(displayValue(user.city))}</td>
          <td class="col-device">${escapeHtml(formatBrandModel(user))}</td>
          <td class="col-verified">${verifiedBadge(verified)}</td>
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
      align-items: flex-end;
      border-bottom: 3px solid #2563eb;
      display: flex;
      gap: 18px;
      justify-content: space-between;
      margin-bottom: 14px;
      padding-bottom: 14px;
    }
    .brand-line { align-items: center; display: flex; gap: 14px; }
    .brand-logo { height: 52px; object-fit: contain; width: 52px; }
    .brand-wordmark { height: 38px; max-width: 260px; object-fit: contain; }
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
    .section-title {
      align-items: center;
      color: #1e40af;
      display: flex;
      font-size: 13px;
      gap: 8px;
      margin: 0 0 10px;
    }
    .section-title span {
      background: #dbeafe;
      border-radius: 999px;
      color: #1d4ed8;
      font-size: 10px;
      font-weight: 700;
      padding: 2px 8px;
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
    .col-sno { text-align: center; width: 36px; }
    .col-name { width: 16%; }
    .col-email { width: 22%; }
    .col-mobile { width: 12%; }
    .col-city { width: 12%; }
    .col-device { width: 18%; }
    .col-verified { text-align: center; width: 12%; }
    .name-cell strong { color: #0f172a; font-size: 10px; }
    .badge {
      border-radius: 999px;
      display: inline-block;
      font-size: 8px;
      font-weight: 700;
      letter-spacing: 0.4px;
      padding: 3px 8px;
      text-transform: uppercase;
    }
    .badge-yes {
      background: #dcfce7;
      color: #166534;
    }
    .badge-no {
      background: #fee2e2;
      color: #991b1b;
    }
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
      <div>
        <div class="brand-line">
          <img src="/logo-new.png" alt="" class="brand-logo" />
          <img src="/label-dark.png" alt="Moi Kanakku" class="brand-wordmark" />
        </div>
        <div class="header-copy" style="margin-top: 10px;">
          <h1>${escapeHtml(title)}</h1>
          <div class="meta">
            Generated on ${escapeHtml(generatedAt)}
            ${subtitle ? `<br />${escapeHtml(subtitle)}` : ""}
          </div>
        </div>
      </div>
    </header>

    <div class="summary">
      <div class="summary-card card-blue"><strong>${users.length}</strong><span>Total Users</span></div>
      <div class="summary-card card-emerald"><strong>${withEmail}</strong><span>With Email</span></div>
      <div class="summary-card card-violet"><strong>${verifiedCount}</strong><span>Email Verified</span></div>
      <div class="summary-card card-amber"><strong>${withDevice}</strong><span>With Device Info</span></div>
    </div>

    <section class="table-shell">
      <h2 class="section-title">
        User Directory
        <span>${users.length}</span>
      </h2>
      <table>
        <thead>
          <tr>
            <th class="col-sno">#</th>
            <th class="col-name">Full Name</th>
            <th class="col-email">Email</th>
            <th class="col-mobile">Mobile</th>
            <th class="col-city">City</th>
            <th class="col-device">Brand &amp; Model</th>
            <th class="col-verified">Email Verified</th>
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
