# Moi Kanakku — Architecture, Quality, and Defensive Security Review

**Scope:** `new-design` branch of the monorepo (`mobile-app/`, `admin-app/`, `backend/`), with primary focus on the Flutter Android client.

**Review type:** Static architecture and defensive VAPT-style assessment. No exploits, payloads, or attack procedures.

**Date:** 17 September 2026  
**Reviewed commit:** tip of `new-design` at review start  
**Environment notes:** Flutter/Dart SDKs were **not** installed in this review environment. `flutter analyze` could not be run. Findings are from source inspection, config review, and in-repo pattern search.

**Secret handling:** Secret *values* are redacted below. Locations and key *names* are listed so they can be rotated and purged.

---

## Executive summary

Moi Kanakku is a production-oriented Android Flutter app (`com.renzo.moi`, version `5.0.1+52`) talking to a Node/Express MySQL API, with a React/Vite admin dashboard. The mobile codebase already includes several strong controls: HTTPS-only startup gating, API host allowlisting, TLS certificate pinning for the production host, `flutter_secure_storage`, biometric lock, R8 minify/shrink, and `usesCleartextTraffic="false"`.

Those controls are undermined by **committed production secrets and personal data**, and by **authorization gaps on the API** that the mobile client cannot compensate for.

The highest-priority issues are:

1. **Signing keys, Play Console service-account private key, and keystore passwords are in git** (`mobile-app/play_store_files.zip` and `mobile-app/play_store_files/keystore-files.zip`).
2. **SQL dumps with live-looking user/admin rows, bcrypt hashes, emails, and OTPs are in git** (`backend/database/*.sql`).
3. **Unauthenticated account takeover / restore / mail-relay endpoints** (`POST /apis/users/reset-password`, `POST /apis/users/restore`, `POST /apis/email/sendEmail` including `custom`/`raw`).
4. **Broken object-level authorization:** many person/transaction/user APIs trust `userId` from the request body or path instead of the JWT subject.
5. **`validateApiKey` is defined but never applied.** CORS is effectively `Access-Control-Allow-Origin: *`. Login/forgot/reset are excluded from rate limiting.

This review’s PR applies **gitignore hardening** and **redacts placeholder secrets in `admin-app/.env.example`**. It does **not** rewrite API auth (that is a product change). Committed secret files should still be **rotated, removed from git history, and treated as compromised**.

**Overall risk:** High for a financial/family-records app, driven by secrets-in-git and API authorization — not by the Flutter UI layer.

**OWASP mapping (summary):**

| Framework | Most relevant items observed |
| --- | --- |
| OWASP Mobile Top 10 | M1 credential usage, M3 authz, M5 communication policy gaps, M6 privacy (dumps/uploads), M7 binary/backup, M8 misconfiguration, M9 storage |
| MASVS | MASVS-STORAGE, MASVS-AUTH, MASVS-NETWORK, MASVS-PLATFORM, MASVS-CODE |
| OWASP API Top 10 / ASVS | API1 BOLA, API2 broken auth, API4 unconstrained resource (email/OTP), API8 security misconfig, API9 inventory (unauth dashboard/health) |

---

## Architecture map

```
┌─────────────────────────────┐     HTTPS + (intended) X-API-Key
│  mobile-app (Flutter)       │     + Bearer JWT
│  lib/main.dart → MyApp      │────────────────────────────────┐
│  splash → remote config     │                                │
│  Connection (Dio)           │                                ▼
│  SecureStorageService       │                     ┌────────────────────┐
└─────────────────────────────┘                     │ backend (Express)  │
                                                    │ app.js             │
┌─────────────────────────────┐     Axios + JWT     │ /health  (open)    │
│  admin-app (React/Vite)     │────────────────────▶│ /apis/*            │
│  AdminLayout auth gate      │                     │ /uploads (static)  │
└─────────────────────────────┘                     └─────────┬──────────┘
                                                              │
                                                              ▼
                                                         MySQL / MariaDB
```

### Mobile entry points and navigation

| Area | Path | Notes |
| --- | --- | --- |
| Process entry | `mobile-app/lib/main.dart` | Firebase init, Crashlytics in release, portrait lock, `ThemeProvider` + `LanguageProvider` |
| App shell | `mobile-app/lib/my_app.dart` | Adds `ConnectivityProvider`, `UserProvider`; `MaterialApp` with string routes; `initialRoute: 'splash'` |
| Router | `mobile-app/lib/app_configs/app_routes.dart` | Large `switch` on `settings.name`. **No auth guard.** Unknown routes fall through to `SplashScreen`. Offline forces `NoInternetPage` for every named route. |
| Splash / session | `mobile-app/lib/app_pages/splash_screen/splash_screen_controller.dart` | Remote Config → API allowlist/pinning gate → maintenance/force-update → login flag + optional biometrics |
| API client | `mobile-app/lib/app_services/connection.dart` | Shared Dio client; injects `X-API-Key` and `Authorization`; 401 clears session |
| Local storage | `mobile-app/lib/app_storages/secure_storages.dart` | Encrypted prefs via `flutter_secure_storage` (Android Keystore-backed options) |
| Native plugins | `pubspec.yaml` | Firebase (Core, Crashlytics, Remote Config, Messaging), `local_auth`, `webview_flutter`, `image_picker`, `speech_to_text`, `printing`/`pdf`, `dio`, `permission_handler` |

### Backend / admin entry points (critical)

| Surface | Path | Auth observed |
| --- | --- | --- |
| Health | `GET /health`, `/live`, `/ready` | None. Full health payload includes DB host/user/name |
| API mount | `app.use("/apis", routes)` | General rate limiter only; **API key middleware unused** |
| Static files | `app.use("/uploads", express.static(...))` | None |
| Dashboard stats | `GET /apis/dashboard`, `/detailed` | **No JWT / admin middleware** |
| User auth | `POST /apis/users/login`, `/create` | Open (intended for login/signup) |
| Password reset | `POST /apis/users/reset-password` | **No auth and no OTP check** |
| Account restore | `POST /apis/users/restore` | **No auth and no OTP check** |
| Email | `POST /apis/email/sendEmail` | **No auth**; `custom`/`raw` sends arbitrary HTML |
| Admin UI | `admin-app/src/App.tsx` | Client-side `AdminLayout` token check only |

### State management and folder structure

The Flutter tree is feature-ish and readable:

- `lib/app_pages/` screens (home, login, transactions, functions, upcoming functions, profile, settings)
- `lib/app_services/` HTTP wrappers
- `lib/app_configs/` routes, tokens, pinning, allowlist
- `lib/app_themes/` centralized `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`
- `lib/app_storages/`, `lib/app_firebase/`, `lib/app_utils/`

Quality gaps: leftover global `userDetails` / `jwtToken` in `app_variables.dart`; widgets mixed into `app_utils`; stringly-typed routes; `UserProvider` is a thin wrapper over secure storage rather than a domain model; **no `test/` directory**; `pubspec.lock` is gitignored; `analysis_options.yaml` globally ignores `use_build_context_synchronously`.

There is **no `ios/` project**. This is Android-only in-repo. iOS ATS, Keychain, and Info.plist could not be reviewed because they are absent.

---

## Architecture & code quality suggestions

These are maintainability and UX/performance notes, not billed as vulnerabilities unless they also appear in the findings table.

1. **Replace string routes with a typed router** (`go_router` or a const route table) and add an auth redirect: logged-out users must not be able to `pushNamed('home')`.
2. **Finish the Provider migration.** Delete globals in `app_variables.dart`. Keep JWT only in `SecureStorageService` + `UserProvider`.
3. **Stop using request-body `userId`.** The API should take identity exclusively from `req.user.userId`. The Flutter services can then drop `userId` from payloads.
4. **Split `Connection`.** The Dio client currently owns headers, loading UI, toasts, login redirect, Crashlytics, and multipart upload. Extract interceptors and keep UI out of the HTTP layer.
5. **Connectivity should not replace the navigator.** `AppRoute.allRoutes` returning `NoInternetPage` for *every* route loses stack and form state. Prefer a banner/overlay.
6. **Commit `pubspec.lock`** for reproducible Android builds. Ignoring it is a supply-chain/reproducibility issue (Mobile Top 10 M2).
7. **Re-enable `use_build_context_synchronously`** and fix call sites; the splash/login flows are async-heavy.
8. **Trim `pubspec.yaml` font aliases.** Multiple family names (`Roboto`, `Poppins`, `tamilFont`, …) all point at Arimo. Runtime `GoogleFonts.config.allowRuntimeFetching = true` adds network, privacy, and layout-shift cost — prefer bundled fonts only.
9. **Permission surface vs Manifest.** The in-app permission page asks for notifications/camera/mic (and legacy storage). The Manifest also declares Bluetooth, fine location, nearby Wi-Fi, and advertising ID. Align Manifest with actual features.
10. **Add widget/golden tests** for login, splash routing, and pinning/allowlist unit tests (the pinning code already has `@visibleForTesting` hooks).
11. **Admin dashboard routes must use `authenticateAdminToken`.** Client-side `AdminLayout` is not an access control.
12. **JWT session store.** `tokenService.js` keeps tokens in process memory with a 30-day expiry. Restarts invalidate everyone; multiple Node processes break single-session checks. Persist hashed session IDs (Redis/DB) and shorten access-token lifetime with refresh tokens.

---

## Security findings table

Severity: **Critical** (immediate account/key compromise or confirmed sensitive data in git), **High** (authz/authn broken in code), **Medium** (misconfig that enlarges impact), **Low** (defense-in-depth / hygiene).

| ID | Severity | Area | Finding | Evidence (path) | Fix |
| --- | --- | --- | --- | --- | --- |
| S-01 | Critical | Secrets / git | Android **release keystores**, **keystore password file**, and a **Google Play / Firebase service-account JSON containing `private_key`** are tracked. Treat signing keys and the service account as compromised. | `mobile-app/play_store_files.zip` (also nested `play_store_files/keystore`, `my-release-key.keystore`, `my-release-key-pkcs12.keystore`, `keystore password.txt`, `moi-master-*.json`); `mobile-app/play_store_files/keystore-files.zip` (same artifacts). Zip JSON `type` = `service_account`, `private_key` present. `mobile-app/.gitignore` **un-ignores** `play_store_files/moi-master-f2f9415b77b0.json`. | Rotate Play Console service account; generate a **new** upload keystore (or use Play App Signing reset); revoke the leaked service account; `git rm --cached` the zips; purge git history (`git filter-repo` / BFG); store keys in CI secrets only. Do not keep password files in the tree. |
| S-02 | Critical | Privacy / git | Production-like **SQL dumps with INSERT data** are tracked: users, admins, persons, transactions, credentials (bcrypt), devices, profiles, and in one dump **OTP rows**. Unique email-like strings: 41 and 33; bcrypt-like hashes: 42 and 34. | `backend/database/floatwal_moi_kanakku_db.sql` (~418K); `backend/database/prasowla_moi_kanakku_db.sql` (~288K). `optimizations_indexes.sql` is schema-only (OK). | Remove dumps from git; purge history; rotate DB passwords and user/admin passwords if dumps left a cloneable environment; keep anonymized seed fixtures only. Restrict DB hosts. |
| S-03 | High | Secrets / git | Tracked Vite env files include live API base URLs and **commented Firebase web keys / VAPID / ENCRYPTION_KEY**. `.env.example` contained a **64-char `ENCRYPTION_KEY` and real-looking Firebase web credentials** (not placeholders). | `admin-app/.env`, `admin-app/.env.production` (tracked despite root `.gitignore`); `admin-app/.env.example`. `admin-app/.gitignore` did not list `.env`. | Untrack `.env` / `.env.production`; keep example files with placeholders only (done in this PR for `.env.example`); rotate Firebase web API key restrictions and any encryption key that was committed; restrict API keys by HTTP referrer. |
| S-04 | High | Flutter / M1 | API shared secret is **hardcoded as a source fallback**, then sent on every request as `X-API-Key`. Remote Config can overwrite it, but the fallback remains in the APK. | `mobile-app/lib/app_configs/app_variables.dart` (`_cachedApiSecretKey`); applied in `connection.dart` interceptor. | Remove plaintext fallback from the client. Deliver the key only via Remote Config **after** App Check, or replace “API key as shared secret” with real client attestation. Rotate `API_SECRET_KEY` server-side. |
| S-05 | High | API / M3 / API2 | **Password reset does not require OTP or a reset token.** Any caller who knows an email can set a new password. Flutter verifies OTP first, but the API does not enforce that. | `backend/src/routes/user.js` `POST /reset-password` (no `authenticateToken`); `backend/src/controllers/user.js` `resetPassword` hashes body password after `findByEmail` only. | Require a single-use server-side reset token issued only after successful OTP; bind token to email; expire quickly; invalidate sessions on reset. |
| S-06 | High | API / M3 / API2 | **Account restore is unauthenticated and does not check OTP.** Flutter has an OTP UI, but `restoreAccount` only needs `{ email }`. | `backend/src/routes/user.js` `POST /restore`; `user.js` `restoreAccount`. | Restore only after `verifyRestoreOTP` succeeds; then restore in the same transaction; do not expose a standalone restore-by-email endpoint. |
| S-07 | High | API / API4 | **Unauthenticated mail sending**, including `type: custom` / `raw` with caller-supplied HTML to any `email`. OTP send types (`forgot` / `restore` / `verification`) are also unauthenticated and unrate-limited (login/forgot skipped by the general limiter). | `backend/src/routes/emailRoutes.js` `POST /sendEmail` (no auth); `emailControllers.js` `custom`/`raw` branch. Rate-limit skip: `apiSecurity.js` `skip` includes `/forgot-password` and `/reset-password`; path `/email` is not specially limited. | Remove `custom`/`raw` from the public endpoint (admin-only). Rate-limit OTP send per email and per IP. Do not skip auth endpoints in the general limiter — add a **stricter** limiter for them instead. |
| S-08 | High | API / API1 | **BOLA / IDOR:** person and transaction handlers trust `userId` from the body. A valid JWT for user A can operate on user B’s UUID. JWT is checked for presence, not resource ownership. Upcoming functions are better (`req.user?.userId \|\| req.body.userId`) but still fall back to the body. | `moiPersons.js` `list`/`create` use `req.body.userId`; `transactions.js` `create` uses `req.body.userId` and checks person belongs to **that body id**, not `req.user.userId`. Contrast: `upcomingFunction.js` and `notificationController.js` prefer JWT. | Ignore body/path user ids. Always `const userId = req.user.userId`. Add regression tests that a token for A cannot read/write B. |
| S-09 | High | API / API1 | Authenticated **user detail and delete/referral** APIs are not bound to the caller. `GET /users/details/:id` returns another user’s profile (name, email, mobile, address, device). `POST /users/delete` deletes by **body email**. `GET /referral-code` accepts arbitrary `id`/`email`. | `backend/src/routes/user.js`; `getImportantUserDetails`, `deleteUser`, `getReferralCode` in `user.js`. | Force `id === req.user.userId` (users) or admin role. Delete only the authenticated account (or admin). |
| S-10 | High | API / API9 | **Admin dashboard JSON is public** (counts of users, persons, transactions, devices, feedback). No `authenticateAdminToken`. Combined with unused API key middleware, this is an unauthenticated inventory leak. | `backend/src/routes/dashboard.js` (no middleware); mounted in `src/routes/index.js`. | Apply `authenticateAdminToken`. Do not cache this response without auth. |
| S-11 | High | API / M8 | **`validateApiKey` and `registrationRateLimiter` are never used.** README claims registration requires `X-API-Key`; the mobile client always sends it, but the server never checks. CORS `origin` callback **always succeeds** (`return callback(null, true)` after the allowlist block). | `backend/src/middlewares/apiSecurity.js` (exported, no other references); `backend/app.js` CORS origin function. | Wire `validateApiKey` on `/apis`. Apply registration limiter on `POST /users/create`. Make CORS fail closed when `ALLOWED_ORIGINS` is set; never allow `*` with `credentials: true`. |
| S-12 | High | Privacy / API | **User uploads are world-readable.** Profile images are stored under UUID paths and served by `express.static` with no auth. A tracked sample image is in git. | `backend/app.js` `app.use("/uploads", express.static(uploadPath))`; tracked file `backend/uploads/<uuid>/profile/profile-*.jpg`. | Untrack uploads; gitignore `backend/uploads/`. Serve files via authenticated handlers or short-lived signed URLs. |
| S-13 | Medium | Android / M7 | **Auto-backup not disabled.** No `android:allowBackup="false"` / `dataExtractionRules`. Default is backup **enabled**, which can include app files (secure storage uses Android Keystore, which reduces but does not eliminate backup risk for non-Keystore prefs). | `mobile-app/android/app/src/main/AndroidManifest.xml` `<application>` lacks `allowBackup` / `fullBackupContent`. | Set `android:allowBackup="false"` and `android:dataExtractionRules` / `fullBackupContent` to exclude tokens. Confirm with `adb backup` **not** used in production tests — use a debug build of *your* app and confirm backup agent skips token files. |
| S-14 | Medium | Android / M8 | **Over-privileged Manifest:** `ACCESS_FINE_LOCATION`, Bluetooth (legacy + SCAN/CONNECT/ADVERTISE), `NEARBY_WIFI_DEVICES`, `AD_ID`, plus `showWhenLocked` / `turnScreenOn` on the launcher activity. In-app permission UX only covers notification/camera/mic/storage. | Same Manifest; `permission_controller.dart` permission list. | Remove unused permissions and lock-screen flags unless a feature needs them. `AD_ID` requires Play Data Safety justification. |
| S-15 | Medium | Flutter / MASVS-PLATFORM | `WebViewPage` enables **unrestricted JavaScript** and loads whatever URL is passed in. Not referenced from routes today (dead code), but it is shippable if wired later. | `mobile-app/lib/app_utils/app_widgets/webview_page.dart` | Keep JS disabled unless required; allowlist https hosts; block file/content schemes; do not add a JS bridge. Prefer Custom Tabs / `url_launcher`. |
| S-16 | Medium | Flutter / M3 | **No navigation auth guard.** `onGenerateRoute` will build `HomePage`, profile, transactions, etc. for any caller of `Navigator.pushNamed`. Splash checks login, but any later named navigation skips it. Connectivity hijack also bypasses intended screens. | `app_routes.dart`; `splash_screen_controller.dart` | Guard authenticated routes; keep a session listenable on `MaterialApp`. |
| S-17 | Medium | API / sessions | **JWT TTL 30 days**, stored in **process memory**, compared in auth middleware. Auth also **logs both presented and stored tokens** at debug. Restart logs everyone out; multi-instance deploys accept stale JWTs if memory is empty on one node (mismatch fails closed) or diverge. | `tokenService.js` `expiresIn: '30 days'`; `auth.js` `logger.debug('token mismatch for user', userId, { token, storedToken })`. | Short-lived access tokens; hashed refresh sessions in DB; never log raw JWTs. Set `LOG_LEVEL=info` in production. |
| S-18 | Medium | API / ASVS | **`GET /health` discloses hostname, PID, `NODE_ENV`, DB host/user/name.** Fine for an internal probe; risky if the port is public. | `backend/src/controllers/healthController.js`; `backend/src/routes/health.js` | Keep `/live` public. Protect `/health` (network ACL or admin auth). Remove DB username/host from the payload. |
| S-19 | Medium | Admin / MASVS-AUTH | Admin OTP console returns **plaintext OTP `code`** to the SPA. Useful for support, harmful if an admin session is stolen. | `adminControllers.js` `listOTPs` selects `o.code`; `admin-app/src/pages/UserOtps.tsx`. | Return masked codes (`***123`) or hashes; store OTPs hashed at rest. |
| S-20 | Medium | Flutter / logging | Release logging is mostly gated with `kReleaseMode`, which is good. **Upload path logs request headers** (would include `Authorization` / `X-API-Key`) in debug. `logApiErrorToCrashlytics` records the `DioException` object (may include URL/headers depending on interceptor). Signup logs `response.toString()`. | `connection.dart` `printContent("===> Headers: $headers")`; `app_logs.dart`; `signup.dart` `printContent(response.toString())`. | Redact Authorization and API keys in all logs. Strip Dio request headers before Crashlytics. Never log signup/login bodies. |
| S-21 | Medium | Android / R8 | Release has minify + shrink (good). `proguard-rules.pro` still **keeps entire Flutter packages and leftover Razorpay/Gson/OkHttp rules** while Razorpay is commented out of `pubspec.yaml`. Broad `-keep class io.flutter.**` weakens obfuscation. | `android/app/build.gradle.kts` `isMinifyEnabled = true`; `proguard-rules.pro`. | Drop unused Razorpay keeps; avoid blanket Flutter `-keep`; use Flutter’s recommended R8 config; enable obfuscation mapping upload to Play/Crashlytics only (do not commit maps — already gitignored). |
| S-22 | Low | Flutter / iOS | **No iOS app tree** (`Info.plist`, ATS, Keychain accessibility, URL schemes). `firebase_options.dart` throws on iOS. Cannot assess ATS or backup. | `mobile-app/` has `android/` only; `DefaultFirebaseOptions.iOS` is `UnsupportedError`. | If iOS is in scope later: disable arbitrary loads, set Keychain `first_unlock_this_device`, no plaintext HTTP exceptions. |
| S-23 | Low | Flutter client config | `google-services.json` and `firebase_options.dart` contain the Android Firebase **client** API key / app id. This is normal for Firebase, but the file is listed in root `.gitignore` yet **still tracked**. Client keys must be **API-restricted** (Android app + SHA-256). | `mobile-app/android/app/google-services.json`; `lib/app_firebase/firebase_options.dart`. | Restrict the key in Google Cloud Console. Prefer injecting `google-services.json` in CI if you want it out of git; otherwise accepting it as public client config is OK **if** restricted. |
| S-24 | Low | Error handling | Many controllers return `error.toString()` to clients, which can leak SQL/driver messages. | Widespread in `backend/src/controllers/*.js`. | Return generic messages; log details server-side only. |
| S-25 | Info / positive | Network | Production API host allowlist + SPKI pinning; cleartext disabled; startup gate blocks requests until HTTPS allowlisted URL + non-empty API key. | `api_endpoint_allowlist.dart`, `api_certificate_pinning.dart`, `api_startup_config.dart`, Manifest `usesCleartextTraffic="false"`. | Keep pin rotation runbook (already documented in-source). Add the second production host if admin/API split (`moi-kanakku-api.prasowlabs.in`) is still live. |
| S-26 | Info / positive | Storage / auth UX | Tokens in `flutter_secure_storage`; biometrics optional; password validator requires mixed complexity; bcrypt on server (`cost 10`). | `secure_storages.dart`, `app_bio_metric.dart`, `password_validator.dart`, `user.js` `bcrypt.hash(..., 10)`. | Consider bcrypt cost 12; bind biometrics to a CryptoObject for the token if you need hardware-backed session unlock. |

---

## Hardening checklist (Android / iOS / Flutter)

### Android (release)

- [ ] `android:allowBackup="false"` and exclude encrypted prefs from backup/extraction rules.
- [ ] Remove unused Bluetooth / location / nearby / AD_ID permissions.
- [ ] Remove `showWhenLocked` / `turnScreenOn` unless required for notifications.
- [ ] Keep `usesCleartextTraffic="false"` (already set). Add `networkSecurityConfig` that disallows cleartext and optionally pins via Android N config **in addition to** Dart pinning.
- [ ] Keep R8 minify/shrink; tighten ProGuard; do not commit mapping files.
- [ ] Signing: `key.properties` is gitignored (good). **Rotate** leaked keystores from S-01. Use Play App Signing.
- [ ] Confirm Play Data safety matches mic/camera/notifications.
- [ ] Restrict Firebase Android API key by package `com.renzo.moi` and release SHA-256.

### iOS (not in repo)

- [ ] When an iOS target is added: ATS defaults (no `NSAllowsArbitraryLoads`), no HTTP exceptions.
- [ ] Keychain accessibility `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` via `flutter_secure_storage` iOS options.
- [ ] No custom URL schemes without validation (no deep links found on Android).

### Flutter / Dart

- [ ] No hardcoded API secrets; empty fallback.
- [ ] Auth gate on all post-login routes.
- [ ] Do not log headers, tokens, passwords, OTP, or full API bodies.
- [ ] WebView: JS off + host allowlist, or delete the unused widget.
- [ ] Commit `pubspec.lock`; run `flutter analyze` in CI.
- [ ] Unit-test allowlist, pinning, and startup gate (code is already structured for this).
- [ ] `GoogleFonts.config.allowRuntimeFetching = false`.

### Backend / admin (ASVS-oriented)

- [ ] Apply `authenticateAdminToken` to `/dashboard`.
- [ ] Apply `validateApiKey` globally on `/apis`.
- [ ] Fail-closed CORS.
- [ ] Bind every user-data query to `req.user.userId`.
- [ ] OTP-gate reset and restore; hash OTPs at rest.
- [ ] Authenticate or sign `/uploads`.
- [ ] Rate-limit login/OTP (do not skip them).
- [ ] Stop returning `error.toString()`; stop logging JWTs.
- [ ] Persist sessions out of process memory.

---

## Suggested safe verification tests

These tests **assert secure behavior**. They do not include payloads or attack steps.

### Secrets / repo hygiene

- Clone a fresh copy from git (no working tree). Confirm `play_store_files.zip`, `keystore-files.zip`, SQL dumps, `.env`, and `backend/uploads/**` are **absent**.
- `git log --all --full-history -- backend/database/floatwal_moi_kanakku_db.sql` should be empty **after** history purge (will still exist until purge).

### Flutter (unit / widget)

- `isAllowedApiEndpoint` accepts only `https://moi-api.floatwalktiruppur.in/...` and rejects `http://`, userinfo, non-443 ports, and suffix hosts.
- `validateApiCertificatePin` returns false when the leaf SPKI is not in `apiCertificatePins`.
- `ApiStartupConfig.validate` blocks empty base URL / empty API key / non-allowlisted URL; `Connection` must not send requests while `apiRequestsAllowed` is false.
- Widget test: with `isLogin != true`, building the app and navigating to `home` is redirected to `login`.
- `kReleaseMode` logging helpers emit nothing (test with a small wrapper).

### Android release

- Release Manifest merge: `usesCleartextTraffic=false`; unused Bluetooth/location permissions absent after Manifest cleanup.
- Backup rules: token files excluded (inspect merged Manifest / backup XML on a **local debug** build of the app you own).
- `bundletool` / Play pre-launch: no cleartext traffic.

### API (authenticated tests against a staging DB you own)

- User A token + User B id on `GET /apis/users/details/:id` → **403**.
- User A token + User B `userId` on `POST /apis/persons/list` and `POST /apis/transactions/list` → **403** / empty owned set.
- `POST /apis/users/reset-password` with email+new password and **no** prior OTP token → **401/403**.
- `POST /apis/users/restore` with email only → **401/403**.
- `POST /apis/email/sendEmail` with `type: "custom"` unauthenticated → **401**.
- `GET /apis/dashboard` without admin JWT → **401**.
- Login: after N failures from one IP, next login returns **429** (once limiter is applied).
- CORS: a request with `Origin` not in `ALLOWED_ORIGINS` is rejected (once fail-closed).
- `/health/live` remains 200; `/health` does not include `database.user` / `database.host`.

Do **not** run these against production. Do **not** use another customer’s account.

---

## Prioritized remediation plan

### P0 — this week

1. **Assume S-01/S-02/S-03 are public.** Rotate Play service account, Android upload keystore (coordinate with Play App Signing), Firebase keys that were committed, DB passwords, `JWT_SECRET`, `API_SECRET_KEY`, SMTP credentials if they ever appeared in dumps/env, and force password resets for dumped user/admin rows.
2. **Purge git history** of `play_store_files.zip`, `keystore-files.zip`, SQL dumps, env files, and `backend/uploads/`. A `.gitignore` fix (this PR) only stops *new* commits.
3. **Disable unauthenticated reset/restore/custom-email** in production (feature flag or deploy a one-line auth/OTP check). This is the fastest reduction of account-takeover risk.
4. **Protect `/apis/dashboard`** with admin JWT.

### P1 — next hardening slice

5. Bind all person/transaction/user reads and writes to `req.user.userId` (S-08, S-09).
6. Apply `validateApiKey`, fail-closed CORS, and **dedicated** login/OTP rate limits (S-11, S-07).
7. Stop serving `/uploads` statically; gitignore uploads.
8. Remove hardcoded mobile API-key fallback; rotate the server key (S-04).
9. Android backup flag + drop unused permissions (S-13, S-14).
10. Hash OTPs; mask admin OTP UI (S-19).

### P2 — quality and defense in depth

11. Typed router + auth guard; delete global session variables.
12. Persist sessions in Redis/DB; shorten JWT TTL; never log tokens.
13. Tighten R8; commit `pubspec.lock`; CI `flutter analyze` + API authorization tests.
14. Delete or lock down unused `WebViewPage`.
15. Health endpoint minimization; generic API errors.
16. If iOS ships, complete ATS/Keychain review.

### Do this week (checklist)

- [ ] Rotate Play service account and signing materials from S-01  
- [ ] Remove dumps/zips/env from git **and** history  
- [ ] OTP-bind reset + restore; disable custom email  
- [ ] Auth-protect dashboard  
- [ ] Confirm Firebase Android/web keys are referrer/app restricted  
- [ ] Notify affected users if dumps included real personal data (privacy/legal)

---

## Open questions / what could not be verified statically

| Item | Why unverified |
| --- | --- |
| `flutter analyze` / test suite | Flutter SDK not installed in this environment; no `mobile-app/test/` folder found |
| Runtime pinning against the live cert | Pins are present for `moi-api.floatwalktiruppur.in`; not probed from this review (would be an external network test) |
| Whether Remote Config currently overrides the hardcoded API key | Requires Firebase project access |
| Production `ALLOWED_ORIGINS`, `JWT_SECRET` entropy, `TRUST_PROXY` | No `backend/.env` in repo (good); server env unknown |
| Whether SQL dumps are production vs staging | Emails/hashes/OTPs are real-looking; environment name in filenames (`floatwal`, `prasowla`) suggests deployed DBs, not empty schemas |
| iOS ATS, Keychain, backup, URL schemes | No `ios/` directory |
| Deep links / App Links | No `intent-filter` VIEW/BROWSABLE and no `uni_links`/`app_links` dependency |
| WebView in production UX | Widget exists but is not referenced from `AppRoute` |
| Admin encryption at rest | `admin-app/src/lib/secureStorage.ts` uses WebCrypto + localStorage; not a substitute for httpOnly cookies; XSS impact not fully modeled |
| MFA enforcement on admin login | MFA routes/controllers exist; not fully traced whether admin login *requires* MFA in all paths |
| Multi-instance Node deployment | In-memory token map is unsafe if more than one process is used; hosting topology unknown |
| `play_store_files/KeyStore.png` | Likely a screenshot of keystore creation; treat as sensitive UI, not parsed |
| History leak beyond current tree | Files are in the current tree; older commits may contain additional secrets — needs a dedicated secret-scan of history (`gitleaks` / `trufflehog`) after this review |

### Positive controls already in place (keep)

- HTTPS-only API allowlist and SPKI pinning with rotation comments  
- `usesCleartextTraffic="false"`  
- `flutter_secure_storage` with Android options; session clear preserves only permission flags  
- Biometric lock before home when enabled  
- R8 minify + resource shrink on release  
- Helmet + (intended) rate limiting library  
- Parameterized SQL (`mysql2` placeholders) in reviewed models  
- Admin SPA route wrapper checks token before rendering layout  
- Crashlytics collection enabled only in release  

---

## Small hardening included in this PR

Low-risk repo hygiene only (no auth behavior change):

- Root / app `.gitignore` entries for env files, SQL dumps, uploads, and Play/keystore archives  
- Untrack those files from the git index (`git rm --cached`) so they are not on `new-design` going forward  
- Replace real-looking secrets in `admin-app/.env.example` with placeholders  

**Still required outside git:** rotation, history purge, and the P0 API auth fixes.
