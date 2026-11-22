# Mobile app security and performance audit (2026-11-22)

Scope: `mobile-app/` (Flutter, Provider, Dio, flutter_secure_storage), branch `development`.
Severity scale: **Critical** (exploitable now or a credential leak), **High**, **Medium**, **Low**.
Status: **Fixed** means fixed in this pass (uncommitted). **Decision** means it needs your call.

---

## 1. Security findings

| # | Sev | Finding | Where | Status |
|---|-----|---------|-------|--------|
| S1 | **Critical** | **Android signing material is committed to git.** `mobile-app/play_store_files/KeyStore.png` is tracked, and the repo-root `backup/play_store_files.zip` is tracked too (commit history also has the old `keystore-files.zip`). `.gitignore` lists `KeyStore.png`, but that rule doesn't apply because the file was already tracked. Anyone with repo access can get the upload key or its password. | `play_store_files/KeyStore.png`, `../backup/play_store_files.zip` | Decision (not deleted) |
| S2 | **Critical** | **SQL dumps of production data are committed.** `backup/moi-kanakku-2026-11-22161456.sql` and `backend/database/21-09-2026/floatwal_moi_kanakku_db(1).sql` are tracked. Commit `a56b062` ("bug fix: certificate pinning") added `backup/moi-kanakku-2026-11-01140510.sql.gz`. These dumps hold user PII and password hashes. | repo root | Decision |
| S3 | **High** | **`.env` is bundled into the APK as a Flutter asset**, so `API_SECRET_KEY` (sent as `X-API-Key`) and the Google client IDs ship in plain text in every build. Anyone can get them with `unzip app.apk assets/flutter_assets/.env`. A secret that ships on the client is not a secret. The backend must not rely on it for authorization. | `pubspec.yaml:75` (`- .env`), `lib/main.dart:28-32`, `lib/app_services/connection.dart:220-222` | Decision |
| S4 | **High** | **Certificate pinning was removed, not fixed.** Commit `a56b062` deleted `api_certificate_pinning.dart` and `dio_certificate_pinning.dart` and the wiring in `connection.dart`. Dio now uses the default adapter and trusts any CA on the device, including user-installed MITM proxy CAs on rooted devices. The old code pinned the leaf SPKI, which breaks on every certificate renewal (the likely "bug"). `crypto` and `asn1lib` are still in `pubspec.yaml` but nothing uses them. | `lib/app_services/connection.dart:36-48`, `pubspec.yaml:28-29` | Decision |
| S5 | Medium | `android:showWhenLocked="true"` and `turnScreenOn="true"` on `MainActivity`. A ledger of personal gift amounts can appear over the lock screen. There's also no `FLAG_SECURE`, so screenshots and the recents thumbnail show balances. | `android/app/src/main/AndroidManifest.xml:43-44` | Decision |
| S6 | Medium | **Release logging leak:** about 50 raw `debugPrint(...)` calls, which still write to logcat in release builds. Some print exception or response text. | 17 files | **Fixed**: now use the release-gated `printDirect` |
| S7 | Medium | Passwords are `.trim()`-ed before they are sent, so a password with a leading or trailing space silently becomes a different password. This must change in the same way on signup, login, change and reset, or existing users get locked out. | `lib/app_pages/users/login/login_controller.dart:38`, `profile_page/change_password.dart:240-241`, `users/login/google_profile_setup_page.dart:80` | Decision |
| S8 | Low | `_dio.options.headers = await _getHeader(...)` changes the shared singleton's headers on every call, which can race between concurrent calls. The interceptor re-sets or removes `Authorization`, so it is safe today but fragile. Per-request `Options(headers:)` is cleaner. | `lib/app_services/connection.dart:245,297,351,404` | Decision (refactor) |
| S9 | Low | The admin WhatsApp number is hard-coded in the blocked-account dialog. | `lib/app_services/connection.dart:178` | Info |
| S10 | Low | Release `signingConfig` calls `error(...)` at configuration time when `key.properties` is missing, so a fresh clone can't even run a debug build. | `android/app/build.gradle.kts:38-43` | Info |

**Already good:**
- JWT and user info are stored only in `flutter_secure_storage` (Keychain `first_unlock_this_device`, no iCloud sync), and `AuthCredentialSanitizer` strips secrets.
- No `SharedPreferences` is used anywhere.
- `allowBackup=false` and data-extraction rules exclude everything from backup.
- `usesCleartextTraffic=false`.
- R8 minify and resource shrinking are on.
- The Remote Config `liveURL` is restricted to an exact HTTPS host and port allowlist.
- Log payloads are redacted (`redactSensitive`).
- Crashlytics never gets request bodies.
- There are no deep-link intent filters (only LAUNCHER), so there is no deep-link attack surface.
- Concurrent 401s are deduplicated.

**Dart obfuscation:** release builds should use `flutter build appbundle --obfuscate --split-debug-info=build/symbols`, and the symbols should be uploaded to Crashlytics. Nothing in the repo enforces this. Check your build script or CI.

---

## 2. Performance and correctness findings

| # | Sev | Finding | Where | Status |
|---|-----|---------|-------|--------|
| P1 | **High** | `use_build_context_synchronously` was **suppressed** in `analysis_options.yaml`, which hid **32** `BuildContext`-after-`await` sites. These can crash or misroute when the user leaves the screen mid-request. | `analysis_options.yaml` | **Fixed**: all 32 sites fixed and the lint re-enabled |
| P2 | **High** | A null `response` crashed the else branch (`response['responseValue']`), then the `catch` called `Navigator.pop` a second time and **closed the Add/Edit page itself**. | `lib/app_pages/transactions/add_edit_page.dart` `_submitTransaction` | **Fixed**: null-safe access plus a one-shot progress-dialog close |
| P3 | Medium | `setState` and the image cropper's `context` were used after the picker, crop and compress awaits with no `mounted` check. | `lib/app_pages/upcoming_functions/add_edit_upcoming_function.dart` `_pickImage` | **Fixed** |
| P4 | Medium | The `MaterialApp` (wrapped in `Consumer2<ThemeProvider, LanguageProvider>`) rebuilt a full `ThemeData` on every notify. Language load notified **twice** (in `_loadTranslations` and again in the caller), so startup and every language switch did two whole-app rebuilds with two theme builds each. | `lib/app_themes/theme_provider.dart` `getThemeForLanguage`, `lib/app_utils/app_providers/language_provider.dart` `_loadTranslations` | **Fixed**: ThemeData is now memoized per (seed, dark, language) and the duplicate notify is removed |
| P5 | Low | The OTP countdown `startTimer()` didn't cancel the previous `Timer.periodic`, and the resend path started the timer after an `await` with no `mounted` check. | `users/restore_account/restore_account_verify_otp.dart`, `users/forgot_password/verify_forgot_otp.dart` | **Fixed** |
| P6 | Low | 72 missing or redundant `const` constructors. | 16 files (`dart fix`) | **Fixed** |
| P7 | Medium | **Every** `LanguageProvider` change rebuilds the whole app, and many pages call `context.watch<ThemeProvider>()` at the top of `build()` (for example `home_page.dart` `build`) even though they only read colors through static `AppColors`. Moving to `context.select` or `Selector`, or dropping those watches, would narrow rebuilds. | `home_page.dart`, `transaction_dashboard.dart`, `more_page.dart`, `main_shell_page.dart`, others | Decision (refactor) |
| P8 | Medium | Very large `State` classes with page-wide `setState`: `profile_page.dart` (1,477 lines, 11 `setState`) and `notification_list_page.dart` (979 lines, 12). Splitting them into child widgets or `ValueListenableBuilder`s would limit rebuild scope. | those files | Decision (refactor) |
| P9 | Low | `MoiNetworkImage` uses `Image.network` with `cacheWidth` (good), but there's no disk cache, so images download again after every cold start. `cached_network_image` would fix this. | `lib/app_utils/app_widgets/moi_network_image.dart:34` | Decision (new dependency) |
| P10 | Low | `LayoutBuilder` + `OrientationBuilder` + `SizeConfig().get()` wrap `MaterialApp`, so a window-size change rebuilds the entire app. The app is locked to portrait, so the impact is small. | `lib/my_app.dart` `build` | Info |
| P11 | Low | `HomePage` doesn't implement `didUpdateWidget` for `refreshSignal`, so if the notifier instance ever changed, the old listener would stay attached. | `lib/app_pages/home_page/home_page.dart` `initState`/`dispose` | Info |

**Already good:**
- Controllers, timers and stream subscriptions are disposed. A scan of every `*Controller()`, `Timer` and `StreamSubscription` field found no leaks.
- Lists use `ListView.builder`/slivers.
- Images are sized with `cacheWidth`.
- Startup work is timed (`StartupTiming`), and the non-critical work is deferred with `unawaited` / post-frame callbacks.

---

## 3. What changed in this pass (uncommitted)

- `analysis_options.yaml`: removed the `use_build_context_synchronously: ignore` suppression.
- Async-gap fixes: the `LanguageProvider` is captured before the first `await`, and `mounted` guards were added in `feedbacks.dart`, `change_password.dart`, `add_edit_page.dart`, `add_transaction.dart`, `add_edit_upcoming_function.dart`, `forgot_password.dart`, `verify_forgot_otp.dart`, `google_profile_setup_page.dart`, `login_controller.dart`, `restore_account_verify_otp.dart` and `app_search.dart`.
- `add_edit_page.dart`: fixed the null-response crash and the double-pop.
- `theme_provider.dart`: memoized `ThemeData`. `language_provider.dart`: removed the duplicate notify.
- `debugPrint` → `printDirect` (release-gated) across 17 files. Removed the voice-locale debug print in `app_search.dart`.
- OTP timers now cancel before they restart.
- `dart fix`: `const` constructors were added and redundant `const` removed.

Checks: `flutter analyze` reports **No issues found** (it also passed before, but only with the lint suppressed). `flutter test`: 30 of 31 tests pass. `test/settings_menus_panel_dark_mode_test.dart` hangs, and it hangs the same way on a clean `HEAD` copy, so the hang predates this pass. The likely cause is that `LanguageProvider.ensureReady()` polls with `Future.delayed` inside `testWidgets`'s fake-async zone and never advances. It needs `tester.runAsync` or a mocked secure storage. Nothing has been run on a device.

---

## 4. Decisions needed (nothing committed)

1. **Signing key and SQL dumps (S1, S2).** `git rm --cached` them, add them to `.gitignore`, and **rotate**: request a Play upload-key reset, and treat every password hash in the dumps as exposed. Removing them from history (`git filter-repo`) needs a force-push and agreement from everyone who uses the repo.
2. **`X-API-Key` in the APK (S3).** Stop bundling `.env` and treat the key as public (rotate it). Then either drop the key check on the backend, or replace it with something that can't be extracted (Play Integrity / App Attest). Google client IDs are public by design and can stay as `--dart-define` values.
3. **Certificate pinning (S4).** Options: (a) restore pinning but pin the **intermediate or root CA SPKI** with a backup pin, so certificate renewals don't break it; (b) leave it off and remove the unused `crypto` and `asn1lib` dependencies. I recommend (a).
4. **Lock-screen exposure (S5).** Remove `showWhenLocked`/`turnScreenOn` unless a feature needs them, and add `FLAG_SECURE`, either for the whole app or only on screens that show amounts.
5. **Password trimming (S7).** Needs a matching backend and signup change, so it's left as is for now.
6. **Rebuild-narrowing refactor (P7, P8):** `Selector`s and splitting `profile_page` / `notification_list_page`. These are medium-sized refactors and should be tested on a device.
7. **Disk image cache (P9):** add the `cached_network_image` dependency.
8. **Per-request headers in `Connection` (S8).**
