# Moi Kanakku - Expense Tracking App

Moi Kanakku is a comprehensive expense tracking application built with Flutter, specifically designed to manage and track "Moi" (a Tamil term for gift/contribution) transactions for various functions and events. The app allows users to record both incoming and outgoing Moi transactions, manage functions, and generate reports.

## Technology Stack

### Flutter & Dart Versions
- **Flutter SDK**: 3.44.9 (CI pin; project floor ^3.32.0)
- **Dart SDK**: ^3.8.0

### Android
- **applicationId**: `com.renzo.moi`
- **minSdk**: 24
- **targetSdk**: 36
- **AGP**: 8.8.2
- **Gradle**: 8.10.2
- **Kotlin**: 2.1.0

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Connect to Firebase by following the Firebase setup instructions
4. For local **release** builds, copy `android/app/key.properties.example` to `android/app/key.properties` and point `storeFile` at your local keystore (never commit real credentials)
5. Run the app using `flutter run`

## App Security

The app implements several security features:
- Biometric authentication for app access
- Secure storage for sensitive information
- Firebase Crashlytics for monitoring app stability
- Firebase Performance for monitoring app performance

---

## GitLab CI/CD

This repository uses **GitLab CI/CD** (not GitHub Actions) to validate Merge Requests and to build a signed Android App Bundle (AAB) that is uploaded to **Google Play Console → Internal testing** after merges to `main`.

### Git workflow

```
feature/*
      ↓
Merge Request  →  flutter analyze  →  flutter test  →  PASS/FAIL
      ↓ (merge)
main
      ↓
GitLab CI/CD
      ↓
Flutter Analyze → Flutter Test → Build Signed AAB → Google Play (internal)
```

| Trigger | Analyze | Test | Build AAB | Deploy to Play |
|---------|---------|------|-----------|----------------|
| Feature branch push | Yes | Yes | No | No |
| Merge Request | Yes | Yes | No | No |
| Push / merge to `main` | Yes | Yes | Yes | Yes (internal by default) |
| `PLAY_STORE_TRACK=production` on `main` | Yes | Yes | Yes | **Manual** job only |

Feature branches and Merge Requests **never** deploy to Google Play.

### Protect the `main` branch

In GitLab: **Settings → Repository → Protected branches**

- Protect `main`
- Restrict who can push / merge
- Ensure production CI/CD variables are **protected** so only protected branches (and protected environments) can read them

Also protect the GitLab environment named `production` (**Settings → CI/CD → Environments** / environment protection) so only authorized users can deploy.

### Required GitLab CI/CD variables

Configure under **Settings → CI/CD → Variables**. Prefer **Protected** for all secrets. Mask where GitLab allows (large JSON/base64 values may need a **File** variable instead of Masked).

| Variable | Protected | Masked | Description |
|----------|-----------|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Yes | If size allows | Base64-encoded upload keystore (`.jks` / `.keystore`) |
| `ANDROID_KEYSTORE_PASSWORD` | Yes | Yes | Keystore password |
| `ANDROID_KEY_ALIAS` | Yes | Yes | Key alias |
| `ANDROID_KEY_PASSWORD` | Yes | Yes | Key password |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Yes | Prefer File variable | Full Google Play service account JSON |
| `PLAY_STORE_TRACK` | Optional | No | Default in pipeline: `internal`. Allowed: `internal`, `closed`, `open`, `production` |

Never commit keystores, `key.properties`, or service-account JSON. Never print secret values in job logs.

#### Encode the keystore for GitLab

```bash
base64 -i /path/to/your-upload-keystore.jks | pbcopy   # macOS
# or
base64 /path/to/your-upload-keystore.jks > keystore.b64
```

Paste the base64 string into `ANDROID_KEYSTORE_BASE64` (or upload as a File variable and adjust the pipeline if you prefer files).

#### Local signing example

```bash
cp android/app/key.properties.example android/app/key.properties
# Edit passwords, alias, and storeFile path — do not commit this file
```

### Google Play Console setup (manual)

Perform these steps once in Google Cloud / Play Console (use your real project and app; do not invent IDs):

1. Open [Google Play Console](https://play.google.com/console) and ensure the app for package **`com.renzo.moi`** exists.
2. Create or select a Google Cloud project linked to Play.
3. Enable the **Google Play Android Developer API**.
4. Create a **service account** in Google Cloud IAM.
5. Download the service account JSON key.
6. In Play Console → **Users and permissions**, invite the service account email and grant least privilege needed to upload releases to testing tracks (e.g. release to internal/closed/open testing; avoid broader permissions than required).
7. Paste the JSON into GitLab variable `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` (Protected; File variable recommended).
8. Configure Android upload signing secrets in GitLab (`ANDROID_KEYSTORE_*`).
9. Merge to `main` (or run a pipeline on `main`) to publish to the **internal** track.

If this repository previously contained keystore or password files in git history, **rotate** those credentials and treat the old material as compromised.

### Play Store track

Default track is **`internal`**.

Override with CI/CD variable `PLAY_STORE_TRACK`:

- `internal` (default) — automatic deploy on `main`
- `closed` — automatic on `main`
- `open` — automatic on `main`
- `production` — **manual** confirmation required in GitLab (protected `production` environment)

Do not set production accidentally. The pipeline will not auto-deploy to production.

### Versioning (`versionName` / `versionCode`)

In `pubspec.yaml`:

```yaml
version: 4.0.9+51
```

- **versionName** = `4.0.9` (user-visible)
- **versionCode** = `51` (integer Play requires to increase for every upload)

**Before each Play release**, bump the `+N` build number (and version name when appropriate), for example `4.1.0+52`. CI does **not** auto-increment versions. If Play already has that `versionCode`, upload fails with a clear error — bump and retry.

### Artifacts

Successful `main` builds store:

- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/bundle/release/app-release.aab.sha256`

Artifacts expire after 14 days in GitLab.

### Manual deployment

1. Ensure secrets are configured and `main` is protected.
2. Push/merge to `main`, or open **CI/CD → Pipelines → Run pipeline** on `main`.
3. For non-production tracks, deploy runs automatically after a successful signed AAB build.
4. For `PLAY_STORE_TRACK=production`, open the pipeline and click **Play** on the manual `deploy_google_play` job.

### Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Flutter installation failed | Image/network access to clone Flutter `3.44.9`; check `FLUTTER_VERSION` |
| Dependency installation failed | `flutter pub get` / pub.dev access |
| Flutter analyze failed | Fix analyzer issues locally with `flutter analyze` |
| Flutter tests failed | Run `flutter test` locally |
| Android signing failed | Missing/incorrect `ANDROID_KEYSTORE_*` variables; invalid base64 keystore |
| AAB build failed | Local `flutter build appbundle --release --no-tree-shake-icons`; NDK/SDK; `key.properties` |
| Google Play authentication failed | Service account JSON, Play API enabled, Play Console permissions |
| Google Play upload failed | Package `com.renzo.moi`, track name, AAB path, network |
| Existing versionCode already used | Increment `+N` in `pubspec.yaml` and merge again |

Pipeline jobs fail loudly with these messages; do not ignore red jobs.

---

## Contribution

This project is maintained by GP_Dhanush. For any queries or suggestions, please contact through the app's contact us section.
