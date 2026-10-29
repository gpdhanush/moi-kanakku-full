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
  persistAdminSession,
  purgeLegacyTokenStorage,
  setCsrfToken,
} from './auth';

describe('admin auth storage (cookie session)', () => {
  beforeEach(async () => {
    localStorage.clear();
    sessionStorage.clear();
    await clearAuth();
  });

  it('never persists JWT access/refresh tokens in localStorage or sessionStorage', async () => {
    localStorage.setItem('auth_token', 'legacy-jwt');
    localStorage.setItem('refresh_token', 'legacy-refresh');
    sessionStorage.setItem('mfa_pending_login', JSON.stringify({ sessionToken: 'x' }));

    await persistAdminSession({
      user: {
        id: '1',
        name: 'Admin',
        email: 'a@b.com',
        token: 'should-not-be-stored',
        accessToken: 'should-not-be-stored',
        refreshToken: 'should-not-be-stored',
      },
      csrfToken: 'csrf-memory-only',
      token: 'ignored-jwt',
      refreshToken: 'ignored-refresh',
    });

    purgeLegacyTokenStorage();

    expect(localStorage.getItem('auth_token')).toBeNull();
    expect(localStorage.getItem('refresh_token')).toBeNull();
    expect(sessionStorage.getItem('mfa_pending_login')).toBeNull();
    expect(getAuthToken()).toBeNull();
    await expect(getAuthTokenAsync()).resolves.toBeNull();

    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i) || '';
      const value = localStorage.getItem(key) || '';
      expect(value.includes('ignored-jwt')).toBe(false);
      expect(value.includes('should-not-be-stored')).toBe(false);
    }

    expect(getCsrfToken()).toBe('csrf-memory-only');
    expect(getCurrentUser()?.email).toBe('a@b.com');
    expect(getCurrentUser()?.token).toBeUndefined();
  });

  it('clears in-memory session on clearAuth', async () => {
    setCsrfToken('abc');
    await persistAdminSession({
      user: { id: '9', name: 'X', email: 'x@y.z' },
      csrfToken: 'abc',
    });
    await clearAuth();
    expect(getCurrentUser()).toBeNull();
    expect(getCsrfToken()).toBeNull();
  });
});
