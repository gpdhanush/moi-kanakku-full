import type { PersonItem } from "@/features/persons/api";
import type { TransactionFunctionItem } from "@/features/transaction-functions/api";
import type { TransactionItem } from "@/features/transactions/api";
import type { UpcomingFunctionItem } from "@/features/upcoming-functions/api";
import type { UserDetail } from "@/features/users/api";
import {
  displayValue,
  formatAmount,
  formatDateOnly,
  formatDateTime,
  formatLabel,
} from "@/lib/formatters";

export interface UserDetailsPdfData {
  user: UserDetail;
  persons: PersonItem[];
  functions: TransactionFunctionItem[];
  transactions: TransactionItem[];
  upcomingFunctions: UpcomingFunctionItem[];
}

export interface UserDetailsPdfOptions {
  watermark?: boolean;
}

function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function cell(value: unknown): string {
  return `<td>${escapeHtml(value)}</td>`;
}

function table(title: string, headers: string[], rows: string[][]): string {
  const body = rows.length
    ? rows.map((row) => `<tr>${row.join("")}</tr>`).join("")
    : `<tr><td class="empty" colspan="${headers.length}">No records found</td></tr>`;

  return `
    <section class="report-section">
      <h2>${escapeHtml(title)} <span>${rows.length}</span></h2>
      <table>
        <thead><tr>${headers.map((header) => `<th>${escapeHtml(header)}</th>`).join("")}</tr></thead>
        <tbody>${body}</tbody>
      </table>
    </section>`;
}

function details(
  title: string,
  fields: Array<[string, unknown]>,
  tone: "blue" | "violet",
): string {
  return `
    <section class="report-section details-section tone-${tone}">
      <h2>${escapeHtml(title)}</h2>
      <div class="details-grid">
        ${fields
          .map(
            ([label, value]) =>
              `<div><dt>${escapeHtml(label)}</dt><dd>${escapeHtml(value)}</dd></div>`,
          )
          .join("")}
      </div>
    </section>`;
}

function buildDocument(
  {
    user,
    persons,
    functions,
    transactions,
    upcomingFunctions,
  }: UserDetailsPdfData,
  { watermark = false }: UserDetailsPdfOptions,
): string {
  const profile = user.profile;
  const generatedAt = formatDateTime(new Date().toISOString());
  const safeName = user.name?.trim() || "User";

  const userDetails = details(
    "Personal Information",
    [
      ["Full Name", displayValue(user.name)],
      ["Email", displayValue(user.email)],
      ["Mobile", displayValue(user.mobile)],
      ["City", displayValue(profile?.city)],
      ["Status", formatLabel(user.status)],
      ["Last Login", formatDateTime(user.last_login)],
    ],
    "blue",
  );

  const addressDetails = details(
    "Address",
    [
      ["Address Line 1", displayValue(profile?.address_line1)],
      ["Address Line 2", displayValue(profile?.address_line2)],
      ["City", displayValue(profile?.city)],
      ["State", displayValue(profile?.state)],
      ["Country", displayValue(profile?.country)],
      ["Postal Code", displayValue(profile?.postal_code)],
    ],
    "violet",
  );

  const personDetails = table(
    "Persons",
    [
      "#",
      "First Name",
      "Second Name",
      "Business",
      "City",
      "Mobile",
      "Created At",
    ],
    persons.map((person, index) => [
      cell(index + 1),
      cell(displayValue(person.firstName)),
      cell(displayValue(person.secondName)),
      cell(displayValue(person.business)),
      cell(displayValue(person.city)),
      cell(displayValue(person.mobile)),
      cell(formatDateTime(person.createdAt)),
    ]),
  );

  const functionDetails = table(
    "Functions",
    ["#", "Function Name", "Function Date", "Location", "Notes", "Created At"],
    functions.map((item, index) => [
      cell(index + 1),
      cell(displayValue(item.functionName)),
      cell(formatDateOnly(item.functionDate)),
      cell(displayValue(item.location)),
      cell(displayValue(item.notes)),
      cell(formatDateTime(item.createdAt)),
    ]),
  );

  const upcomingDetails = table(
    "Upcoming Functions",
    ["#", "Title", "Date", "Location", "Status", "Description", "Created At"],
    upcomingFunctions.map((item, index) => [
      cell(index + 1),
      cell(displayValue(item.title)),
      cell(formatDateOnly(item.functionDate)),
      cell(displayValue(item.location)),
      cell(formatLabel(item.status)),
      cell(displayValue(item.description)),
      cell(formatDateTime(item.createdAt)),
    ]),
  );

  const transactionDetails = table(
    "Transactions",
    [
      "#",
      "Function",
      "Date",
      "Type",
      "Amount",
      "Person",
      "Notes",
      "Created At",
    ],
    transactions.map((item, index) => [
      cell(index + 1),
      cell(displayValue(item.transactionFunctionName || item.function?.name)),
      cell(formatDateOnly(item.transactionDate)),
      cell(formatLabel(item.type)),
      cell(formatAmount(item.amount)),
      cell(
        displayValue(
          [item.person?.firstName, item.person?.lastName]
            .filter(Boolean)
            .join(" "),
        ),
      ),
      cell(displayValue(item.notes || item.itemName)),
      cell(formatDateTime(item.createdAt)),
    ]),
  );

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Moi Kanakku - ${escapeHtml(safeName)}</title>
  <style>
    @page { size: A4 landscape; margin: 12mm; }
    * { box-sizing: border-box; }
    body { margin: 0; color: #172033; font-family: Arial, sans-serif; font-size: 10px; }
    header { border-bottom: 3px solid #2563eb; margin-bottom: 16px; padding-bottom: 16px; }
    .brand-line { align-items: center; display: flex; gap: 14px; }
    .brand-logo { height: 56px; object-fit: contain; width: 56px; }
    .brand-wordmark { height: 42px; max-width: 280px; object-fit: contain; }
    .report-content { position: relative; z-index: 1; }
    .watermark { align-items: center; background: rgba(37, 99, 235, 0.08); border: 1px solid rgba(37, 99, 235, 0.24); border-radius: 999px; bottom: 4mm; color: #1d4ed8; display: flex; font-size: 9px; font-weight: 700; gap: 6px; justify-content: center; left: 50%; letter-spacing: 1.5px; opacity: 0.9; padding: 4px 12px; position: fixed; text-align: center; text-transform: uppercase; transform: translateX(-50%); z-index: 3; }
    .watermark img { height: 20px; object-fit: contain; width: 20px; }
    h1 { font-size: 28px; margin: 9px 0 4px; }
    .meta { color: #64748b; font-size: 10px; }
    .summary { display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px; margin: 14px 0 20px; }
    .summary-card { border: 0; border-radius: 10px; color: white; min-height: 72px; padding: 12px 14px; }
    .summary-card strong { display: block; font-size: 22px; line-height: 1.1; }
    .summary-card span { color: rgba(255,255,255,0.88); display: block; font-size: 9px; font-weight: 700; letter-spacing: 0.8px; margin-top: 7px; text-transform: uppercase; }
    .card-blue { background: linear-gradient(135deg, #2563eb, #1d4ed8); }
    .card-emerald { background: linear-gradient(135deg, #059669, #047857); }
    .card-violet { background: linear-gradient(135deg, #7c3aed, #6d28d9); }
    .card-rose { background: linear-gradient(135deg, #e11d48, #be123c); }
    .card-amber { background: linear-gradient(135deg, #d97706, #b45309); }
    .report-section { break-inside: avoid; margin: 0 0 18px; }
    h2 { border-bottom: 0; color: #1e40af; font-size: 14px; margin: 0 0 10px; padding-bottom: 0; }
    h2 span { color: #64748b; font-size: 10px; font-weight: normal; }
    .details-section { background: #f8fafc; border: 1px solid #dbe4f0; border-radius: 10px; padding: 12px; }
    .details-section h2 { border-left: 4px solid #2563eb; padding-left: 8px; }
    .details-section.tone-violet h2 { border-left-color: #7c3aed; color: #6d28d9; }
    .details-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
    .details-grid div { background: white; border: 1px solid #e2e8f0; border-radius: 7px; min-height: 42px; padding: 7px 9px; }
    dt { color: #64748b; font-size: 8px; font-weight: 700; text-transform: uppercase; }
    dd { margin: 3px 0 0; overflow-wrap: anywhere; }
    table { border-collapse: collapse; table-layout: auto; width: 100%; }
    th, td { border: 1px solid #cbd5e1; padding: 5px 6px; text-align: left; vertical-align: top; }
    th { background: #2563eb; color: white; font-size: 8px; text-transform: uppercase; }
    td { font-size: 9px; overflow-wrap: anywhere; }
    tr:nth-child(even) td { background: #f8fafc; }
    .empty { color: #64748b; text-align: center; }
    footer { border-top: 1px solid #cbd5e1; color: #64748b; font-size: 8px; margin-top: 18px; padding-bottom: 16px; padding-top: 7px; }
    @media print { .report-section { break-inside: auto; } tr { break-inside: avoid; } .watermark { position: fixed; } }
  </style>
</head>
<body>
  ${watermark ? '<div class="watermark"><img src="/logo-new.png" alt="" /><span>Moi Kanakku</span></div>' : ""}
  <div class="report-content">
    <header>
      <div class="brand-line">
        <img src="/logo-new.png" alt="" class="brand-logo" />
        <img src="/label-dark.png" alt="Moi Kanakku" class="brand-wordmark" />
      </div>
      <h1>User Name: ${escapeHtml(safeName)}</h1>
      <div class="meta">Generated on ${escapeHtml(generatedAt)}</div>
    </header>
    <div class="summary">
      <div class="summary-card card-blue"><strong>${persons.length}</strong><span>Persons</span></div>
      <div class="summary-card card-emerald"><strong>${functions.length}</strong><span>Functions</span></div>
      <div class="summary-card card-violet"><strong>${upcomingFunctions.length}</strong><span>Upcoming</span></div>
      <div class="summary-card card-rose"><strong>${transactions.length}</strong><span>Transactions</span></div>
      <div class="summary-card card-amber"><strong>${escapeHtml(formatAmount(transactions.reduce((total, item) => total + (Number(item.amount) || 0), 0)))}</strong><span>Total Amount</span></div>
    </div>
    ${userDetails}
    ${addressDetails}
    ${personDetails}
    ${functionDetails}
    ${upcomingDetails}
    ${transactionDetails}
    <footer>Confidential administrative export · Moi Kanakku · G.K Tech</footer>
  </div>
</body>
</html>`;
}

export function exportUserDetailsToPDF(
  data: UserDetailsPdfData,
  options: UserDetailsPdfOptions = {},
): void {
  const printWindow = window.open("", "_blank", "width=1200,height=800");
  if (!printWindow) {
    throw new Error(
      "The PDF window was blocked. Please allow pop-ups and try again.",
    );
  }

  printWindow.document.open();
  printWindow.document.write(buildDocument(data, options));
  printWindow.document.close();
  printWindow.focus();
  printWindow.addEventListener("load", () => {
    printWindow.print();
  });
}
