/** Local preferences for theme color and session timeout (no profile API on MOI admin). */

export const THEME_COLOR_KEY = "theme-color";
export const SESSION_TIMEOUT_KEY = "session_timeout";
export const SESSION_TIMEOUT_CHANGED_EVENT = "session-timeout-changed";

export const DEFAULT_THEME_COLOR = "217 91% 60%";
export const DEFAULT_SESSION_TIMEOUT = 60;
export const MIN_SESSION_TIMEOUT = 1;
export const MAX_SESSION_TIMEOUT = 1440;

export function getThemeColor(): string {
  return localStorage.getItem(THEME_COLOR_KEY) || DEFAULT_THEME_COLOR;
}

export function applyThemeColor(colorValue: string) {
  const root = document.documentElement;
  root.style.setProperty("--primary", colorValue);
  root.style.setProperty("--ring", colorValue);
  root.style.setProperty("--sidebar-primary", colorValue);
  root.style.setProperty("--sidebar-ring", colorValue);
  root.style.setProperty("--chart-1", colorValue);
  localStorage.setItem(THEME_COLOR_KEY, colorValue);
}

export function getSessionTimeout(): number {
  const raw = localStorage.getItem(SESSION_TIMEOUT_KEY);
  const parsed = raw ? Number(raw) : DEFAULT_SESSION_TIMEOUT;
  if (!Number.isFinite(parsed)) return DEFAULT_SESSION_TIMEOUT;
  return Math.min(MAX_SESSION_TIMEOUT, Math.max(MIN_SESSION_TIMEOUT, parsed));
}

export function setSessionTimeout(minutes: number) {
  const value = Math.min(
    MAX_SESSION_TIMEOUT,
    Math.max(MIN_SESSION_TIMEOUT, Math.round(minutes))
  );
  localStorage.setItem(SESSION_TIMEOUT_KEY, String(value));
  window.dispatchEvent(
    new CustomEvent(SESSION_TIMEOUT_CHANGED_EVENT, { detail: value })
  );
  return value;
}
