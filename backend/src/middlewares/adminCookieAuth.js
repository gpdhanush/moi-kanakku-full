/**
 * Admin browser session cookies (HttpOnly) + CSRF companion cookie.
 *
 * Mobile / Bearer clients are unaffected: they keep using Authorization headers
 * and never send these cookies.
 */

const crypto = require("crypto");

const ACCESS_COOKIE = "moi_admin_access";
const REFRESH_COOKIE = "moi_admin_refresh";
const CSRF_COOKIE = "moi_admin_csrf";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

function isProduction() {
  return (
    process.env.NODE_ENV === "production" ||
    process.env.COOKIE_SECURE === "true" ||
    process.env.COOKIE_SECURE === "1"
  );
}

function cookieBaseOptions() {
  const sameSiteRaw = (process.env.COOKIE_SAMESITE || "").toLowerCase();
  // Cross-site admin SPA → API needs SameSite=None; Secure.
  // Localhost same-site (different ports) can use Lax.
  const sameSite =
    sameSiteRaw === "none" ||
    sameSiteRaw === "lax" ||
    sameSiteRaw === "strict"
      ? sameSiteRaw
      : isProduction()
        ? "none"
        : "lax";

  return {
    httpOnly: true,
    secure: sameSite === "none" ? true : isProduction(),
    sameSite,
    path: "/",
  };
}

function accessMaxAgeMs() {
  // Mirror JWT access default (30d) unless overridden via env seconds.
  const seconds = Number(process.env.JWT_ACCESS_COOKIE_MAX_AGE_SEC);
  if (Number.isFinite(seconds) && seconds > 0) return seconds * 1000;
  return 30 * 24 * 60 * 60 * 1000;
}

function refreshMaxAgeMs() {
  const seconds = Number(process.env.JWT_REFRESH_COOKIE_MAX_AGE_SEC);
  if (Number.isFinite(seconds) && seconds > 0) return seconds * 1000;
  return 30 * 24 * 60 * 60 * 1000;
}

function createCsrfToken() {
  return crypto.randomBytes(32).toString("hex");
}

/**
 * Sets HttpOnly access/refresh cookies and an HttpOnly CSRF cookie.
 * Returns the CSRF token so the SPA can send it as X-CSRF-Token (memory only).
 */
function setAdminAuthCookies(res, { accessToken, refreshToken }) {
  const base = cookieBaseOptions();
  const csrfToken = createCsrfToken();

  res.cookie(ACCESS_COOKIE, accessToken, {
    ...base,
    maxAge: accessMaxAgeMs(),
  });

  if (refreshToken) {
    res.cookie(REFRESH_COOKIE, refreshToken, {
      ...base,
      maxAge: refreshMaxAgeMs(),
    });
  }

  res.cookie(CSRF_COOKIE, csrfToken, {
    ...base,
    maxAge: accessMaxAgeMs(),
  });

  return csrfToken;
}

function clearAdminAuthCookies(res) {
  const base = cookieBaseOptions();
  const clearOpts = { ...base, maxAge: 0 };
  res.clearCookie(ACCESS_COOKIE, clearOpts);
  res.clearCookie(REFRESH_COOKIE, clearOpts);
  res.clearCookie(CSRF_COOKIE, clearOpts);
  // Also clear with maxAge for clients that ignore clearCookie path quirks
  res.cookie(ACCESS_COOKIE, "", { ...clearOpts, expires: new Date(0) });
  res.cookie(REFRESH_COOKIE, "", { ...clearOpts, expires: new Date(0) });
  res.cookie(CSRF_COOKIE, "", { ...clearOpts, expires: new Date(0) });
}

/**
 * Prefer Authorization Bearer (mobile / legacy). Fall back to admin access cookie.
 */
function extractAccessToken(req) {
  const authHeader = req.headers.authorization || req.headers.Authorization;
  if (typeof authHeader === "string" && authHeader.startsWith("Bearer ")) {
    const token = authHeader.slice(7).trim();
    if (token) {
      return { token, source: "bearer" };
    }
  }

  const cookieToken = req.cookies?.[ACCESS_COOKIE];
  if (typeof cookieToken === "string" && cookieToken.trim()) {
    return { token: cookieToken.trim(), source: "cookie" };
  }

  return { token: null, source: null };
}

function extractRefreshToken(req) {
  const bodyToken =
    req.body?.refreshToken || req.body?.refresh_token || null;
  if (typeof bodyToken === "string" && bodyToken.trim()) {
    return { token: bodyToken.trim(), source: "body" };
  }
  const cookieToken = req.cookies?.[REFRESH_COOKIE];
  if (typeof cookieToken === "string" && cookieToken.trim()) {
    return { token: cookieToken.trim(), source: "cookie" };
  }
  return { token: null, source: null };
}

/**
 * CSRF check for cookie-authenticated mutating requests.
 * Bearer-authenticated requests skip CSRF (token not auto-attached by browser).
 */
function enforceAdminCsrf(req, res, tokenSource) {
  if (tokenSource !== "cookie") return true;
  if (SAFE_METHODS.has(String(req.method || "GET").toUpperCase())) {
    return true;
  }

  // Logout must always succeed so cookies can be cleared even if SPA memory was wiped.
  // Refresh is public + CORS-origin gated (cookie body alternative still supported).
  const url = String(req.originalUrl || req.url || "");
  if (url.includes("/admin/logout") || url.includes("/admin/refresh")) {
    return true;
  }

  const header =
    req.headers["x-csrf-token"] ||
    req.headers["X-CSRF-Token"] ||
    req.headers["x-xsrf-token"];
  const cookieVal = req.cookies?.[CSRF_COOKIE];

  if (
    !header ||
    !cookieVal ||
    typeof header !== "string" ||
    header.length < 16 ||
    header !== cookieVal
  ) {
    res.status(403).json({
      responseType: "F",
      responseValue: { message: "Invalid CSRF token." },
    });
    return false;
  }
  return true;
}

/**
 * Strip secrets from admin login JSON. Tokens live in HttpOnly cookies for browsers.
 * csrfToken is returned for the SPA memory store (not a JWT).
 */
function publicAdminSessionPayload(accountPayload, csrfToken) {
  const {
    token: _t,
    accessToken: _a,
    refreshToken: _r,
    ...safe
  } = accountPayload || {};
  return {
    ...safe,
    csrfToken,
  };
}

module.exports = {
  ACCESS_COOKIE,
  REFRESH_COOKIE,
  CSRF_COOKIE,
  setAdminAuthCookies,
  clearAdminAuthCookies,
  extractAccessToken,
  extractRefreshToken,
  enforceAdminCsrf,
  publicAdminSessionPayload,
  createCsrfToken,
};
