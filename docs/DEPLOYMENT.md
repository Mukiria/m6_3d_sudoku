# Production Deployment — M6 Sudoku

## 0. Reality check first

M6 Sudoku is a **client-only Flutter app**: Android (Play Store) + static Web
(currently `m6-sudoku.web.app`). Per `whatitis.md`, there is no backend, no
database, and zero external service integrations — all state lives in
`SharedPreferences` on-device. That changes what "production deployment"
means here:

- There is no server fleet to design infrastructure for, no API to put
  behind a load balancer, and nothing to run in Kubernetes *today*.
- "Scaling" is mostly already solved for you — a CDN-backed static site and
  the Play Store both scale automatically; the scaling work that's actually
  yours is app-side (bundle size, isolate-based generation, render
  performance).
- "Downtime" doesn't mean a server falling over. It means: a bad release
  crash-looping on users' devices, a broken web deploy, or silent data loss
  in local storage.

Everything below is adapted to that reality rather than forcing a
service-shaped runbook onto a client app. Section 6 covers Docker/Kubernetes
directly, including the one place a container genuinely helps this project
today and a reference design for *if* a backend gets built later.

**One blocking finding surfaced while building this** — needs your decision
before the pipeline below can run for real; see the checklist in §8:

1. **Every release build to date has been debug-signed.** `build.gradle`
   falls back to the debug signing config whenever `android/key.properties`
   is missing, which is always true on a CI runner — there's no keystore
   secret configured in GitHub Actions. That means the APK/AAB attached to
   past GitHub Releases (built by the old `release.yml`) were never
   suitable for a real Play Store upload. Fixed going forward in the
   updated `release.yml`, gated behind secrets you still need to add
   (§4.3).

---

## 1. Infrastructure architecture

```
                        ┌─────────────────────────┐
                        │        GitHub repo       │
                        │  (source of truth, main) │
                        └────────────┬─────────────┘
                                     │ push / PR / tag
                                     ▼
                        ┌─────────────────────────┐
                        │     GitHub Actions       │
                        │  ci / release / deploy   │
                        └───────┬─────────┬────────┘
                                │         │
                 build+sign AAB │         │ build web bundle
                                ▼         ▼
                 ┌───────────────────┐ ┌──────────────────────┐
                 │  Play Console     │ │  Firebase Hosting     │
                 │  internal track → │ │  preview channel (PR) │
                 │  closed → open →  │ │  → live channel (main)│
                 │  production       │ │  (global CDN, atomic  │
                 │  (staged rollout) │ │  deploys, 1-click     │
                 │                   │ │  rollback)             │
                 └─────────┬─────────┘ └──────────┬────────────┘
                           │                       │
                           ▼                       ▼
                 ┌────────────────────────────────────────┐
                 │              End-user devices            │
                 │  Android app (APK/AAB) · Browser (PWA)   │
                 │  All game state: on-device only          │
                 │  (SharedPreferences, no server round-trip)│
                 └───────────────────┬──────────────────────┘
                                     │ crash/perf events (opt-in)
                                     ▼
                 ┌────────────────────────────────────────┐
                 │   Firebase Crashlytics + Performance     │
                 │   Monitoring, + Play Console Vitals      │
                 │   (crash rate, ANR rate, vitals alerts)  │
                 └────────────────────────────────────────┘
```

No app servers, no database tier, no message queue — by design, not by
omission. The only two "environments" that matter are **Play Console
tracks** (internal → closed → open → production) and **Firebase Hosting
channels** (preview → live).

## 2. Deployment workflow

**Branching:** `main` is the trunk (already the case). Protect it:
required PR reviews + required `CI` status check before merge (currently
nothing appears to enforce this — add a branch protection rule).

**Versioning:** `pubspec.yaml`'s `version: X.Y.Z+N` is the single source of
truth (`X.Y.Z` → `versionName`, `N` → Android `versionCode`, both wired
through `flutter.versionName`/`flutter.versionCode` in `build.gradle`).
Release flow:

1. Bump `version:` in `pubspec.yaml` on a PR into `main`.
2. Merge → CI runs (build/test/lint/analyze, now also a web-build check).
3. Tag the merge commit `vX.Y.Z+N` and push the tag → `release.yml` fires:
   builds a **signed** APK+AAB, cuts a GitHub Release, uploads the AAB to
   the Play **internal** track as a draft, uploads de-obfuscation symbols.
4. Human promotes internal → closed/open testing → production in Play
   Console, using staged rollout percentages (see §5).
5. Web ships continuously and separately: every merge to `main` deploys to
   the Firebase Hosting **live** channel via `deploy-web.yml`; every PR gets
   its own **preview** channel URL for review before merge.

Mobile and web are intentionally decoupled — a web deploy doesn't wait on
a Play Store review, and a Play Store release doesn't block on a web
deploy.

## 3. CI/CD pipeline (as configured in this repo)

Three GitHub Actions workflows already existed; I fixed the version drift
between them, closed the debug-signing gap, and added web validation.
Two new workflows handle actual deployment (previously there was none).

| Workflow | Trigger | Does |
|---|---|---|
| `.github/workflows/ci.yml` | push/PR to `main` | format check (a real gate on committed code — it previously auto-formatted first, so it could never fail), `flutter analyze`, `flutter test --coverage` (now uploaded as an artifact), **`flutter build web --release`** (new — validates the web target on every PR; previously only Android was built, so web-only regressions could land silently), build+upload debug-signed APK for manual QA sideloading |
| `.github/workflows/release.yml` | push tag `v*` | **tag must equal pubspec `version:`** (fails fast otherwise) → pub get → codegen → analyze → test → **real release signing from secrets** (new) → `--obfuscate --split-debug-info` (new) → build APK+AAB → GitHub Release → **Play Console internal-track upload** (new, gated on secrets, `status: draft` so a human still hits publish). An unsigned build is published as a GitHub **pre-release** and never sent to Play. Also runnable by hand (Actions → Release → Run workflow, any branch): builds the same signed APK/AAB as a 30-day run artifact, with no tag, GitHub Release, or Play upload |
| `.github/workflows/deploy-web.yml` (new) | push/PR to `main` | build web → Firebase Hosting **preview channel** on PRs, **live channel** on `main`. Hosting config is `firebase.json` (SPA rewrite, `no-cache` on JS/HTML/wasm so a deploy is picked up on next load, 1-day cache on images/fonts/audio, basic security headers) |
| `.github/workflows/BuildAPK.yml` | manual (`workflow_dispatch`) | unchanged — ad hoc debug-signed APK for quick sideload testing, doesn't need signing secrets |

All workflows use `concurrency` groups: CI and PR previews cancel superseded
runs; live web deploys and releases queue instead, so an older build can
never finish last and overwrite a newer one.

All the version-drift fixes, signing wiring, obfuscation flags, and new
workflows are already written into the repo (not just proposed) — see the
diffs. **They will not silently do anything dangerous**: the signing and
Play/Firebase steps check for their secrets first and emit a `::warning::`
and skip themselves if absent, rather than failing the whole pipeline or
falling through to an insecure default silently. Nothing publishes to real
users until you add the secrets in §4.3 and §8.

### 4.1 Required GitHub Secrets

| Secret | Used by | Source |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | `release.yml` | `base64 -i android/app/keystore/upload-keystore.jks` — **the existing local upload keystore already in the repo working tree (untracked)**; don't generate a new one or Play Console will reject updates |
| `ANDROID_KEYSTORE_PASSWORD` | `release.yml` | from `android/key.properties` (local, untracked) |
| `ANDROID_KEY_ALIAS` | `release.yml` | from `android/key.properties` |
| `ANDROID_KEY_PASSWORD` | `release.yml` | from `android/key.properties` |
| `PLAY_SERVICE_ACCOUNT_JSON` | `release.yml` | Play Console → Setup → API access → create/link a Google Cloud service account with **Release Manager** permission, download its JSON key |
| `FIREBASE_SERVICE_ACCOUNT` | `deploy-web.yml` | `firebase init hosting:github` locally (interactive; creates this secret and the workflow wiring for you) or Firebase Console → Project Settings → Service Accounts |
| `FIREBASE_PROJECT_ID` (repo **variable**, not secret) | `deploy-web.yml` | your Firebase project ID |

None of these exist yet (confirmed: no `firebase.json`/`.firebaserc` in the
repo, no Play service account referenced anywhere). Until they're added,
`release.yml` still produces a GitHub Release (debug-signed, with a loud
warning) and `deploy-web.yml` simply no-ops with a warning — nothing is
blocked, nothing fails destructively.

## 5. Reliability & downtime-risk reduction

For a client app, "reliability" is about **blast radius control on
releases**, not uptime of infrastructure you don't have:

- **Staged rollout on Android**: never publish straight to 100% production.
  Play Console supports a percentage rollout (start at 5–10%, watch
  Crashlytics/Vitals for a few hours to a day, then ramp). If crash rate
  spikes, halt the rollout from Play Console — no rollback deploy needed,
  affected users just never got the bad build.
- **Play Console pre-launch report**: automatically installs the AAB on a
  matrix of real/virtual devices and flags crashes before you roll out —
  free, already available once you're uploading through the API/console,
  costs nothing to turn on.
- **Web has near-zero-downtime deploys by construction**: Firebase Hosting
  deploys are atomic (new version goes live all-at-once, not
  file-by-file) and every previous deploy stays available for instant
  rollback (`firebase hosting:clone` or the console's "rollback" button on
  a prior release) — this is a real, practical mitigation, unlike most of
  the advice that gets copy-pasted from server-side runbooks.
- **R8/ProGuard risk**: `isMinifyEnabled`/`isShrinkResources` are both
  `true` in release builds, but `android/app/proguard-rules.pro` is
  effectively empty (one comment line). Minification-induced runtime
  breakage (reflection, native method binding) typically only shows up in
  *release* builds, which is exactly the build type least tested day to
  day. Concretely: install the signed release AAB/APK on a real device and
  smoke-test both game modes before every rollout, don't rely on debug
  builds as a proxy.
- **Local-only storage is itself a reliability gap, not just a DevOps
  concern**: a player's entire progress (streaks, statistics, in-progress
  puzzles) lives in `SharedPreferences` with no export/import. An app
  uninstall, device loss, or storage corruption is unrecoverable data loss
  today. This is a product decision, not something a pipeline fixes, but
  it's worth flagging: even a simple "export save data to a file" /
  "restore from file" feature would meaningfully de-risk this without
  requiring the cloud-sync backend in §6.3.
- **CI as a release gate**: `release.yml` now runs `flutter analyze` +
  `flutter test` before it will build/sign/publish anything — a red test
  suite can't produce a tagged release.

## 6. Docker / Kubernetes

### 6.1 Why not for the app itself
Docker/Kubernetes solve problems of running and scaling *server processes*.
This app has none — the Android build produces an APK/AAB consumed by Play
Store infrastructure Google already operates at whatever scale is needed;
the web build produces static files served from a CDN that scales
automatically. Containerizing either would add an orchestration layer with
nothing underneath for it to orchestrate.

### 6.2 Where Docker genuinely helps here: reproducible builds
Added `Dockerfile.ci` at the repo root — a pinned Flutter 3.29.3 + Android
SDK image. Use it to guarantee a contributor's or self-hosted runner's local
build matches CI exactly, independent of what's installed on that machine:

```bash
docker build -f Dockerfile.ci -t m6-sudoku-builder .
docker run --rm -v "$PWD":/workspace m6-sudoku-builder \
  "flutter build apk --release --split-per-abi"
```

Not wired into `ci.yml`/`release.yml` — GitHub-hosted runners with
`subosito/flutter-action`'s own caching are faster than pulling/building
this image on every run. It's there for local parity and as a ready base
image if you ever move to self-hosted runners.

### 6.3 If a backend ever gets built (cloud sync is listed as "Planned")
`infra/future-backend/` has a reference Dockerfile + minimal Kubernetes
manifests (Deployment/Service/HPA) for that scenario, with a README
explaining the reasoning. Short version: **start on Cloud Run, not GKE** —
a sync API for small JSON blobs at indie-app traffic volumes is exactly the
spiky/low-volume workload managed serverless containers are for; a
Kubernetes cluster's fixed control-plane/node overhead buys you nothing at
that scale. Move to the `k8s/` manifests only once there's a concrete,
evidenced reason Cloud Run can't keep up. Nothing in this section is wired
into any pipeline — it's a starting point for that day, not current work.

## 7. Monitoring & logging strategy

**Currently: none.** No Crashlytics, Sentry, or analytics dependency exists
in `pubspec.yaml`, confirmed. The app's `logger` package writes locally
only — nothing leaves the device. The app hasn't been published yet, so
this is the moment to decide: without it, you'll launch blind to crash rate,
ANR rate, and error frequency in the wild except what users choose to report.
Adding Crashlytics also means updating the Play **data safety** form
(crash logs + device info are collected), so it's a decision, not just a
dependency.

**Recommended, in priority order:**

1. **Firebase Crashlytics** (`firebase_crashlytics` + `firebase_core`) —
   free, integrates with the Firebase project you're already setting up
   for Hosting (§4.1), and directly consumes the `--split-debug-info`
   symbols the updated `release.yml` now produces. Wrap `main.dart`'s
   top-level error handling (`PlatformDispatcher.instance.onError`,
   `FlutterError.onError`) to report to Crashlytics; route the existing
   `logger` calls at `error`/`fatal` level there too as breadcrumbs.
2. **Firebase Performance Monitoring** — nearly free given Crashlytics is
   already wired; flags slow frames/jank, useful given this app has
   genuinely CPU-heavy operations (cube geometry rendering, isolate-based
   puzzle generation) worth watching for regressions across releases.
3. **Play Console Vitals** (no code change — already collected by Google
   Play Services once the app is published) — crash rate, ANR rate, and
   "bad behavior" thresholds that can gate a staged rollout's next ramp.
   Check this on every rollout, not just when something looks wrong.
4. **Structured release-correlated logging**: tag Crashlytics
   custom keys with `versionName`+`versionCode` and game mode (classic vs.
   cube) at session start, so a spike is immediately attributable to a
   specific release and feature area, not just "app version X".
5. Deliberately **not** recommending a general analytics SDK
   (Firebase Analytics/Amplitude/etc.) by default — this app currently has
   zero telemetry and that's a legitimate privacy-respecting design choice
   per `whatitis.md`. Add it only if you actually want product analytics,
   as a separate, explicit decision — don't bundle it in "just because
   Crashlytics needs Firebase anyway."

## 8. Production deployment checklist

**Blocking — resolve before enabling automated publishing:**
- [x] `applicationId` confirmed as `com.msixv.m6sudoku` (the app has not
      been published yet, so this is the id the *first* Play Console
      listing should be created under — `build.gradle.kts`,
      `release.yml`, `README.md`, and `RELEASE_NOTES.md` are now
      consistent on this value).
- [ ] An upload keystore already exists locally, untracked, at
      `android/app/keystore/upload-keystore.jks` (alias `upload`, per
      `android/key.properties`). Since nothing has been published yet,
      **this is the keystore to register with Play Console on first
      upload** — don't generate a new one. Base64-encode it and its
      passwords into the 4 Android signing secrets (§4.1). Once Play
      Console has accepted a signed AAB once, **never regenerate or
      replace this keystore** — every future update must be signed with
      the same key, and losing it means losing the ability to publish
      updates to this app entirely (back it up somewhere safe, outside
      the repo, today).
- [ ] Create the app listing in Play Console under `com.msixv.m6sudoku`
      (App details, store listing, content rating, data safety form,
      etc.) before the first automated `deploy-play` run — the Play
      Developer API can upload a build to an *existing* app but cannot
      create the listing itself.

**CI/CD:**
- [ ] Add the 4 Android signing secrets + `PLAY_SERVICE_ACCOUNT_JSON` (§4.1)
      once the above is confirmed.
- [ ] Create a Firebase project, then add the `FIREBASE_SERVICE_ACCOUNT`
      secret and `FIREBASE_PROJECT_ID` repo variable. `firebase.json` is
      already committed; `.firebaserc` isn't needed because the workflow
      passes the project ID explicitly. If you run `firebase init hosting`
      anyway, keep the committed `firebase.json` rather than letting it
      overwrite (its `public` must stay `build/web`).
- [ ] Add a `main` branch protection rule requiring the `CI` check + review
      before merge.
- [x] `web/manifest.json` populated (it was a 0-byte file, so the PWA had
      no name/icons/theme colour and wasn't installable); `index.html`'s
      placeholder title/description ("A new Flutter project.") replaced.

**Reliability:**
- [ ] Flesh out `android/app/proguard-rules.pro` (currently a single
      comment line) or verify explicitly that R8's default rules are
      sufficient — then smoke-test a real signed release build on-device
      before every rollout, not just a debug build.
- [ ] Set up staged rollout percentages in Play Console (§5) instead of
      100%-at-once releases.
- [ ] Decide on a save-data export/import feature to de-risk local-only
      storage — product decision, flagged here because it's the app's
      single biggest reliability gap and cheaper to solve than full cloud
      sync.

**Monitoring:**
- [ ] Add Firebase Crashlytics + Performance Monitoring (§7); wire
      `--split-debug-info` symbols (already produced by the updated
      `release.yml`) to Crashlytics symbol upload.
- [ ] Start checking Play Console Vitals on every rollout.

**Housekeeping:**
- [x] `release.yml` Flutter version aligned to `3.29.3` (was `3.24.0`,
      drifted from `ci.yml`/`BuildAPK.yml`) — done in this pass.
- [x] `ci.yml` now validates `flutter build web --release` on every PR —
      done in this pass.
- [x] Release builds now pass `--obfuscate --split-debug-info` — done in
      this pass (symbols uploaded as a 90-day CI artifact per release).
- [x] `deploy-web.yml` no longer passes `--web-renderer canvaskit` (the
      flag was removed in Flutter 3.29 and would have failed the first
      real deploy) or a hosting `target` nothing defined.
- [x] Keystore passwords are written to `key.properties` via `printf`
      from env vars, not an unquoted heredoc that would mangle `$`/`` ` ``.
