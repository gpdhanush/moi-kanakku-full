/**
 * Admin authentication helpers — HttpOnly cookie sessions.
 *
 * JWTs are never stored in localStorage/sessionStorage. The API sets
 * HttpOnly cookies; the SPA keeps only non-sensitive user profile + CSRF
 * token in memory (CSRF is rehydrated via GET /users/admin/session).
 */

import { logger } from './logger';

export const MFA_PENDING_KEY = 'mfa_pending_login';

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

/** In-memory only — never persist JWTs here. */
let memoryUser: AdminUser | null = null;
let memoryCsrfToken: string | null = null;
let memoryMfaPending: MfaPendingLogin | null = null;

const LEGACY_AUTH_KEYS = [
  'auth_token',
  'refresh_token',
  'user',
  'remember_me',
] as const;

/** Remove legacy plaintext / encrypted token material from browser storage. */
export function purgeLegacyTokenStorage(): void {
  try {
    for (const key of LEGACY_AUTH_KEYS) {
      localStorage.removeItem(key);
    }
    // Obfuscated secureStorage keys cannot be enumerated reliably; wipe all
    // keys that look like our previous secure_ prefix blobs on first boot.
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
    // ignore storage access errors
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
}

export function getCurrentUser(): AdminUser | null {
  return memoryUser;
}

export async function getCurrentUserAsync(): Promise<AdminUser | null> {
  return memoryUser;
}

/** @deprecated Tokens are HttpOnly cookies — always null for SPA. */
export function getAuthToken(): string | null {
  return null;
}

/** @deprecated Tokens are HttpOnly cookies — always null for SPA. */
export async function getAuthTokenAsync(): Promise<string | null> {
  return null;
}

export function isAuthenticated(): boolean {
  return !!memoryUser?.id;
}

export function setMfaPendingLogin(payload: MfaPendingLogin): void {
  memoryMfaPending = {
    userId: String(payload.userId),
    accountType: payload.accountType || 'admin',
  };
  // Intentionally do not write sessionStorage (no auth secrets / session tokens).
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
  clearMfaPendingLogin();
  purgeLegacyTokenStorage();
}

/**
 * Persist non-sensitive session metadata after cookie-authenticated login.
 * `token` / `refreshToken` arguments are ignored (cookies are set by the API).
 */
export async function persistAdminSession(options: {
  user: unknown;
  csrfToken?: string | null;
  token?: string | null;
  refreshToken?: string | null;
}): Promise<void> {
  purgeLegacyTokenStorage();
  const raw = options.user && typeof options.user === 'object'
    ? (options.user as Record<string, unknown>)
    : {};
  const {
    token: _t,
    accessToken: _a,
    refreshToken: _r,
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

  setCsrfToken(
    options.csrfToken ??
      (typeof csrfFromUser === 'string' ? csrfFromUser : null),
  );
}

export async function forceLogout(reason?: string): Promise<void> {
  try {
    logger.warn('Force logout triggered', reason ? `Reason: ${reason}` : '');
    // Best-effort server cookie clear via raw fetch (avoid axios circular import).
    try {
      const { API_CONFIG } = await import('./config');
      await fetch(`${API_CONFIG.BASE_URL}/users/admin/logout`, {
        method: 'POST',
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
          ...(memoryCsrfToken ? { 'X-CSRF-Token': memoryCsrfToken } : {}),
        },
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
