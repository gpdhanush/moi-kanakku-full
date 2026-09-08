# Offline-First Architecture Plan — Moi Kanakku

> Living document. Update as decisions and implementation progress.
> Last reviewed: 2026-07-20

---

## 1. Goal

Make the app usable **without network** for core moi accounting flows (persons, transactions, functions), then sync safely when online.

**Offline-first means:** local database is the source of truth for domain data. The API is a remote adapter. Isolates help with background sync; they do not replace local persistence.

---

## 2. Current architecture (as of 4.0.5+47)

```
UI (StatefulWidget / thin controllers)
  → *Services (thin API wrappers; each owns Connection)
    → Connection (Dio + pinning + Bearer token + EasyLoading)
      → REST API (https://moi-kanakku-api.prasowlabs.in/apis)

SecureStorage ← session / prefs only (token, login flag, user blob, theme, language)
Provider ← UI state (user, theme, language, connectivity)
Firebase ← Remote Config, FCM, Crashlytics
```

| Topic | Reality |
|-------|---------|
| Stack | Flutter ^3.8, Provider, Dio, `flutter_secure_storage`, `connectivity_plus` |
| Local DB | **None** (no Hive / SQLite / Drift / Isar) |
| Repository layer | **None** — pages call services that hit the network |
| Outbox / retry queue | **None** |
| Offline UX | Hard block: `NoInternetPage` on all routes when offline |
| Isolates for API | **Not used** — only PDF base64 encode uses `Isolate.run` |
| Home cache | In-memory 5-minute TTL only |

### Key files

| Area | Path |
|------|------|
| Dio client | `lib/app_services/connection.dart` |
| Transactions / persons | `lib/app_services/transaction_services.dart` |
| Legacy moi APIs | `lib/app_services/moi_services.dart` |
| Auth / profile | `lib/app_services/user_services.dart` |
| Functions | `lib/app_services/function_services.dart` |
| Upcoming functions | `lib/app_services/upcoming_function_services.dart` |
| Routes / offline gate | `lib/app_configs/app_routes.dart` |
| Connectivity | `lib/app_utils/app_providers/connectivity_provider.dart` |
| Secure storage | `lib/app_storages/` |

---

## 3. Feasibility verdict

**Yes — offline-first is possible.** Networking is already centralized on Dio + thin services, which makes a remote adapter + repository layer a natural fit.

Effort: **medium–large**, best done in phases (cache → write queue → sync isolate).

### What already helps

- Thin `*Services` wrapping REST
- Session restored from secure storage (returning users can open the app)
- `ConnectivityProvider` already detects online/offline
- Remote Config partially cached on splash

### Biggest blockers

1. Global offline lock (`NoInternetPage` on every route)
2. No local persistence for domain data
3. No repository / outbox pattern
4. UI tightly coupled to network (EasyLoading on almost every Dio call)
5. Multiple `Connection()` instances (not a shared singleton)
6. Overlapping APIs (`MoiServices` vs `TransactionServices`)
7. Multipart image uploads need deferred file paths if queued

---

## 4. Target architecture

```
UI
  → Repository (read/write local first)
      → Local DB (Drift / Isar / SQLite)  ← source of truth
      → Outbox queue (pending create/update/delete)
  → Connectivity online
      → SyncEngine (optional Isolate)
          → Connection (singleton Dio) → API
          → merge server results into Local DB
```

### Design rules

1. **UI never calls Dio directly** — only repositories.
2. **Reads** always prefer local DB; refresh from API when online.
3. **Writes** go to local DB + outbox; sync later.
4. **Connection** becomes a remote-only adapter (no EasyLoading on sync path).
5. **One shared Dio** for auth, pinning, and sync.
6. Offline gate becomes a **banner / pending indicator**, not a full-screen block for authenticated routes.

---

## 5. Isolates for send / retrieve

| Use | Recommendation |
|-----|----------------|
| Offline-first itself | Local DB + outbox (required) |
| Heavy JSON parse / batch merge | `compute` or `Isolate.run` (optional) |
| Background push/pull sync | Dedicated SyncEngine; isolate if work is heavy |
| Every single API call in an isolate | **Not recommended** — Dio/plugins/secure storage need care across isolates |

**Important:** Isolate ≠ offline-first. Isolates keep sync off the UI thread; they do not store data when offline.

---

## 6. Domain sync priority

| Priority | Domain | Notes |
|----------|--------|-------|
| P0 | Persons | Core CRUD |
| P0 | Transactions (RETURN / INVEST) | Core CRUD |
| P0 | Transaction-functions | Linked to transactions |
| P0 | Home totals / dashboard | Cache after fetch |
| P1 | Functions list | List + CRUD |
| P1 | Profile (read) | Edit may stay online-first initially |
| P2 | Upcoming functions | Secondary |
| Online-only (for now) | OTP, login restore, feedback submit, notifications, most image uploads | Queue uploads later if needed |

---

## 7. Auth & session offline

| Scenario | Behavior |
|----------|----------|
| Returning logged-in user, offline | Allow app open using stored `isLogin` + user blob (after relaxing route gate) |
| Fresh login / OTP / restore | Requires network |
| Token expiry / 401 | Clear session only on real auth failure — not on transient network errors |
| Token refresh | Not present today; document if API adds refresh later |

---

## 8. Phased plan

### Phase 1 — Read offline (cache)

- [ ] Choose local DB (candidate: **Drift** or **Isar**)
- [ ] Add tables for persons, transactions, functions, home totals snapshot
- [ ] Introduce repositories; pages read from repo
- [ ] After successful online fetch, upsert into local DB
- [ ] Relax `AppRoute` offline gate for authenticated home / list routes
- [ ] Show subtle offline indicator instead of full-screen block

### Phase 2 — Write offline (outbox)

- [ ] Outbox table: `id`, `entity`, `operation`, `payload`, `localId`, `status`, `retries`, `createdAt`
- [ ] Create/update/delete → write local + enqueue outbox
- [ ] Mark UI rows as `pending` / `synced` / `failed`
- [ ] On connectivity restored → drain outbox via SyncEngine
- [ ] Conflict policy: **last-write-wins** initially (document exceptions)

### Phase 3 — Sync isolate + polish

- [ ] Singleton `Connection` / Dio
- [ ] Strip EasyLoading from sync path
- [ ] Optional isolate/worker for batch sync + JSON parse
- [ ] Image upload queue (file path + retry)
- [ ] Unify overlapping moi vs transaction APIs where possible
- [ ] Conflict UI for failed sync items

---

## 9. Suggested folder layout (future)

```
lib/
  app_data/
    local/          # DB schema, DAOs
    remote/         # keep or wrap existing *Services
    repositories/   # TransactionRepository, PersonRepository, ...
    sync/           # Outbox, SyncEngine, SyncIsolate entry
  app_services/     # existing Dio wrappers (become remote adapters)
```

*(Adjust names to match team preference when implementing.)*

---

## 10. Conflict & edge cases (to decide later)

| Case | Proposed default | Decision |
|------|------------------|----------|
| Same record edited offline + online | Last-write-wins | _TBD_ |
| Create offline then delete before sync | Cancel outbox create | _TBD_ |
| Server rejects outbox item | Mark failed; keep local; allow retry/edit | _TBD_ |
| Large list pagination offline | Cache last N pages / per-function lists | _TBD_ |
| Force update / maintenance while offline | Use last known Remote Config; block only when online and flagged | _TBD_ |

---

## 11. Non-goals (for now)

- Full CRDT / multi-device realtime merge
- Offline OTP / account restore
- Replacing Provider with another state library solely for sync
- Offline Firebase Auth flows (app uses custom JWT API)

---

## 12. Open questions

1. Preferred local DB: Drift vs Isar vs raw SQLite?
2. Should sync run only on app foreground, or also via background fetch / WorkManager?
3. Per-user DB encryption needed beyond secure storage for token?
4. Can backend expose `updatedAt` / sync cursors for incremental pull?
5. Keep `MoiServices` endpoints or migrate fully to `TransactionServices`?

---

## 13. Changelog

| Date | Change |
|------|--------|
| 2026-07-20 | Initial analysis and phased plan documented |

---

## 14. References (in-repo)

- `lib/app_services/connection.dart` — Dio hub
- `lib/app_configs/app_routes.dart` — offline route gate
- `lib/app_utils/app_providers/connectivity_provider.dart`
- `pubspec.yaml` — current dependencies (no local DB yet)
`)