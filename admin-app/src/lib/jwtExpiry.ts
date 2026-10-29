/**
 * Decode JWT payload without verifying signature (client-side expiry hints only).
 * Server remains the source of truth.
 */
export function readJwtExpiryMs(token: string | null | undefined): number | null {
  if (!token || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const json = atob(base64);
    const payload = JSON.parse(json) as { exp?: number };
    if (typeof payload.exp !== 'number') return null;
    return payload.exp * 1000;
  } catch {
    return null;
  }
}

/** True when token is missing, malformed, or expires within `skewMs`. */
export function isAccessTokenExpiringSoon(
  token: string | null | undefined,
  skewMs = 60_000
): boolean {
  const expMs = readJwtExpiryMs(token);
  if (expMs == null) return true;
  return Date.now() >= expMs - skewMs;
}
