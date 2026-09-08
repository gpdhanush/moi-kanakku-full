/**
 * Authentication helpers — encrypted localStorage via secureStorage
 */

import { getItemSync, secureStorageWithCache } from './secureStorage';
import { logger } from './logger';

export const MFA_PENDING_KEY = 'mfa_pending_login';

export type MfaPendingLogin = {
  userId: string;
  accountType?: string;
  sessionToken?: string;
  user?: {
    id: string;
    name: string;
    email: string;
    mobile: string;
    status: string;
    last_login: string;
    profile_image: string | null;
  };
};

export function getCurrentUser(): any | null {
  const userStr = getItemSync('user');
  if (!userStr) return null;
  try {
    return JSON.parse(userStr);
  } catch (error) {
    logger.error('Error parsing user data:', error);
    return null;
  }
}

export async function getCurrentUserAsync(): Promise<any | null> {
  const userStr = await secureStorageWithCache.getItem('user');
  if (!userStr) return null;
  try {
    return JSON.parse(userStr);
  } catch (error) {
    logger.error('Error parsing user data:', error);
    return null;
  }
}

export function getAuthToken(): string | null {
  return getItemSync('auth_token');
}

export async function getAuthTokenAsync(): Promise<string | null> {
  return await secureStorageWithCache.getItem('auth_token');
}

export function isAuthenticated(): boolean {
  return !!(getAuthToken() && getCurrentUser());
}

export function setMfaPendingLogin(payload: MfaPendingLogin): void {
  try {
    sessionStorage.setItem(MFA_PENDING_KEY, JSON.stringify(payload));
  } catch (error) {
    logger.error('Failed to store MFA pending login:', error);
  }
}

export function getMfaPendingLogin(): MfaPendingLogin | null {
  try {
    const raw = sessionStorage.getItem(MFA_PENDING_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as MfaPendingLogin;
  } catch {
    return null;
  }
}

export function clearMfaPendingLogin(): void {
  try {
    sessionStorage.removeItem(MFA_PENDING_KEY);
  } catch {
    // ignore
  }
}

export async function clearAuth(): Promise<void> {
  await secureStorageWithCache.removeItem('auth_token');
  await secureStorageWithCache.removeItem('user');
  await secureStorageWithCache.removeItem('remember_me');
  clearMfaPendingLogin();
}

export async function forceLogout(reason?: string): Promise<void> {
  try {
    logger.warn('Force logout triggered', reason ? `Reason: ${reason}` : '');
    await clearAuth();
    localStorage.removeItem('auth_token');
    localStorage.removeItem('user');
    localStorage.removeItem('remember_me');
    sessionStorage.clear();
    if (typeof window !== 'undefined' && (window as any).__REACT_QUERY_CLIENT__) {
      (window as any).__REACT_QUERY_CLIENT__.clear();
    }
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
  } catch (error) {
    logger.error('Error during force logout:', error);
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
  }
}
