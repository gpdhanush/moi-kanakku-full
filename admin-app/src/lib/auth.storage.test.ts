/**
 * @vitest-environment jsdom
 */
import { beforeEach, describe, expect, it } from 'vitest';
import {
  clearAuth,
  getAuthToken,
  getAuthTokenAsync,
  getCsrfToken,
  getCurrentUser,
  getRefreshToken,
  persistAdminSession,
  purgeLegacyTokenStorage,
  setCsrfToken,
} from './auth';

describe('admin auth storage (cookie + tab session)', () => {
  beforeEach(async () => {
    localStorage.clear();
    sessionStorage.clear();
    await clearAuth();
  });

  it('keeps access JWT in memory; refresh in memory + sessionStorage; never localStorage', async () => {
    localStorage.setItem('auth_token', 'legacy-jwt');
    localStorage.setItem('refresh_token', 'legacy-refresh');
    sessionStorage.setItem('mfa_pending_login', JSON.stringify({ sessionToken: 'x' }));

    await persistAdminSession({
      user: {
        id: '1',
        name: 'Admin',
        email: 'a@b.com',
      },
      csrfToken: 'csrf-memory-only',
      accessToken: 'memory-access-jwt',
      refreshToken: 'memory-refresh-jwt',
    });

    purgeLegacyTokenStorage();

    expect(localStorage.getItem('auth_token')).toBeNull();
    expect(localStorage.getItem('refresh_token')).toBeNull();
    expect(sessionStorage.getItem('mfa_pending_login')).toBeNull();
    expect(getAuthToken()).toBe('memory-access-jwt');
    await expect(getAuthTokenAsync()).resolves.toBe('memory-access-jwt');
    expect(getRefreshToken()).toBe('memory-refresh-jwt');
    expect(sessionStorage.getItem('__moi_admin_rt')).toBe('memory-refresh-jwt');

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i) || '';
      const value = localStorage.getItem(key) || '';
      expect(value.includes('memory-access-jwt')).toBe(false);
      expect(value.includes('memory-refresh-jwt')).toBe(false);
    }

    expect(getCsrfToken()).toBe('csrf-memory-only');
    expect(getCurrentUser()?.email).toBe('a@b.com');
  });

  it('clears in-memory and session refresh on clearAuth', async () => {
    setCsrfToken('abc');
    await persistAdminSession({
      user: { id: '9', name: 'X', email: 'x@y.z' },
      csrfToken: 'abc',
      refreshToken: 'rt-clear-me',
    });
    await clearAuth();
    expect(getCurrentUser()).toBeNull();
    expect(getCsrfToken()).toBeNull();
    expect(getRefreshToken()).toBeNull();
    expect(sessionStorage.getItem('__moi_admin_rt')).toBeNull();
  });
});
