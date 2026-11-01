import type { TransactionItem } from "@/features/transactions/api";

export const userPath = (userId: string) =>
  `/users/${encodeURIComponent(userId)}`;
export const personPath = (userId: string, personId: string) =>
  `${userPath(userId)}/persons/${encodeURIComponent(personId)}`;
export const functionPath = (userId: string, functionId: string) =>
  `${userPath(userId)}/functions/${encodeURIComponent(functionId)}`;
export const transactionPath = (userId: string, transactionId: string) =>
  `${userPath(userId)}/transactions/${encodeURIComponent(transactionId)}`;

export function personFullName(
  person?: { firstName?: string | null; secondName?: string | null } | null,
): string {
  return (
    [person?.firstName, person?.secondName].filter(Boolean).join(" ") || "N/A"
  );
}

export function transactionPersonName(row: TransactionItem): string {
  return (
    [row.person?.firstName, row.person?.lastName].filter(Boolean).join(" ") ||
    "N/A"
  );
}

export function isReturnType(type?: string | null): boolean {
  return (type || "").toUpperCase() === "RETURN";
}
