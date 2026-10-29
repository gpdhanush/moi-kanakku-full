/**
 * @vitest-environment node
 */
import { describe, expect, it } from 'vitest';
import { isAccessTokenExpiringSoon, readJwtExpiryMs } from './jwtExpiry';

function makeJwt(expSeconds: number): string {
  const header = Buffer.from(
    JSON.stringify({ alg: 'none', typ: 'JWT' })
  ).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({ exp: expSeconds })
  ).toString('base64url');
  return `${header}.${payload}.sig`;
}

describe('jwtExpiry', () => {
  it('reads exp from JWT payload', () => {
    const exp = Math.floor(Date.now() / 1000) + 3600;
    expect(readJwtExpiryMs(makeJwt(exp))).toBe(exp * 1000);
  });

  it('flags tokens expiring within skew', () => {
    const soon = Math.floor(Date.now() / 1000) + 30;
    expect(isAccessTokenExpiringSoon(makeJwt(soon), 60_000)).toBe(true);
    const later = Math.floor(Date.now() / 1000) + 3600;
    expect(isAccessTokenExpiringSoon(makeJwt(later), 60_000)).toBe(false);
  });

  it('treats missing token as expiring', () => {
    expect(isAccessTokenExpiringSoon(null)).toBe(true);
    expect(isAccessTokenExpiringSoon('not-a-jwt')).toBe(true);
  });
});
