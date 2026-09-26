# Project Summary: M6 3D Sudoku (`m6_3d_sudoku`)

## 1. Project Purpose

This is **M6 3D Sudoku** (the launcher label since commit `9669c38`; older docs and the Dart package still say "M6 Sudoku"/`m6_sudoku`), a production-quality Flutter mobile/web game combining a classic single-grid Sudoku app with a novel **3D "Cube Sudoku" mode** — six independent 9×9 puzzles mapped to the faces of a rotatable cube, solved simultaneously. Per `README.md`/`CHANGELOG.md`/`RELEASE_NOTES.md`, it's positioned as a polished, "production-ready" consumer puzzle game distributed on Google Play and web (`m6-sudoku.web.app`), aimed at everyday puzzle players who want depth beyond a basic Sudoku clone: daily challenges with streaks, an achievement system, detailed statistics, a full hint/solving-technique system, and now an added 3D variant as a distinguishing feature. The Android application ID is `com.msixv.m6sudoku` (see §8) and the Dart package name is `m6_sudoku`; "M6" is the developer/studio brand.

## 2. Tech Stack

- **Language/Framework:** Dart / Flutter (SDK ≥3.7.0, Flutter ≥3.24.0; CI pins Flutter 3.29.3)
- **State management:** `flutter_riverpod` + `riverpod_generator`/`riverpod_annotation` (code-generated providers, `.g.dart` files)
- **Routing:** `go_router` (declarative, with custom transitions)
- **Data modeling:** `freezed`/`freezed_annotation` (immutable unions/entities) + `json_serializable`/`json_annotation` for persistence; `equatable` for value equality; `dartz` for functional `Either<Failure, T>` error handling
- **UI/UX:** Material 3, the Inter font (bundled as pubspec font assets in six weights — `google_fonts` was removed because release builds have no INTERNET permission, so its runtime download silently failed and the app fell back to Roboto), `flutter_animate`, `flutter_staggered_animations`, `confetti`, `fl_chart` (statistics charts), `flutter_svg`, `vector_math` (used for cube 3D geometry). Layered on top is an in-house "Liquid Glass" material system (`lib/shared/widgets/glass/`, `lib/core/theme/glass_tokens.dart`, `lib/core/motion/springs.dart`) approximating Apple's translucent-material design language via `BackdropFilter` blur + tint + a specular-gradient overlay + a custom continuous-corner `SquircleBorder`, with spring-physics motion presets — no new dependency, built from Flutter's own painting/animation APIs.
- **Persistence:** `shared_preferences` (all storage is local key-value JSON, no server/database)
- **Other:** `audioplayers` (sound), `uuid`, `logger`, `intl` (i18n scaffolding via `flutter_intl`), `url_launcher` (Settings' Privacy Policy / Terms / Support / Rate App links, opened in the external browser)
- **Dev tooling:** `build_runner`, `flutter_lints` + `custom_lint`/`riverpod_lint`, `mockito`, `flutter_launcher_icons`, `flutter_native_splash`
- **Platforms configured:** Android and Web only (per pubspec/CI). Android pins `compileSdk`/`targetSdk` to 36 (Android 16) rather than Flutter 3.29's default of 35, to meet Google Play's target-API requirement for new apps; `minSdk` follows Flutter's default. The Android release build requests **no INTERNET permission** (only the debug/profile manifests add it), which the app's privacy policy relies on; iOS/macOS/Windows/Linux are listed as "Planned" in `CHANGELOG.md`, though standard `ios/`, `macos/`, `windows/`, `linux/` platform folders do exist in the repo tree (likely default Flutter scaffolding, not actively maintained/released).

## 3. Architecture & Structure

Clean Architecture + feature-first modules, consistently applied:

```
lib/
├── core/            # cross-cutting: constants, routing (GoRouter), theme
│                       (incl. glass_tokens.dart — the Liquid Glass material
│                       extension), motion (spring-curve presets),
│                       storage_service (SharedPreferences wrapper),
│                       json_store (shared JSON encode/decode helper),
│                       errors (Failure/Exception types), audio, utils
├── features/
│   ├── home/          presentation only (landing screen)
│   ├── sudoku/         the classic single-grid game — the largest feature:
│   │     engine/        pure Dart game logic (no Flutter deps): Board/Cell
│   │                     models, backtracking solver with MRV heuristic,
│   │                     puzzle generator (isolate-based via `compute`),
│   │                     unique-solution validator, candidates/bitmask ops,
│   │                     grader/ (TechniqueGrader — grades a puzzle by the
│   │                     hardest human technique it needs), bank/
│   │                     (PuzzleBank — parses the bundled puzzle banks and
│   │                     draws disguised puzzles from them)
│   │     domain/        entities (Puzzle, GameState, Achievement,
│   │                     DailyChallenge, DailyStreak) + repository
│   │                     interfaces + usecases
│   │     data/          repository impls + local datasources (each wraps
│   │                     SharedPreferences via JsonStore)
│   │     presentation/  Riverpod providers/notifiers, screens, widgets
│   ├── cube_sudoku/    the 3D mode, mirroring the same layered structure
│   │                    (domain/data/presentation) — CubeFace enum,
│   │                    CubeGameState (freezed), cube geometry widget,
│   │                    its own achievement usecases and local datasource
│   ├── settings/       theme/sound/haptics/etc., same layered pattern
│   └── statistics/     win/loss/time/streak stats, same layered pattern
└── shared/widgets/    reusable buttons/cards, app_header_bar.dart (the
                         shared AppHeaderBar — every screen's AppBar now
                         goes through this instead of a raw AppBar, so
                         the header's brand-orange gradient stays defined
                         in exactly one place), plus glass/ (GlassSurface,
                         SquircleBorder, GlassButtonSurface — the shared
                         Liquid Glass material primitives) and
                         pausable_blur.dart (the animated shrink+blur used
                         to hide a puzzle behind its pause sheet)
```

Each feature follows **domain → data → presentation** with repository interfaces decoupling storage from business logic, and `Either<Failure, T>` (via `dartz`) as the standard error-handling return type throughout data/domain layers. The Sudoku *engine* (solver/generator/validator/grader/bank) is deliberately kept as plain, dependency-free Dart under `engine/`, separate from the domain/data/presentation Clean Architecture layers — notable because it's built to run inside a `compute()` isolate for puzzle generation (keeps UI responsive on higher difficulties). The 3D cube feature was added later as a **parallel, independent feature module** rather than a modification of the existing game (confirmed by both code comments and git log — see commits `d6706f6`, `60af5ed`).

## 4. Entry Points

- **App entry:** `lib/main.dart` — initializes `SharedPreferences`, builds a Riverpod `ProviderContainer`, eagerly restores any in-progress classic game *and* any in-progress cube game before first frame (so "Continue Game" is accurate immediately), then runs `M6SudokuApp` (a `MaterialApp.router` wired to `goRouterProvider`). `M6SudokuApp` also observes `WidgetsBindingObserver` and flushes both games' state to storage on `paused`/`hidden`/`detached` lifecycle transitions, so "Continue" reflects the exact moment a player backgrounds or closes the app, not just their last in-game move.
- **Routing table:** `lib/core/routing/app_router.dart` defines all routes (`/`, `/game`, `/cube-game`, `/daily`, `/achievements`, `/statistics`, `/settings`, etc.) with custom slide/fade transitions per route.
- **Build commands** (from `README.md`, verified against CI workflows): `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` → `flutter run` / `flutter build apk|ios|web --release`.

## 5. Data & Storage

No backend/database — everything is **local-only**, persisted as JSON strings inside `SharedPreferences`, accessed through:
- `StorageService`/`StorageServiceImpl` (`lib/core/services/storage_service.dart`) — thin typed wrapper over `SharedPreferences`.
- `JsonStore` (`lib/core/services/json_store.dart`) — a shared helper that factors out the "read key → jsonDecode → build entity, or default" and "jsonEncode → write key" boilerplate that each feature's `*_local_datasource.dart` uses, returning `Either<Failure, T>`.

New regular games and every cube face come from a **bundled puzzle bank**, not from on-device generation: `assets/puzzles/<difficulty>.txt` (300 pre-graded puzzles each, ~264 KB total, one line per puzzle: puzzle, solution, hardest technique). `PuzzleBankSource` (`lib/features/sudoku/data/datasources/puzzle_bank_source.dart`, one shared instance via `puzzleBankSourceProvider`) loads each file once through `rootBundle` and draws a random entry with a random validity-preserving transform (digit relabelling, row/column swaps within bands, band swaps, transposition), so repeats aren't recognisable and the grade is unchanged. Live generation is the fallback if a bank can't be read, and is always used when a seeded generator is injected (tests) and for the daily challenge.

Each feature's local datasource owns its own storage keys (centralized in `AppConstants`, e.g. `keyCurrentGame`, `keyStatistics`, `keyCompletedPuzzles`) and its own read-modify-write policy. Data flow is straightforward: UI → Riverpod notifier/usecase → repository → local datasource → `StorageService`/`SharedPreferences`, and back. There is no cloud sync (explicitly listed as a "Planned" feature, not implemented).

## 6. External Integrations

None at the app-code level. No REST/GraphQL API clients, no Firebase/analytics SDKs, no ads SDKs, and no `.env` files or credential/API-key references turned up in a repo-wide grep (the only "secret" hits are the game's own "secret achievement" flag, unrelated to credentials). `url_launcher` only opens Settings' links in the external browser: the app-specific privacy policy (`https://msixv.com/games/m6-3d-sudoku/privacy-policy/`), terms, support, and the app's own Play listing (Rate App). There is now a deployment-side integration point: `.github/workflows/deploy-web.yml` targets Firebase Hosting (gated on `FIREBASE_SERVICE_ACCOUNT`/`FIREBASE_PROJECT_ID` secrets that aren't configured yet, so it currently no-ops with a warning rather than deploying; `firebase.json` holds the hosting rewrites/cache headers, and no `.firebaserc` is needed since the workflow passes the project ID). That's a hosting/CI concern, not an in-app SDK — no telemetry leaves the device at runtime. The only other "external service" touchpoints remain the Play Store (manual uploads today; see §7/§8) and GitHub Actions for CI/CD.

## 7. Build/Run/Test Instructions

From `README.md`, cross-checked against `.github/workflows/`:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates .freezed.dart / .g.dart
flutter run                                                 # run locally
flutter analyze --no-fatal-infos --no-fatal-warnings        # lint (as run in CI)
dart format --output=none --set-exit-if-changed .           # format check (CI)
flutter test --coverage                                     # unit/widget tests
flutter build apk --release --split-per-abi                 # Android release
flutter build web --release                                  # Web release
dart run flutter_launcher_icons                              # regenerate icons
dart run flutter_native_splash:create                        # regenerate splash
dart run tool/build_puzzle_bank.dart [perDifficulty=300]     # rebuild assets/puzzles/ (~12 min, deterministic)
```

CI (`ci.yml`, runs on every push/PR to main/master) pins Flutter 3.29.3, generates code, checks formatting of tracked files (a real gate — it no longer auto-formats first), analyzes, tests with coverage (now uploaded as a build artifact), builds and validates a release **web** bundle (added so a web-only regression can't land silently — previously only Android was built in CI), and builds a split-per-ABI release APK as an artifact. A separate manual `BuildAPK.yml` does the same (minus analyze/web-build) on `workflow_dispatch`. `release.yml` (Flutter version now aligned to 3.29.3, was 3.24.0) builds a **real, keystore-signed** APK+AAB with `--obfuscate --split-debug-info` on `v*` tags, publishes a GitHub Release, and — only once `ANDROID_KEYSTORE_BASE64`/`PLAY_SERVICE_ACCOUNT_JSON` etc. secrets are added (not yet configured) — uploads the AAB to the Play Console internal track as a draft. It can also be run by hand from the Actions tab (`workflow_dispatch`) on any branch: that builds the same signed APK/AAB and attaches them to the run as downloadable artifacts, skipping the tag/pubspec version check, GitHub Release, and Play upload. Until those secrets exist, every step that needs them skips itself with a `::warning::` instead of failing or falling back silently. There's also a new `deploy-web.yml` (Firebase Hosting: PR preview channels, live deploy on `main`), also inert until Firebase secrets are added. Full rationale, required secrets, and a production checklist live in `docs/DEPLOYMENT.md`; `Dockerfile.ci` provides a pinned Flutter+Android build image for local/self-hosted-runner parity, and `infra/future-backend/` sketches a Cloud Run/Kubernetes reference design for *if* the "Planned" cloud-sync feature is ever built (nothing there is wired into any pipeline today).

**Test suite:** 30 test files under `test/`, covering engine logic (solver/generator/validator/technique grader/puzzle bank — including a check of every bundled bank puzzle's format, grade, uniqueness and solution), datasources, repositories, entities, Riverpod providers/notifiers (including cube-specific completion and save/load flows), and a set of widget tests (including pause/blur behavior and the cube's auto-advance-on-face-completion flow). No integration/e2e (`integration_test/`) directory was found. One known, pre-existing environmental flake: the isolate-based puzzle-generation test (`newGame initializes with correct puzzle for difficulty`) occasionally times out under load — confirmed non-reproducible on repeated clean runs, not a code defect.

## 8. Notable Observations

- **Liquid Glass design language, applied app-wide:** shared surfaces (buttons, cards, the regular/cube game's top docks and number pads, pause sheets, dialogs) render through the `GlassSurface` primitive described above, in both light and dark theme. Caller-supplied colors — semantic stat/achievement tiles, a selected difficulty card — deliberately stay solid rather than glass, since glass is meant to change container material, not override intentional semantic color. The one caveat worth knowing: this is a `BackdropFilter`-based approximation, not real-time GPU refraction (Flutter has no equivalent), and it's been retrofitted onto plain `Container`/`Card` widgets one at a time, so a handful of screens (e.g. some Achievement-screen tiles) are intentionally left solid rather than converted.
- **Every screen header shares one definition:** `AppHeaderBar` (`lib/shared/widgets/app_header_bar.dart`) wraps a plain `AppBar` with a brand-orange gradient (`AppThemeExtension.headerGradient` — the same light-sheen-into-orange formula `GlassSurface` gives an accent-tinted button), white text/icons, and a fixed height, all pulled from one `AppBarTheme` in `app_theme.dart` that's identical between light and dark (headers deliberately don't follow brightness). Statistics' header used to be a bespoke `GlassSurface`-based `SliverPersistentHeader` that shrank its title font on scroll — now a plain `SliverAppBar` painted with the same gradient, so it's pixel-identical to every other screen instead of a one-off. Primary orange CTA buttons (Home, pause-sheet "Resume", "Start 3D Sudoku", etc.) use a matching `glassTint` rather than an opaque `backgroundColor` — a few screens had drifted to the latter (a flat-fill bug, not a design choice) and were brought back in line.
- **`achievement_usecases.dart`'s difficulty-tracking TODO is resolved:** "Master of All" (win on every difficulty) now credits via `EvaluateAchievementDeltasUseCase.distinctProgressCredits` and `IncrementAchievementProgressBatchUseCase`'s `distinctProgress` param, rather than a plain per-win counter that couldn't distinguish "5 different difficulties" from "the same difficulty 5 times."
- **~~CI Flutter version drift~~ (fixed):** `release.yml` pinned Flutter `3.24.0` while `ci.yml`/`BuildAPK.yml` pinned `3.29.3` — now aligned to `3.29.3` everywhere.
- **`applicationId` vs. Play Store listing mismatch — resolved:** the app has never actually been published (confirmed with the owner 2026-09-17), so there was no live listing to conflict with. Standardized on `com.msixv.m6sudoku` (matches `android/app/build.gradle.kts`, which is what's actually built/signed) — `README.md` and `RELEASE_NOTES.md`'s Play Store links, `docs/DEPLOYMENT.md`, and the `release.yml` upload-step comment were updated to match. The old `com.m6.sudoku` ID seen in earlier docs is stale; `com.msixv.m6sudoku` is authoritative. The Play Console app now exists (created 2026-09-25 as "M6 3D Sudoku: Cube Puzzles", Game, Free), so automated uploads are unblocked once `PLAY_SERVICE_ACCOUNT_JSON` is added. `AppConstants.bundleId` had also still said `com.m6.sudoku`, which made Settings › Rate App open a non-existent Play page — fixed in `1.0.0+3`.
- **Every release build was debug-signed until this pass:** `build.gradle`'s release `signingConfig` falls back to `debug` whenever `android/key.properties` is absent, which was always true in CI (no keystore secret was ever configured there) — meaning past GitHub Release APK/AAB artifacts were not genuinely Play-Store-signed. `release.yml` now decodes a real keystore from GitHub secrets when present (not yet configured), falling back to the old debug-signed behavior with an explicit warning otherwise. Full details in `docs/DEPLOYMENT.md`.
- **Code comments show deliberate engineering discipline**, not just boilerplate: e.g. `main.dart` explains *why* both classic and cube games are eagerly restored before first frame, `json_store.dart` explains why it's deliberately kept thin rather than a general ORM, and `puzzle_generator.dart` documents why generation runs in a `compute()` isolate. This suggests a codebase maintained with care rather than one accumulating unreviewed AI-generated cruft.
- **iOS/macOS/Windows/Linux platform folders exist** in the repo (standard Flutter scaffolding) despite `pubspec.yaml`/CI only really targeting Android+Web and the changelog listing those as future work — likely dormant scaffolding rather than actively maintained targets; worth flagging as ambiguous rather than assuming intent.
- **No `.env`/secrets/API keys found** anywhere in `lib/` — the app is entirely offline/local-storage-based, which is consistent with its scope (no backend needed) but means anything like cloud sync or leaderboards would be a substantial new addition, not a config change.
- **Two parallel game engines by design, not duplication**: `sudoku` and `cube_sudoku` intentionally each have their own domain/data/presentation stack (confirmed via router comment: "a new mode alongside the regular game, not a replacement for it"), so overlapping-looking code (e.g., two achievement usecases, two local datasources) is an intentional feature boundary rather than an accidental copy-paste.
- **Release status (as of 2026-09-26):** `1.0.0+3` is live on the Play Console **internal testing** track and installed on the owner's phone; production isn't submitted yet. `1.0.0+4` (the generation/grading work below) is committed, pushed and built as a signed AAB with its native-debug-symbols zip in `build/app/outputs/`, but still has to be uploaded to internal testing by hand — both files exceed the browser-automation upload limit, and CI upload needs the not-yet-configured `PLAY_SERVICE_ACCOUNT_JSON`. Version codes 1 and 3 have been uploaded; once +4 is up, the next build must be `1.0.0+5` or higher. The Play account is an organisation account, so the 12-tester / 14-day closed-test rule shouldn't apply — production can be submitted directly once Play Console setup is complete (still to confirm in Play Console). Store listing copy, the app-specific privacy policy draft and store artwork live in `store_listing/` (artwork in `store_listing/images/`, deliberately outside `assets/` so it isn't bundled into the app — only the logotype, mascot and launcher-icon source remain in `assets/images/`). `todolist.md` is the running go-live checklist.
- **Native debug symbols need a manual step:** Flutter's engine `libflutter.so` ships pre-stripped and `--split-debug-info` strips `libapp.so`, so AGP's `ndk.debugSymbolLevel` produces nothing. The `1.0.0+3` symbols zip was assembled by hand from Google's published engine symbols (`storage.googleapis.com/flutter_infra_release/flutter/<engine hash>/android-*-release/symbols.zip`) plus `build/symbols/app.android-*.symbols`, stripped to symbol tables with the NDK's `llvm-objcopy --strip-debug`, after checking every ELF build ID against the uploaded AAB. Not yet automated in `release.yml`.
- **Statistics screen layout fix:** the overview tiles put the icon beside the text, which on a ~360dp phone left ~36dp for label and value, so everything was ellipsized ("Ga…", "Cub…"). Tiles now stack icon above text with a `FittedBox`-scaled value, and the Difficulty Performance rows use a `Wrap` so large numbers or larger system font sizes can't overflow.
- **Puzzle generation (fixed in `1.0.0+4`):** Evil could sit on "Generating puzzle" for minutes (67–105 s on a Mac, worse on a phone) — its 20-clue target was almost never reachable, so all 200 removal attempts ran, each re-checking uniqueness with an unordered search over allocation-heavy `Board`/`Cell` objects. The uniqueness check now only asks whether the removed cell could hold a different digit (valid because the grid is unique before each removal), using an MRV search over plain bitmasks (`_BitGrid` in `puzzle_generator.dart`): same answers, so seeded output is byte-identical, ~100× faster. Unseeded generation also stops after `PuzzleGenerator.unseededTimeBudget` (2 s); seeded generation ignores the budget so the daily stays device-independent. Evil's clue target is 21.
- **Difficulty is graded by technique, not clue count:** clue count barely predicted difficulty (67/150 old "Evil" puzzles solved with singles alone; 16/150 "Medium" ones needed chains). `TechniqueGrader` (`engine/grader/technique_grader.dart`) solves like a person — naked/hidden singles, locked candidates, naked/hidden pairs and triples, X-wing, XY-wing, swordfish, XYZ-wing, W-wing, simple colouring, unique rectangle (type 1), jellyfish, else `beyond` — and `SolvingTechnique.fits` maps that to tiers: Easy/Medium = singles (36 vs 30 clues), Hard = locked candidates, Expert = pairs/triples/X-wing, Evil = XY-wing and up. At most a third of the Evil bank is `beyond` (needs chains or trial and error); the rest is hard but learnable. Finding such puzzles takes minutes, which is why they're built offline by `tool/build_puzzle_bank.dart` (fixed seeds; refuses any puzzle whose logical solve contradicts its solution) rather than on the phone.
- **Daily challenge is always genuinely Medium:** `generateDailyPuzzle` (top-level, in `daily_challenge_local_datasource.dart`) grades the date-seeded puzzle and steps through a fixed seed sequence (`date + i × 100000000`) until one fits Medium. Deterministic across devices; days whose original puzzle already fit keep it. 58 of 2026's 365 dailies were previously off-level (30 needed chains).
- **Repeating-puzzle bug (fixed in `1.0.0+4`):** `PuzzleLocalDataSource` used to cache each puzzle it generated and serve from that cache first, so every other New Game on a difficulty replayed the previous puzzle. The cache is gone; the leftover `puzzle_cache_<difficulty>` key is deleted on the next New Game.
