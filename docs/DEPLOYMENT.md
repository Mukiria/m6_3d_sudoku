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

**Two blocking findings surfaced while building this** — both need your
decision before the pipeline below can run for real; see the checklist in
§8 for the full list:

1. **`android/app/build.gradle.kts` declares `applicationId
   "com.msixv.m6sudoku"`**, but `README.md` / `RELEASE_NOTES.md` link the
   Play Store listing as `com.m6.sudoku`. If the app is actually published
   under `com.m6.sudoku`, an automated upload using the current
   `applicationId` will fail (or worse, silently create a second, wrong
   listing). Confirm which ID the live Play Console listing actually uses
   before enabling `deploy-play` in CI.
2. **Every release build to date has been debug-signed.** `build.gradle`
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
| `.github/workflows/ci.yml` | push/PR to `main` | format check, `flutter analyze`, `flutter test --coverage` (now uploaded as an artifact), **`flutter build web --release`** (new — validates the web target on every PR; previously only Android was built, so web-only regressions could land silently), build+upload debug-signed APK for manual QA sideloading |
| `.github/workflows/release.yml` | push tag `v*` | pub get → codegen → analyze → test → **real release signing from secrets** (new) → `--obfuscate --split-debug-info` (new) → build APK+AAB → GitHub Release → **Play Console internal-track upload** (new, gated on secrets, `status: draft` so a human still hits publish) |
| `.github/workflows/deploy-web.yml` (new) | push/PR to `main` | build web → Firebase Hosting **preview channel** on PRs, **live channel** on `main` |
| `.github/workflows/BuildAPK.yml` | manual (`workflow_dispatch`) | unchanged — ad hoc debug-signed APK for quick sideload testing, doesn't need signing secrets |

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
only — nothing leaves the device. For a "production-ready" app already on
the Play Store, this means you're currently blind to crash rate, ANR rate,
and error frequency in the wild except what users choose to report.

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
- [ ] Confirm the real Play Console `applicationId`: `com.msixv.m6sudoku`
      (current `build.gradle`) vs. `com.m6.sudoku` (README/RELEASE_NOTES
      link). Fix whichever side is wrong before touching Play API uploads.
- [ ] Verify `android/app/keystore/upload-keystore.jks` +
      `android/key.properties` on disk are the **actual** keystore Play
      Console already has on file for this app (not a newly generated
      one) — Play Store rejects AAB updates signed with a different
      upload key than it's already tracking.

**CI/CD:**
- [ ] Add the 4 Android signing secrets + `PLAY_SERVICE_ACCOUNT_JSON` (§4.1)
      once the above is confirmed.
- [ ] Create a Firebase project, run `firebase init hosting`, commit the
      resulting `firebase.json`/`.firebaserc` (currently absent from the
      repo entirely), add `FIREBASE_SERVICE_ACCOUNT`/`FIREBASE_PROJECT_ID`.
- [ ] Add a `main` branch protection rule requiring the `CI` check + review
      before merge.
- [ ] Fill in `web/manifest.json` — it's currently a 0-byte empty file, so
      the PWA has no name/icons/theme-color/start_url declared despite
      `flutter_native_splash` being configured for web. "Add to Home
      Screen" / installability won't work correctly until this has real
      content (`flutter pub run flutter_native_splash:create` and the
      launcher-icons config already reference a web icon — this file just
      needs the standard manifest fields populated to match).

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
