# Play Console answers — M6 3D Sudoku

Every answer needed to get `com.msixv.m6sudoku` from internal testing to a
production review, in the order Play Console's **Dashboard › Set up your
app** list presents them. Listing text and artwork are in
`PLAY_STORE_LISTING.md`.

## Status (updated 2026-09-26, after submission)

Developer account: **MSIXV** (organisation), signed in as tech@msixv.com at
`https://play.google.com/console/u/2`.

| Step | State |
|---|---|
| 0. Before you start | ✅ Production access confirmed, no verification banner |
| 1. App content | ✅ All 10 declarations done, answers match this sheet |
| 2. Store settings | ✅ Done: phone number removed, tags added |
| 3. Main store listing | ✅ Done: cube screenshot first, updated description |
| 4. Production release | ✅ All countries; version code 4 (1.0.0); `en-GB` notes |
| 5. Send for review | ✅ **Submitted 2026-09-26** |

Decisions made at submission:
- **Google Play Games on PC:** opted out.
- **Managed publishing:** left **off** on purpose, so the app goes live
  automatically as soon as Google approves it.

**Facts the answers rely on** (checked against the `1.0.0+4` release build,
2026-09-26):

- The release manifest requests **no** `INTERNET` and **no** `AD_ID`
  permission. Its only permission is Android's internal
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
- There are no analytics, crash reporting, ads, in-app purchase, sign-in,
  location or sharing SDKs. Games, stats and settings are stored only on the
  device (`shared_preferences`).
- The only outbound actions are Settings links (privacy policy, terms,
  support, Rate App) that open in the phone's own browser.

If a future update adds AdMob or Crashlytics, the **Ads**, **Advertising
ID** and **Data safety** answers below must change in that same update.

---

## 0. Before you start

- [x] **Dashboard / Test and release › Production:** it shows **Create new
      release**. No closed test or "apply for production access" needed.
- [x] No account-verification banner.
- [ ] `support@msixv.com` exists and someone reads it. Play shows it
      publicly and may email it during review.

## 1. App content (Policy › App content)

### Privacy policy
`https://msixv.com/games/m6-3d-sudoku/privacy-policy/`

Use the app-specific page, not the studio-wide one; the studio-wide wording
about ads and telemetry contradicts the Data safety answers below.

### App access
**All functionality in my app is available without any access
restrictions.** No login, no membership, no location or age gate.

### Ads
**No, my app does not contain ads.**

### Content rating
- Email: `support@msixv.com`
- Category: **Game** (or "All other app types" if Game isn't offered. It's a
  puzzle game either way.)
- Answer **No** to every question: violence, blood, fear/horror, sexual
  content, nudity, crude humour, profanity, drugs, alcohol, tobacco,
  gambling or simulated gambling, and so on.
- Miscellaneous:
  - Users can interact or exchange content: **No**
  - Shares the user's location with others: **No**
  - Allows purchase of digital goods: **No**
  - Unrestricted internet access or web browser: **No**. The Settings links
    open the phone's own browser; the app has no browser or network access.
  - Is a news or educational app: **No**
- Expected result: **IARC 3+ / PEGI 3 / ESRB Everyone / USK 0**. Click
  **Apply rating**.

### Target audience and content
- Age groups: **13–15, 16–17, 18 and over**. Leave every under-13 group
  unticked. Including under-13s puts the app under the Families policy,
  which restricts the ads planned for v1.1.
- "Could your store listing unintentionally appeal to children?" **No.**
  The listing is a plain puzzle game. If Play pushes back because of the
  mascot, answer honestly; worst case, the Families policy applies.

### News app
**No.**

### Data safety
- Does your app collect or share any of the required user data types?
  **No.**
- Play then skips the security and deletion questions. The summary should
  read **"No data collected · No data shared"**. Submit.
- Why this is accurate: data kept only on the device and never sent off it
  isn't "collected" under Play's definition, and the app has no network
  permission to send anything.

### Advertising ID
Does your app use advertising ID? **No.** (No `AD_ID` permission in the
release manifest.)

### Government apps
**No.**

### Financial features
**My app doesn't provide any financial features.**

### Health
**My app does not have any health features.**

Anything else listed under App content, such as photo/video permissions,
foreground services or exact alarms: **not applicable / No**. The app
declares none of those permissions.

## 2. Store settings (Grow users › Store presence › Store settings)

- App or game: **Game**
- Category: **Puzzle**
- Tags (up to 5, from Play's list): Sudoku, Logic, Brain games, and any of
  Puzzle, Single player, Offline that are offered
- Email: `support@msixv.com`
- Website: optional. Currently set to `https://msixv.com`.
- Phone: optional. **Removed** (2026-09-26); it would be shown publicly.
- External marketing: your choice. On is the default and is harmless.

## 3. Main store listing (Grow users › Store presence › Main store listing)

Paste and upload from `PLAY_STORE_LISTING.md`:

- **App name:** `M6 3D Sudoku: Cube Puzzles`
- **Short description:** from the doc (78 characters)
- **Full description:** from the doc (2,055 characters)
- **App icon:** `images/m6_sudoku_logo.png` (512×512, no alpha)
- **Feature graphic:** `images/m6-sudoku-feature-graphic.jpg` (1024×500)
- **Phone screenshots**, in this order:
  1. `images/Screenshot_3d_cube.jpg`
  2. `images/Screenshot_3d_cube-2.jpg` (status bar now removed)
  3. `images/Screenshot_game_play.jpg`
  4. `images/Screenshot_homescreen_dark_mode.jpg`
  5. `images/Screenshot_daily-challenge.jpg`
  6. **Your new statistics screenshot.** Take it on `1.0.0+4` after a few
     finished games, so the tiles show real numbers, not "Ga…" or "Cub…".
     Don't upload the old `Screenshot_statistics.jpg`.
- Tablet screenshots: optional. Skip for now.

**As submitted (2026-09-26):** 6 screenshots with a 3D cube one first,
then home (dark), classic game, daily challenge, select difficulty and
statistics (fixed tiles). The full description is the updated version from
`PLAY_STORE_LISTING.md`, and store tags are set.
- Video: optional. Skip.

## 4. Production release (Test and release › Production)

1. **Countries / regions** tab: add the countries to launch in. Choosing all
   is simplest; the app has no region-specific content.
2. **Create new release**, then **Add from library**, and pick version code
   **4 (1.0.0)**. That's the bundle already on internal testing. Don't
   rebuild or re-upload it; its debug symbols carry over.
3. Release notes. The tag must match the listing's default language,
   **English (United Kingdom)**:
   ```
   <en-GB>
   First release of M6 3D Sudoku: classic Sudoku with five technique-graded difficulties, plus 3D Cube Sudoku — six puzzles on a cube you can spin. Daily challenges, hints that teach, achievements and statistics. No account, no ads, works offline.
   </en-GB>
   ```
4. **Rollout:** if Play offers a rollout percentage, start at **20%**. Play
   may require a first production release to go to 100%; that's fine for a
   new app with no users yet.
5. **Next**, then check the warnings. "No deobfuscation file" is expected
   and harmless: the Dart code is obfuscated with Flutter's own
   `--split-debug-info`, not R8 mapping. Then **Save**.

## 5. Send for review (Publishing overview)

- **Before submitting, go to Test and release › Advanced settings › Form
  factors and opt out of Google Play Games on PC** (done 2026-09-26). PC review expects mouse and keyboard support and resizable windows,
  and this touch-first app hasn't been tested on PC. Opting in later is
  easy; a PC-related rejection would delay the whole first review.

- Optional but recommended: turn on **Managed publishing**. Once Google
  approves, the release waits for you to press **Publish**, instead of
  going live automatically at a random moment.
- Click **Send N changes for review**.
- The first review usually takes a few days to about a week. Watch the
  inbox of your developer account email, plus `support@msixv.com`, for
  policy questions.

## 6. After approval

- Publish (if managed publishing is on).
- Watch **Quality › Android vitals** for crashes and ANRs for a few days;
  if clean, raise the rollout toward 100%.
- The next upload must be version code **5** or higher (`1.0.0+5`).
