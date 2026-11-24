# Anti-clone / anti-scraping hardening

Protections against the app, site and API being copied, scraped or
reverse-engineered — including by AI crawlers and agents.

> **Reality check:** nothing here makes the product un-copyable. A browser must
> receive the website's HTML/JS, and an APK can be decompiled. These measures
> *raise the cost* and block automated AI crawlers/agents; they are not DRM.

## Website (`public_web/`)

- **`public/robots.txt`** — allows real search engines and AI *search* citers
  (which send traffic), blocks AI training / cloning crawlers: GPTBot,
  ClaudeBot, Google-Extended, CCBot, Bytespider, Amazonbot, Meta agents,
  Diffbot, PerplexityBot-Extended, etc.
- **`src/server.ts`** — adds security headers to every SSR response:
  `X-Frame-Options: DENY` (no framing / UI-wrapping clones),
  `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`,
  `Cross-Origin-Opener-Policy`, and `X-Robots-Tag: noarchive, nosnippet`.
- Production builds ship **no source maps** (Vite default), so the original
  TypeScript isn't served.

## Mobile app (`mobile-app/`)

- **`scripts/build_release.sh`** — release build with **Dart obfuscation**
  (`--obfuscate --split-debug-info`). Symbol maps go to `build-symbols/<version>/`
  (git-ignored) — **archive them** to de-obfuscate crash reports.
  - `./scripts/build_release.sh aab` (Play Store) or `apk` (sideload).
- **`android/app/build.gradle.kts`** — release already has `isMinifyEnabled`,
  `isShrinkResources` and ProGuard (`proguard-android-optimize`).
- **`android/app/proguard-rules.pro`** — strips `android.util.Log` from release
  and renames source-file attributes in stack traces.

## Backend (`backend/`)

The API already requires a secret `X-API-Key`, rate-limits, validates origin
and uses `helmet`, so it can't be scraped without the key. Added:

- **`src/middlewares/apiSecurity.js`**
  - `aiBotGuard` — rejects known AI-crawler / scraper User-Agents with `403`.
    The Flutter app sends a `Dart/...` UA and is unaffected; browsers pass too.
    Disable with `DISABLE_AI_BOT_GUARD=true` if it ever misfires.
  - `noIndexHeader` — `X-Robots-Tag: noindex, nofollow, noarchive, nosnippet`
    on all API responses.
- Wired in **`src/routes/index.js`** before the rate limiter.

### Env flags

| Var | Effect |
|---|---|
| `DISABLE_AI_BOT_GUARD=true` | Turn off the User-Agent bot block |
| `ALLOWED_ORIGINS` | Comma-separated origins allowed to call the API (existing) |

## Tightening further later

- Block AI *search* agents too (`ChatGPT-User`, `OAI-SearchBot`,
  `Claude-SearchBot`, `PerplexityBot`) in `robots.txt` if you want zero AI
  access — at the cost of AI-search visibility.
- Put the site behind Cloudflare Bot Fight Mode / WAF managed rules.
- Add Play Integrity / app attestation on the backend if you need to prove
  requests come from the genuine app, not a repackaged clone.
