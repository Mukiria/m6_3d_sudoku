# Going live on Google Play — M6 3D Sudoku

Package `com.msixv.m6sudoku` · version `1.0.0+3` (live on internal testing) · last updated 2026-09-26

`[x]` done · `[ ]` to do · ⚠️ needs checking

---

## 1. Accounts & keys

- [x] Google Play Console developer account (organisation — so **no**
      12-tester / 14-day closed-test requirement)
- [ ] ⚠️ Confirm the organisation account is fully verified (D-U-N-S,
      identity, contact details) — Play Console shows a banner if not
- [x] Upload keystore exists (`android/app/keystore/upload-keystore.jks`,
      passwords in `android/key.properties`, both untracked)
- [ ] **Back up the keystore + passwords outside the repo** (password
      manager). Losing it means you can never update the app.

## 2. App build

- [x] Launcher name set to **M6 3D Sudoku**
- [x] Targets Android 16 (API 36)
- [x] Application ID standardised on `com.msixv.m6sudoku`
- [x] Release builds are code-shrunk and obfuscated
- [x] Signed release AAB builds successfully
      (`build/app/outputs/bundle/release/app-release.aab`, signed with the
      upload key)
- [x] Install the release build on a real phone (via internal testing,
      2026-09-26) — playing well so far
- [ ] Finish a classic game and a full 3D cube to the end on that build

## 3. Build pipeline (GitHub)

- [x] CI: format check, analyze, tests, web + APK builds
- [x] Release workflow: signed APK/AAB on `v*` tags, or on demand from
      **Actions › Release › Run workflow**
- [x] Tag must match `pubspec.yaml` version; unsigned builds are never sent
      to Play
- [ ] Open a PR from `devops/cicd-deployment-setup` into `main`, let CI
      pass, merge (the "Run workflow" button only appears once it's on
      `main`)
- [ ] Add repo secrets: `ANDROID_KEYSTORE_BASE64`,
      `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`,
      `ANDROID_KEY_ALIAS` (see `docs/DEPLOYMENT.md` §4.1)
- [ ] Do one manual run and confirm it produces a signed AAB

## 4. Store listing

- [x] App name, short and full description drafted
      (`store_listing/PLAY_STORE_LISTING.md`)
- [x] Hi-res icon (512×512)
- [x] Phone screenshots — new set of 6, cube first (order and paths in
      `store_listing/PLAY_STORE_LISTING.md`)
- [x] 3D cube screenshots added and placed first
- [x] Fixed the truncated statistics tiles ("Ga…", "Cub…", "1…") seen in
      the statistics screenshot
- [ ] **Retake the statistics screenshot** on a build with that fix
- [ ] Crop the status bar off `Screenshot_3d_cube-2.jpg` (or retake with
      notifications cleared)
- [x] Feature graphic redone with the "M6 3D Sudoku" logotype and cube
      (`store_listing/images/`, 2026-09-26)
- [x] `https://msixv.com/games/privacy-policy` is live (checked 2026-09-25)
- [x] App-specific policy live at
      `https://msixv.com/games/m6-3d-sudoku/privacy-policy/` (checked
      2026-09-25) — use this URL in Play Console, not the studio-wide one
- [x] App's Settings › Privacy Policy link points at it (from `1.0.0+3`)
- [x] `https://msixv.com/games/terms-of-service` and `/support` are live
      (HTTP 200, 2026-09-25) — content not reviewed
- [x] Fixed Settings › Rate App linking to the old `com.m6.sudoku` ID
      (from `1.0.0+3`)
- [ ] Choose a public support email address

## 5. Play Console setup

- [x] Create the app: "M6 3D Sudoku: Cube Puzzles", **Game**, **Free**
- [ ] Main store listing: paste text, upload icon, feature graphic,
      screenshots
- [ ] Category: **Game › Puzzle**; contact email; privacy policy URL
      `https://msixv.com/games/m6-3d-sudoku/privacy-policy/`
- [ ] App access: all functionality available without login
- [ ] Ads: **No** (change to Yes in the update that adds AdMob)
- [ ] Content rating questionnaire (expect Everyone / PEGI 3)
- [ ] Target audience: **13+** (avoids the Families policy, which would
      restrict ads later)
- [ ] Data safety: no data collected, no data shared
- [ ] Advertising ID declaration: **No**
- [ ] Government apps / financial features / health: No

## 6. Internal testing

- [x] Testing › Internal testing › create a release (`1.0.0+3`)
- [x] Upload `app-release.aab` by hand (the first upload must be manual)
      — uploaded version codes 1 and 3; the next build must be `1.0.0+4` or higher
- [x] Native debug symbols zip for `1.0.0+3` (engine symbols from Google's
      bucket + `build/symbols`, build IDs verified) — script it in
      `release.yml` for future builds
- [x] Accept **Play App Signing** when asked
- [x] Add testers (email list; the join link must be sent by hand — Play
      sends no email)
- [x] Install from the Play Store on your phone (the phone's Play Store
      errored; installing from play.google.com on desktop worked)
- [ ] Play through both modes
- [ ] Review the pre-launch report for crashes

## 7. Go live

- [ ] Promote the tested build to **Production**
- [ ] Use a **staged rollout** — start at 10–20%
- [ ] Submit for review (first review: a few days to about a week)
- [ ] Watch **Android vitals** (crash and ANR rates); ramp to 100% if clean

---

## After launch

- [ ] Play service account → add `PLAY_SERVICE_ACCOUNT_JSON` secret, so
      tagging `vX.Y.Z+N` uploads straight to internal testing
- [ ] Add a `main` branch protection rule (CI must pass + review)
- [ ] **v1.1 — ads** (once AdMob is approved): `google_mobile_ads`, consent
      form for EEA/UK users, `app-ads.txt`, then update privacy policy,
      data safety, "Contains ads" and advertising ID declarations
- [ ] Crashlytics (pairs naturally with the ads update — same Firebase
      project, same data safety change)
