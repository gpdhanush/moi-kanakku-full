# Auth Token Storage Audit — Moi Kanakku

**Date:** 2026-10-29  
**Scope:** Workspace audit with implementation focused on `mobile-app/` (tagged).  
**Note:** There is no “Room Splits” or Supabase project in this workspace. Auth is custom JWT + Dio + `flutter_secure_storage` (mobile) and encrypted `localStorage` (admin-app).

---

## 1. Inventory — where credentials live

### Flutter (`mobile-app/`) — primary auth client

| Action | Location | Mechanism |
|--------|----------|-----------|
| Persist JWT | `SecureStorageService.saveToken` → key `token` | `flutter_secure_storage` (Android Keystore / iOS Keychain) |
| Read JWT | `getToken`, `Connection._getCachedToken`, `UserProvider`, `AuthGuard` | Secure storage + short-lived in-memory Dio cache |
| Clear JWT | `clearSessionData`, `deleteToken`, logout / 401 / delete account | Secure storage wipe + `Connection.clearCachedToken` |
| User profile blob | `AppVariables.userInformation` | Secure storage JSON (**must not** contain JWT) |
| Login flag | `AppVariables.isLogin` | Secure storage |
| FCM token | `notificationToken` | Secure storage (push, not API auth) |
| Theme prefs | `ThemeProvider` separate namespace `_Theme_` | Secure storage (non-auth) |

**Not used for auth:** browser `localStorage` / `sessionStorage`, SharedPreferences, Supabase, Next.js middleware.

### Admin web (`admin-app/`) — remaining risk

| Item | Location | Risk |
|------|----------|------|
| `auth_token` / `refresh_token` / `user` | `admin-app/src/lib/secureStorage.ts` via AES-GCM in **`localStorage`** | XSS can still decrypt/exfiltrate if JS runs in origin (obfuscation ≠ HttpOnly) |
| Legacy plain keys removed on logout | `auth.ts` `forceLogout` | Cleanup of old plaintext keys |
| MFA pending payload (may include `sessionToken`) | `sessionStorage` `mfa_pending_login` | JS-readable |
| Preferences / device id | `localStorage` | Non-auth |

### Public / marketing web

`public_web` / `moi_kanakku` use `localStorage` for **language/theme only**, not JWTs.

### Backend

Bearer `Authorization` header (`backend/src/middlewares/auth.js`). No HttpOnly cookie session for mobile or admin today. Admin refresh uses body `refreshToken`.

---

## 2. Changes implemented (Flutter)

1. **iOS Keychain hardening** — `first_unlock_this_device`, `synchronizable: false` on session storage reads/writes.
2. **Single JWT key contract** — `SecureStorageService.authTokenKey`; `deleteToken` / `hasAuthToken`.
3. **No JWT in user blob** — `AuthCredentialSanitizer` + sanitize on `save(userInformation)` and at login persist.
4. **Session clear ↔ Dio cache** — `SecureStorageService.onSessionCleared` → `Connection.clearCachedToken`.
5. **Logout / delete-account** — clear Connection cache + `UserProvider` memory after account delete.
6. **Log redaction** — `idToken`, `sessionToken`, `jwt`, notification token keys; JWT-shaped strings.
7. **Tests** — `test/auth_credential_sanitizer_test.dart`, extended `test/log_redaction_test.dart`.

---

## 3. Verification

Run from `mobile-app/`:

```bash
flutter test test/auth_credential_sanitizer_test.dart test/log_redaction_test.dart
flutter analyze lib/app_storages lib/app_services/connection.dart lib/app_pages/users/login/login_controller.dart lib/app_utils/app_providers/user_provider.dart lib/app_pages/profile_page/profile_page.dart
```

---

## 4. Remaining risks (not fixed in this pass)

| Risk | Severity | Why deferred |
|------|----------|--------------|
| Admin JWTs in JS-accessible storage | **High** | Needs backend HttpOnly cookie + CSRF design; Bearer-only API today |
| MFA `sessionToken` in `sessionStorage` | Medium | Admin-only; requires MFA flow redesign |
| In-memory JWT in `UserProvider` / Dio | Low (expected) | Cleared on logout/401; XSS N/A on native |
| Deprecated global `jwtToken` | Low | Documented; cleared on session wipe |
| Flutter web build of secure storage | Low | App targets mobile; web plugin can fall back to browser storage if ever shipped as web |
| HttpOnly cookies do not stop XSS actions | Informational | Documented for future admin cookie work |

---

## 5. Migration notes

- Existing Android installs keep the same `storageNamespace` / prefix — no re-login forced.
- iOS accessibility change may require unlock-after-reboot once; account name unchanged so keys remain findable.
- Users whose profile JSON previously contained a nested `token` field will have it stripped on the next `save(userInformation)`.
- Admin-app: **no cookie migration** until API supports Set-Cookie sessions; do not claim admin storage is XSS-safe.
