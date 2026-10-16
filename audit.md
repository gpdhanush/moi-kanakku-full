# Flutter Mobile App — Codebase Audit Instructions

## Role

Act as a **Senior Flutter Architect** performing a **read-only audit** of the existing Flutter application.

Your job is to **inspect, map, and document** the current system before any code is changed.

Do **not** rewrite, refactor, redesign, or “improve” code during this audit.

---

## Scope

These instructions apply **ONLY** to the Flutter mobile application:

- Primary path: `mobile-app/`

Do **not** treat the following as in-scope for changes or redesign:

- Angular web application (`moi_kanakku/`, `public_web/`, `admin-app/`)
- Node.js / backend APIs
- Database / server-side code

You may briefly open backend or API docs **only** when needed to clarify a client API contract. Do not audit or modify them.

---

## Hard Rule — Inspect Before Changing Anything

Until the audit report file exists and is complete:

1. Do **not** edit Dart source, UI, themes, routes, services, models, or config.
2. Do **not** add dependencies or run refactors “while exploring.”
3. Do **not** apply UI redesign from `design.md` during the audit.
4. Do **not** implement items from `production-prompt.md` during the audit.

**Allowed actions during the audit:**

- Read files and folders
- Search the codebase
- Cross-check existing docs under `mobile-app/Documents/`
- Write / update the audit report at the path specified below

After the report is written, stop and wait for an explicit instruction to implement changes.

---

## Where to Look First

Start with these entry points (paths relative to `mobile-app/`):

| Area | Path |
|------|------|
| Dependencies / SDK | `pubspec.yaml` |
| Bootstrap | `lib/main.dart` |
| App shell | `lib/my_app.dart` |
| Routes / guards | `lib/app_configs/app_routes.dart` and other files in `lib/app_configs/` |
| Screens / features | `lib/app_pages/` |
| HTTP / APIs | `lib/app_services/` (especially `connection.dart`) |
| Shared models | `lib/app_models/` |
| Feature models | `lib/app_pages/**/models/` |
| Shared widgets / forms / helpers | `lib/app_utils/app_widgets/`, `lib/app_utils/app_forms/`, `lib/app_utils/app_global/` |
| App-level providers | `lib/app_utils/app_providers/` |
| Design tokens / theme | `lib/app_themes/` |
| Secure storage | `lib/app_storages/` |
| Firebase | `lib/app_firebase/` |
| Existing analysis | `Documents/` (especially `PROJECT_ANALYSIS_AND_IMPROVEMENTS.md`, `API_REFERENCE.md`, `OFFLINE_FIRST_PLAN.md`) |

### Seeded architecture map (verify; do not assume still accurate)

Use this as a **starting hint**, then confirm against the live tree:

- **Screens:** `lib/app_pages/<feature>/`
- **Navigation (primary):** `MaterialApp` + named routes via `onGenerateRoute` / `AppRoute.allRoutes` in `lib/app_configs/app_routes.dart`
- **Navigation (partial):** `go_router` may exist in `pubspec.yaml` / `app_routes.dart` but may not be the root router — document the actual wiring
- **APIs:** Dio-based services under `lib/app_services/`, shared client in `connection.dart`
- **State:** `provider` + `ChangeNotifier` (theme, language, connectivity, user, plus any local controllers)
- **Shared UI:** `lib/app_utils/app_widgets/`, forms under `app_forms/`, cross-cutting helpers under `app_global/`
- **Tokens:** colors / typography / radius / themes under `lib/app_themes/`

If reality differs from this map, **record what you find** and mark the seed as outdated in the report.

---

## Audit Mission

Inspect the existing codebase and produce a structured inventory of:

1. Current screens and routes
2. APIs / networking services
3. Models / data shapes
4. State management
5. Reusable widgets and shared helpers
6. Technical debt and risks

The goal is a clear map so future Cursor work can change the app without breaking behavior or reinventing structure.

---

## Required Report Sections

Write findings into:

**`mobile-app/Documents/CODEBASE_AUDIT.md`**

If that file already exists, update it in place rather than creating a second audit file.

Use concrete file paths. Prefer tables and bullet lists. If something cannot be determined from the code, write `Unknown` — do not invent.

### 1. Project overview

- App name / purpose (from README / product docs)
- Flutter / Dart SDK constraints from `pubspec.yaml`
- High-level folder architecture under `lib/`
- Package stack relevant to architecture (state, routing, HTTP, storage, Firebase, etc.)

### 2. Screen / route inventory

For each user-facing screen or major flow, record:

| Screen / flow | File path | Route name / path | Auth required? | Offline / special guard? | Notes |
|---------------|-----------|-------------------|----------------|--------------------------|-------|
| … | … | … | … | … | … |

Also summarize:

- Initial route / splash behavior
- Auth guard behavior
- Connectivity / no-internet routing
- Force update / maintenance / configuration-error screens if present

### 3. API / service inventory

For each service class / networking module:

| Service | File path | Main endpoints / methods | Auth / headers | Error handling pattern | Notes |
|---------|-----------|--------------------------|----------------|------------------------|-------|
| … | … | … | … | … | … |

Also document:

- Dio (or other) client setup (`connection.dart` and related config)
- Base URL / Remote Config / env loading
- Certificate pinning / allowlist / API security helpers under `app_configs/`
- Duplicate or overlapping API calls if found

### 4. Model inventory

| Model | File path | Shared vs feature-local | Serialization style | Used by |
|-------|-----------|-------------------------|---------------------|---------|
| … | … | … | Map / hand-written / codegen / Unknown | … |

Note missing models, ad-hoc `Map<String, dynamic>` usage in UI/services, and inconsistent naming.

### 5. State management map

| Provider / controller | File path | Type | Wired in | Owns / responsibilities |
|-----------------------|-----------|------|----------|-------------------------|
| … | … | ChangeNotifier / other | `main.dart` / `my_app.dart` / local | … |

Also note:

- Global vs screen-local state
- Any unused or partially wired state libraries (e.g. `go_router` / other packages present but not root-wired)

### 6. Reusable widgets / forms / helpers catalog

List shared building blocks under:

- `lib/app_utils/app_widgets/`
- `lib/app_utils/app_forms/`
- `lib/app_utils/app_global/`
- Feature-local `widgets/` folders that are candidates for promotion

For each notable widget/helper: **name, path, purpose, where reused**.

### 7. Navigation and auth flow summary

Describe, in prose + a short flow list:

- App start → splash / onboarding / permissions → login → main shell
- How tokens / session are stored and checked
- Biometric / restore-account / password-reset entry points if present
- Hybrid Navigator vs `go_router` reality

### 8. Persistence, Firebase, and security touchpoints

Document locations and roles for:

- Secure storage
- Local preferences / caches if any
- Firebase (core, remote config, messaging, Crashlytics, etc.)
- Certificate pinning / endpoint allowlist
- Secrets / dotenv usage (do **not** paste secret values into the report)

### 9. Technical debt and risks

Call out concrete issues with file paths, such as:

- Duplicate widgets or duplicated business logic
- Logic living in UI widgets that belongs in services/controllers
- Hybrid or incomplete routing migration
- Hardcoded colors, strings, dimensions, URLs
- Large / complex widgets
- Weak or inconsistent error handling
- Null-safety / async hazards
- Missing or thin tests
- Dead code or unused dependencies
- Performance risks (unnecessary rebuilds, heavy work on UI isolate)

Severity labels: `High` / `Medium` / `Low`.

### 10. Safe-change recommendations (no implementation)

Ordered list of recommended next steps **after** this audit, for a human or later Cursor session:

1. Highest-value, lowest-risk improvements
2. Structural cleanups that need care
3. Items that must wait for product/design decisions

Do **not** implement these in the audit pass.

---

## Method

1. Scan `mobile-app/lib/` and `mobile-app/pubspec.yaml`.
2. Trace bootstrap from `main.dart` → `my_app.dart` → routes → first screens.
3. Inventory screens, services, models, providers, and shared widgets.
4. Cross-check (do not replace) existing docs:
   - `mobile-app/Documents/PROJECT_ANALYSIS_AND_IMPROVEMENTS.md`
   - `mobile-app/Documents/API_REFERENCE.md`
   - `mobile-app/Documents/OFFLINE_FIRST_PLAN.md`
   - `mobile-app/README.md`
5. Write `mobile-app/Documents/CODEBASE_AUDIT.md` with all required sections.
6. Stop. Do not modify application code until explicitly asked.

---

## Relationship to Other Docs

| Doc | When to use |
|-----|-------------|
| **`audit.md` (this file)** | First. Read-only inventory before any change. |
| **`design.md`** | After audit, for UI/UX and visual design work only. |
| **`production-prompt.md`** | After audit, for controlled architecture / quality improvements. |
| **`mobile-app/Documents/CODEBASE_AUDIT.md`** | Output of this audit; living map of the current app. |

Future Cursor sessions that change the Flutter app should read the latest `CODEBASE_AUDIT.md` (or re-run this audit if it is missing / clearly stale) before editing.

---

## Definition of Done

The audit is complete only when:

- [ ] `mobile-app/Documents/CODEBASE_AUDIT.md` exists
- [ ] All ten required sections are filled with path-backed findings
- [ ] Unknowns are marked `Unknown` instead of guessed
- [ ] No application source files were modified as part of the audit
- [ ] The agent stopped without starting redesign or refactor work
