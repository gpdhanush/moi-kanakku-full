/**
 * Admin authentication helpers.
 *
 * - Never write JWTs to localStorage.
 * - Prefer HttpOnly cookies when same-site.
 * - Keep access JWT in memory; keep refresh JWT in memory + sessionStorage
 *   (tab-scoped) so overnight / soft reloads can refresh without re-login.
 *   Closing the browser tab clears sessionStorage.
 */

import { logger } from './logger';

export const MFA_PENDING_KEY = 'mfa_pending_login';

/** Tab-scoped refresh persistence (not localStorage). Cleared on tab close. */
const REFRESH_SESSION_KEY = '__moi_admin_rt';
const USER_SESSION_KEY = '__moi_admin_user';

export type AdminUser = {
  id: string;
  name: string;
  email: string;
  mobile?: string;
  status?: string;
  last_login?: string;
  profile_image?: string | null;
  [key: string]: unknown;
};

export type MfaPendingLogin = {
  userId: string;
  accountType?: string;
};

let memoryUser: AdminUser | null = null;
let memoryCsrfToken: string | null = null;
let memoryAccessToken: string | null = null;
let memoryRefreshToken: string | null = null;
let memoryMfaPending: MfaPendingLogin | null = null;

const LEGACY_AUTH_KEYS = [
  'auth_token',
  'refresh_token',
  'user',
  'remember_me',
] as const;

function readSession(key: string): string | null {
  try {
    return sessionStorage.getItem(key);
  } catch {
    return null;
  }
}

function writeSession(key: string, value: string | null): void {
  try {
    if (value == null || value === '') sessionStorage.removeItem(key);
    else sessionStorage.setItem(key, value);
  } catch {
    // private mode / quota
  }
}

/** Hydrate memory from tab sessionStorage (runs once on module load). */
function hydrateFromSessionStorage(): void {
  const rt = readSession(REFRESH_SESSION_KEY);
  if (rt) memoryRefreshToken = rt;

  const rawUser = readSession(USER_SESSION_KEY);
  if (rawUser) {
    try {
      const parsed = JSON.parse(rawUser) as AdminUser;
      if (parsed?.id) memoryUser = parsed;
    } catch {
      writeSession(USER_SESSION_KEY, null);
    }
  }
}

hydrateFromSessionStorage();

/** Remove legacy plaintext / encrypted token material from browser storage. */
export function purgeLegacyTokenStorage(): void {
  try {
    for (const key of LEGACY_AUTH_KEYS) {
      localStorage.removeItem(key);
    }
    const toRemove: string[] = [];
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (!key) continue;
      if (
        key.startsWith('secure_') ||
        key === 'auth_token' ||
        key === 'refresh_token'
      ) {
        toRemove.push(key);
      }
    }
    toRemove.forEach((k) => localStorage.removeItem(k));
    sessionStorage.removeItem(MFA_PENDING_KEY);
    sessionStorage.removeItem('session_master_key');
  } catch {
    // ignore
  }
}

export function setCsrfToken(token: string | null | undefined): void {
  memoryCsrfToken = token && String(token).trim() ? String(token) : null;
}

export function getCsrfToken(): string | null {
  return memoryCsrfToken;
}

export function setCurrentUser(user: AdminUser | null): void {
  memoryUser = user;
  writeSession(USER_SESSION_KEY, user ? JSON.stringify(user) : null);
}

export function getCurrentUser(): AdminUser | null {
  return memoryUser;
}

export async function getCurrentUserAsync(): Promise<AdminUser | null> {
  return memoryUser;
}

export function getAuthToken(): string | null {
  return memoryAccessToken;
}

export async function getAuthTokenAsync(): Promise<string | null> {
  return memoryAccessToken;
}

export function getRefreshToken(): string | null {
  return memoryRefreshToken || readSession(REFRESH_SESSION_KEY);
}

export function isAuthenticated(): boolean {
  return !!(memoryUser?.id && (memoryAccessToken || getRefreshToken()));
}

export function setMfaPendingLogin(payload: MfaPendingLogin): void {
  memoryMfaPending = {
    userId: String(payload.userId),
    accountType: payload.accountType || 'admin',
  };
}

export function getMfaPendingLogin(): MfaPendingLogin | null {
  return memoryMfaPending;
}

export function clearMfaPendingLogin(): void {
  memoryMfaPending = null;
  try {
    sessionStorage.removeItem(MFA_PENDING_KEY);
  } catch {
    // ignore
  }
}

export async function clearAuth(): Promise<void> {
  memoryUser = null;
  memoryCsrfToken = null;
  memoryAccessToken = null;
  memoryRefreshToken = null;
  writeSession(REFRESH_SESSION_KEY, null);
  writeSession(USER_SESSION_KEY, null);
  clearMfaPendingLogin();
  purgeLegacyTokenStorage();
}

/**
 * Store session in memory (+ refresh/user in sessionStorage for tab continuity).
 * Never writes JWTs to localStorage.
 */
export async function persistAdminSession(options: {
  user: unknown;
  csrfToken?: string | null;
  token?: string | null;
  accessToken?: string | null;
  refreshToken?: string | null;
}): Promise<void> {
  purgeLegacyTokenStorage();
  const raw =
    options.user && typeof options.user === 'object'
      ? (options.user as Record<string, unknown>)
      : {};
  const {
    token: tokenFromUser,
    accessToken: accessFromUser,
    refreshToken: refreshFromUser,
    csrfToken: csrfFromUser,
    ...safeUser
  } = raw;

  memoryUser = {
    id: String(safeUser.id ?? ''),
    name: String(safeUser.name ?? safeUser.full_name ?? ''),
    email: String(safeUser.email ?? ''),
    mobile: safeUser.mobile != null ? String(safeUser.mobile) : undefined,
    status: safeUser.status != null ? String(safeUser.status) : undefined,
    last_login:
      safeUser.last_login != null
        ? String(safeUser.last_login)
        : safeUser.last_login_at != null
          ? String(safeUser.last_login_at)
          : undefined,
    profile_image:
      (safeUser.profile_image as string | null | undefined) ??
      (safeUser.profile_image_url as string | null | undefined) ??
      null,
    ...safeUser,
  };
  writeSession(USER_SESSION_KEY, JSON.stringify(memoryUser));

  const access =
    options.accessToken ||
    options.token ||
    (typeof accessFromUser === 'string' ? accessFromUser : null) ||
    (typeof tokenFromUser === 'string' ? tokenFromUser : null);
  memoryAccessToken = access && String(access).trim() ? String(access) : null;

  const refresh =
    options.refreshToken ||
    (typeof refreshFromUser === 'string' ? refreshFromUser : null);
  if (refresh && String(refresh).trim()) {
    memoryRefreshToken = String(refresh);
    writeSession(REFRESH_SESSION_KEY, memoryRefreshToken);
  }

  setCsrfToken(
    options.csrfToken ??
      (typeof csrfFromUser === 'string' ? csrfFromUser : null),
  );
}

export async function forceLogout(reason?: string): Promise<void> {
  try {
    logger.warn('Force logout triggered', reason ? `Reason: ${reason}` : '');
    try {
      const { API_CONFIG } = await import('./config');
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      };
      if (memoryCsrfToken) headers['X-CSRF-Token'] = memoryCsrfToken;
      if (memoryAccessToken) {
        headers.Authorization = `Bearer ${memoryAccessToken}`;
      }
      await fetch(`${API_CONFIG.BASE_URL}/users/admin/logout`, {
        method: 'POST',
        credentials: 'include',
        headers,
        body: '{}',
      });
    } catch {
      // still clear client state
    }
    await clearAuth();
    if (typeof window !== 'undefined') {
      const w = window as Window & {
        __REACT_QUERY_CLIENT__?: { clear: () => void };
      };
      w.__REACT_QUERY_CLIENT__?.clear();
    }
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
  } catch (error) {
    logger.error('Error during force logout:', error);
    await clearAuth();
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
  }
}
