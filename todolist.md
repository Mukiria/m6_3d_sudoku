# Going live on Google Play — M6 3D Sudoku

Package `com.msixv.m6sudoku` · version `1.0.0+4` · **submitted for production
review 2026-09-26** · last updated 2026-09-26

`[x]` done · `[ ]` to do · ⚠️ needs checking

---

## 1. Accounts & keys

- [x] Google Play Console developer account (organisation — so **no**
      12-tester / 14-day closed-test requirement)
- [x] Organisation account ("MSIXV", signed in as tech@msixv.com at
      `play.google.com/console/u/2`) — no verification banner; Play says
      all its apps are registered for Android developer verification
      (checked 2026-09-26)
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
- [x] Fixed Evil taking minutes on "Generating puzzle" — generation is ~100×
      faster and capped at 2 s (`1.0.0+4`)
- [x] Difficulties graded by solving technique; new games come from a
      bundled, pre-graded puzzle bank and load instantly (`1.0.0+4`)
- [x] Fixed every other New Game replaying the previous puzzle (`1.0.0+4`)
- [x] Daily challenge is always genuinely Medium (`1.0.0+4`)
- [x] Version bumped to `1.0.0+4`, signed AAB built and checked (upload key,
      version code 4, puzzle banks bundled)

## 3. Build pipeline (GitHub)

- [x] CI: format check, analyze, tests, web + APK builds
- [x] Release workflow: signed APK/AAB on `v*` tags, or on demand from
      **Actions › Release › Run workflow**
- [x] Tag must match `pubspec.yaml` version; unsigned builds are never sent
      to Play
- [x] `1.0.0+4` work committed and pushed to `devops/cicd-deployment-setup`
- [x] Open a PR from `devops/cicd-deployment-setup` into `main`, let CI
      pass, merge (PR #1, merged 2026-09-26) (the "Run workflow" button only appears once it's on
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
- [x] Statistics screenshot retaken — the one in Play Console already shows
      the fixed, untruncated tiles
- [x] Removed the status bar from `Screenshot_3d_cube-2.jpg` (painted out,
      still 1080×1920)
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
- [x] Public support email: **support@msixv.com** (make sure the mailbox
      exists)
- [x] Full description mentions technique-graded difficulty (in
      `PLAY_STORE_LISTING.md` only — optional to paste into Play, which
      still has the earlier 1,953-character version)
- [x] Cube screenshot moved to the front in Play; updated full description
      (with the technique-grading line) pasted into Play; store tags added

## 5. Play Console setup

All checked in Play Console on 2026-09-26 (read-only review). Answers are in
`store_listing/PLAY_CONSOLE_ANSWERS.md`.

- [x] Create the app: "M6 3D Sudoku: Cube Puzzles", **Game**, **Free**
- [x] Production access: **Production** offers **Create new release** — no
      closed-test / "apply for production access" requirement
- [x] Default store listing (en-GB): name, short and full description,
      icon, feature graphic, 6 phone screenshots — "Ready to send for review"
- [x] Store settings: **Game › Puzzle**, support@msixv.com, website
      https://msixv.com, phone number
- [x] Phone number removed from the public store listing (email and
      website kept)
- [x] App content — all 10 declarations done, "Ready to send for review":
      privacy policy (app-specific URL), sign-in (no special access), ads
      (No), content rating, target audience (13–15, 16–17, 18+), data
      safety (no data collected or shared), advertising ID (No), government
      apps (No), financial features (none), health (none)
- [x] Opted out of **Google Play Games on PC** (Advanced settings › Form
      factors) — touch-first app, untested on PC; revisit later if wanted
- [x] Managed publishing deliberately left **off** — the app goes live
      automatically as soon as Google approves it

## 6. Internal testing

- [x] Testing › Internal testing › create a release (`1.0.0+3`)
- [x] Upload `app-release.aab` by hand (the first upload must be manual)
      — uploaded version codes 1, 3 and 4; the next build must be `1.0.0+5` or higher
- [x] Native debug symbols zip for `1.0.0+3` (engine symbols from Google's
      bucket + `build/symbols`, build IDs verified) — script it in
      `release.yml` for future builds
- [x] Accept **Play App Signing** when asked
- [x] Add testers (email list; the join link must be sent by hand — Play
      sends no email)
- [x] Install from the Play Store on your phone (the phone's Play Store
      errored; installing from play.google.com on desktop worked)
- [x] **Upload `1.0.0+4`**: Internal testing › Create new release › upload
      `build/app/outputs/bundle/release/app-release.aab`, then ⋮ › Upload
      native debug symbols ›
      `build/app/outputs/native-debug-symbols/native-debug-symbols-1.0.0+4.zip`
      (build IDs already verified) › Save and publish. Must be done by hand:
      both files are over the 10 MB browser-automation upload limit
- [ ] On `1.0.0+4`: Evil New Game loads instantly, consecutive New Games
      differ, 3D cube starts quickly
- [ ] Play through both modes
- [ ] Pre-launch report: none exists — Play only generates them for
      closed/open testing tracks, not internal. Not required for review

## 7. Go live

- [x] **Production › Countries/regions**: all countries and regions
- [x] **Production › Create new release** › Add from library › version
      code **4 (1.0.0)**, release notes (`en-GB`)
- [x] **Submitted for review 2026-09-26** (Publishing overview). First
      review usually takes a few days to about a week; with managed
      publishing off it goes live in all countries on approval
- [ ] Watch tech@msixv.com and support@msixv.com for Google's approval or
      policy questions; if rejected, check **Policy status** for the reason
- [ ] Once live: install from the public Play listing and check the store
      page (name, screenshots, description) looks right
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
