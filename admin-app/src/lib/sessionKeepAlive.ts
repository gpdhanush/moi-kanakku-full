import { getAuthToken, getRefreshToken, isAuthenticated } from './auth';
import { isAccessTokenExpiringSoon } from './jwtExpiry';
import { ensureFreshAccessToken } from './axios';
import { logger } from './logger';

let refreshTimer: ReturnType<typeof setTimeout> | null = null;
let started = false;

function clearRefreshTimer(): void {
  if (refreshTimer) {
    clearTimeout(refreshTimer);
    refreshTimer = null;
  }
}

/**
 * Schedule a silent refresh ~60s before access JWT expiry.
 */
export function scheduleAccessTokenRefresh(): void {
  clearRefreshTimer();
  const access = getAuthToken();
  if (!access || !getRefreshToken()) return;

  try {
    const parts = access.split('.');
    if (parts.length < 2) return;
    const payload = JSON.parse(
      atob(parts[1].replace(/-/g, '+').replace(/_/g, '/'))
    ) as { exp?: number };
    if (typeof payload.exp !== 'number') return;

    const refreshAt = payload.exp * 1000 - 60_000;
    const delay = Math.max(5_000, refreshAt - Date.now());

    refreshTimer = setTimeout(() => {
      void ensureFreshAccessToken(true)
        .then(() => scheduleAccessTokenRefresh())
        .catch((err) => {
          logger.warn('Scheduled token refresh failed', err);
        });
    }, delay);
  } catch {
    // ignore decode errors
  }
}

async function onVisibilityOrFocus(): Promise<void> {
  if (document.visibilityState === 'hidden') return;
  if (!isAuthenticated() && !getRefreshToken()) return;

  if (isAccessTokenExpiringSoon(getAuthToken(), 120_000) || !getAuthToken()) {
    try {
      await ensureFreshAccessToken(true);
      scheduleAccessTokenRefresh();
    } catch {
      // ensureFreshAccessToken / axios may forceLogout on hard failure
    }
  }
}

/**
 * Start overnight / idle keep-alive: proactive refresh + refresh on tab focus.
 * Call once from App bootstrap.
 */
export function startSessionKeepAlive(): void {
  if (started || typeof window === 'undefined') return;
  started = true;

  scheduleAccessTokenRefresh();

  document.addEventListener('visibilitychange', () => {
    void onVisibilityOrFocus();
  });
  window.addEventListener('focus', () => {
    void onVisibilityOrFocus();
  });

  // Immediate: if we only have a refresh token (after soft reload), mint access.
  void onVisibilityOrFocus();
}
