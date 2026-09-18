export function formatDateTime(value?: string | null): string {
  if (!value) return "N/A";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "N/A";

  const day = String(date.getDate()).padStart(2, "0");
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];
  const month = months[date.getMonth()];
  const year = date.getFullYear();
  let hours = date.getHours();
  const minutes = String(date.getMinutes()).padStart(2, "0");
  const seconds = String(date.getSeconds()).padStart(2, "0");
  const ampm = hours >= 12 ? "PM" : "AM";
  hours = hours % 12 || 12;

  return `${day}-${month}-${year} ${String(hours).padStart(2, "0")}:${minutes}:${seconds} ${ampm}`;
}

export function formatDateOnly(value?: string | null): string {
  if (!value) return "N/A";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "N/A";
  const day = String(date.getDate()).padStart(2, "0");
  const months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];
  return `${day}-${months[date.getMonth()]}-${date.getFullYear()}`;
}

export function displayValue(value?: string | number | boolean | null): string {
  if (value === null || value === undefined || value === "") return "N/A";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  return String(value);
}

export function formatAmount(value?: string | number | null): string {
  if (value === null || value === undefined || value === "") return "N/A";
  const num = typeof value === "number" ? value : Number(value);
  if (Number.isNaN(num)) return String(value);
  return num.toLocaleString("en-IN", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}

export function formatAppStatus(value?: string | null, { device = false } = {}): string {
  const status = String(value || "UNKNOWN").toUpperCase();
  if (status === "ACTIVE") return device ? "Active" : "Installed";
  if (status === "INACTIVE") return "Inactive";
  if (status === "LIKELY_UNINSTALLED") return "Likely Uninstalled";
  return "Unknown";
}

export function appStatusClassName(value?: string | null): string {
  const status = String(value || "UNKNOWN").toUpperCase();
  if (status === "ACTIVE") return "bg-emerald-500/15 text-emerald-700 hover:bg-emerald-500/20";
  if (status === "INACTIVE") return "bg-amber-500/15 text-amber-800 hover:bg-amber-500/20";
  if (status === "LIKELY_UNINSTALLED") return "bg-rose-500/15 text-rose-700 hover:bg-rose-500/20";
  return "bg-slate-500/15 text-slate-700 hover:bg-slate-500/20";
}

export function formatLabel(value?: string | null): string {
  if (!value) return "N/A";
  return value
    .toLowerCase()
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function resolveImageUrl(path?: string | null): string | undefined {
  if (!path) return undefined;
  const trimmed = path.trim();
  if (!trimmed) return undefined;

  if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
    // Fix legacy /api/uploads and /apis/uploads mistakes
    if (trimmed.includes("/api/uploads/") || trimmed.includes("/apis/uploads/")) {
      try {
        const url = new URL(trimmed);
        url.pathname = url.pathname
          .replace("/apis/uploads/", "/uploads/")
          .replace("/api/uploads/", "/uploads/");
        return url.toString();
      } catch {
        return trimmed;
      }
    }
    return trimmed;
  }

  if (trimmed.startsWith("data:")) return trimmed;

  const base = (
    import.meta.env.VITE_STATIC_URL ||
    // Fall back to API host without /apis suffix
    (import.meta.env.VITE_API_URL || "")
      .replace(/\/apis\/?$/, "")
      .replace(/\/api\/?$/, "")
  ).replace(/\/$/, "");

  if (!base) return undefined;

  let cleanPath = trimmed.replace(/^\/apis\/uploads\//, "/uploads/");
  cleanPath = cleanPath.replace(/^\/api\/uploads\//, "/uploads/");
  const normalized = cleanPath.startsWith("/") ? cleanPath : `/${cleanPath}`;
  return `${base}${normalized}`;
}
