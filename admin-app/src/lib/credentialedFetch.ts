import { API_CONFIG } from './config';
import { getCsrfToken } from './auth';

/**
 * Cookie-authenticated fetch for multipart uploads (no Bearer from storage).
 */
export async function credentialedFetch(
  path: string,
  init: RequestInit = {}
): Promise<Response> {
  const method = String(init.method || 'GET').toUpperCase();
  const headers = new Headers(init.headers || {});
  headers.delete('Authorization');

  if (!['GET', 'HEAD', 'OPTIONS'].includes(method)) {
    const csrf = getCsrfToken();
    if (csrf) {
      headers.set('X-CSRF-Token', csrf);
    }
  }

  const url = path.startsWith('http')
    ? path
    : `${API_CONFIG.BASE_URL}${path.startsWith('/') ? path : `/${path}`}`;

  return fetch(url, {
    ...init,
    method,
    headers,
    credentials: 'include',
  });
}
