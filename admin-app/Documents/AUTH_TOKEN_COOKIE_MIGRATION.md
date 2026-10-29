# Admin App — JWT localStorage → HttpOnly Cookie Migration

**Date:** 2026-10-29  
**Scope:** `admin-app/` + `backend/` admin auth (mobile Bearer unchanged)

## 1. Vulnerable locations (before)

| Location | Issue |
|----------|--------|
| `admin-app/src/lib/secureStorage.ts` | AES-GCM ciphertext of `auth_token` / `refresh_token` in **localStorage** (JS-readable; XSS can decrypt) |
| `admin-app/src/lib/auth.ts` | `persistAdminSession` wrote tokens; MFA pending could hold session data in sessionStorage |
| `admin-app/src/lib/axios.ts` | Attached `Authorization: Bearer` from storage |
| Upload components | Read `auth_token` from storage for Bearer headers |
| `backend/app.js` | CORS effectively allowed all origins with `credentials: true` |

**Root cause:** Browser JWTs lived in JavaScript-accessible storage. Encryption obfuscated casual inspection but did **not** stop XSS session theft.

**Impact:** Any XSS in the admin origin ≈ full admin takeover (access + refresh).

## 2. Implementation

### Backend
- Added `cookie-parser` + `adminCookieAuth.js` (HttpOnly access/refresh/CSRF cookies)
- Admin login / MFA verify / refresh set cookies; JSON returns profile + `csrfToken` only (no JWTs)
- Auth middleware accepts **Bearer OR cookie**; CSRF required for cookie-authenticated mutating requests
- `GET /users/admin/session`, `POST /users/admin/logout`
- CORS tightened (no “allow all origins” in production)
- Mobile user Bearer auth unchanged (`extractAccessToken` prefers Bearer)

### Admin SPA
- Tokens never written to `localStorage` / `sessionStorage`
- `withCredentials: true`; CSRF from memory via `X-CSRF-Token`
- Session restore via `/users/admin/session`
- Legacy token purge on boot
- Uploads use `credentialedFetch` (cookies + CSRF)
- Nginx CSP header added
- Markdown links/images restricted to `http(s):`

## 3. Deploy requirements

1. On the API host after pulling backend changes: `npm install` (needs `cookie-parser`) then restart Node. A missing install crashes the app → **503** from LiteSpeed with **no CORS headers** (browser shows a fake “CORS blocked” error).
2. Set `ALLOWED_ORIGINS` to the exact admin SPA origin(s), e.g.  
   `https://gp.prasowlabs.in,http://localhost:8080`  
   Localhost is also allowed by code for local Vite → production API testing.
3. HTTPS in production (`Secure` cookies; `SameSite=None` default when `NODE_ENV=production`).
4. Optional: `COOKIE_SAMESITE=lax` for same-site admin+API; `COOKIE_SECURE=true` to force Secure.
5. Redeploy **backend then admin-app**. Users must log in again (legacy localStorage tokens purged).

### Diagnose “CORS” vs real outage

```bash
curl -sI -X OPTIONS 'https://moi-api.floatwalktiruppur.in/apis/users/admin/login' \
  -H 'Origin: http://localhost:8080' \
  -H 'Access-Control-Request-Method: POST'
```

- `503` + HTML, no `access-control-allow-origin` → API process is down (install/restart).
- `204`/`200` with `access-control-allow-origin: http://localhost:8080` → CORS OK.

## 4. Remaining risks

- XSS can still **act as** the user (HttpOnly stops token *read*, not CSRF-like actions in-page). CSP reduces but does not eliminate XSS.
- In-memory CSRF + user profile are cleared on full page reload until `/session` restores them.
- Socket.IO cookie auth may need server-side cookie parsing if sockets are used.
- Dependency `npm audit` findings in backend/admin remain separate from this auth change.
- JWT access/refresh TTL still ~30d — consider shortening access TTL later.
