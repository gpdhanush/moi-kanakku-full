import { API_CONFIG } from './config';
import { getAuthToken, getCsrfToken } from './auth';

/**
 * Authenticated fetch for multipart uploads (memory Bearer + cookies).
 */
export async function credentialedFetch(
  path: string,
  init: RequestInit = {}
): Promise<Response> {
  const method = String(init.method || 'GET').toUpperCase();
  const headers = new Headers(init.headers || {});

  const bearer = getAuthToken();
  if (bearer) {
    headers.set('Authorization', `Bearer ${bearer}`);
  } else {
    headers.delete('Authorization');
  }

  if (!['GET', 'HEAD', 'OPTIONS'].includes(method) && !bearer) {
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
