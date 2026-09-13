# Project Summary: M6 Sudoku (`m6_3d_sudoku`)

## 1. Project Purpose

This is **M6 Sudoku**, a production-quality Flutter mobile/web game combining a classic single-grid Sudoku app with a novel **3D "Cube Sudoku" mode** — six independent 9×9 puzzles mapped to the faces of a rotatable cube, solved simultaneously. Per `README.md`/`CHANGELOG.md`/`RELEASE_NOTES.md`, it's positioned as a polished, "production-ready" consumer puzzle game distributed on Google Play and web (`m6-sudoku.web.app`), aimed at everyday puzzle players who want depth beyond a basic Sudoku clone: daily challenges with streaks, an achievement system, detailed statistics, a full hint/solving-technique system, and now an added 3D variant as a distinguishing feature. The bundle ID `com.m6.sudoku` and package name `m6_sudoku` suggest "M6" is the developer/studio brand.

## 2. Tech Stack

- **Language/Framework:** Dart / Flutter (SDK ≥3.7.0, Flutter ≥3.24.0; CI pins Flutter 3.29.3)
- **State management:** `flutter_riverpod` + `riverpod_generator`/`riverpod_annotation` (code-generated providers, `.g.dart` files)
- **Routing:** `go_router` (declarative, with custom transitions)
- **Data modeling:** `freezed`/`freezed_annotation` (immutable unions/entities) + `json_serializable`/`json_annotation` for persistence; `equatable` for value equality; `dartz` for functional `Either<Failure, T>` error handling
- **UI/UX:** Material 3, `google_fonts`, `flutter_animate`, `flutter_staggered_animations`, `confetti`, `fl_chart` (statistics charts), `flutter_svg`, `vector_math` (used for cube 3D geometry). Layered on top is an in-house "Liquid Glass" material system (`lib/shared/widgets/glass/`, `lib/core/theme/glass_tokens.dart`, `lib/core/motion/springs.dart`) approximating Apple's translucent-material design language via `BackdropFilter` blur + tint + a specular-gradient overlay + a custom continuous-corner `SquircleBorder`, with spring-physics motion presets — no new dependency, built from Flutter's own painting/animation APIs.
- **Persistence:** `shared_preferences` (all storage is local key-value JSON, no server/database)
- **Other:** `audioplayers` (sound), `uuid`, `logger`, `intl` (i18n scaffolding via `flutter_intl`), `url_launcher`
- **Dev tooling:** `build_runner`, `flutter_lints` + `custom_lint`/`riverpod_lint`, `mockito`, `flutter_launcher_icons`, `flutter_native_splash`
- **Platforms configured:** Android and Web only (per pubspec/CI); iOS/macOS/Windows/Linux are listed as "Planned" in `CHANGELOG.md`, though standard `ios/`, `macos/`, `windows/`, `linux/` platform folders do exist in the repo tree (likely default Flutter scaffolding, not actively maintained/released).

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
│   │                     unique-solution validator, candidates/bitmask ops
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
└── shared/widgets/    reusable buttons/cards, plus glass/ (GlassSurface,
                         SquircleBorder, GlassButtonSurface — the shared
                         Liquid Glass material primitives) and
                         pausable_blur.dart (the animated shrink+blur used
                         to hide a puzzle behind its pause sheet)
```

Each feature follows **domain → data → presentation** with repository interfaces decoupling storage from business logic, and `Either<Failure, T>` (via `dartz`) as the standard error-handling return type throughout data/domain layers. The Sudoku *engine* (solver/generator/validator) is deliberately kept as plain, dependency-free Dart under `engine/`, separate from the domain/data/presentation Clean Architecture layers — notable because it's built to run inside a `compute()` isolate for puzzle generation (keeps UI responsive on higher difficulties). The 3D cube feature was added later as a **parallel, independent feature module** rather than a modification of the existing game (confirmed by both code comments and git log — see commits `d6706f6`, `60af5ed`).

## 4. Entry Points

- **App entry:** `lib/main.dart` — initializes `SharedPreferences`, builds a Riverpod `ProviderContainer`, eagerly restores any in-progress classic game *and* any in-progress cube game before first frame (so "Continue Game" is accurate immediately), then runs `M6SudokuApp` (a `MaterialApp.router` wired to `goRouterProvider`). `M6SudokuApp` also observes `WidgetsBindingObserver` and flushes both games' state to storage on `paused`/`hidden`/`detached` lifecycle transitions, so "Continue" reflects the exact moment a player backgrounds or closes the app, not just their last in-game move.
- **Routing table:** `lib/core/routing/app_router.dart` defines all routes (`/`, `/game`, `/cube-game`, `/daily`, `/achievements`, `/statistics`, `/settings`, etc.) with custom slide/fade transitions per route.
- **Build commands** (from `README.md`, verified against CI workflows): `flutter pub get` → `dart run build_runner build --delete-conflicting-outputs` → `flutter run` / `flutter build apk|ios|web --release`.

## 5. Data & Storage

No backend/database — everything is **local-only**, persisted as JSON strings inside `SharedPreferences`, accessed through:
- `StorageService`/`StorageServiceImpl` (`lib/core/services/storage_service.dart`) — thin typed wrapper over `SharedPreferences`.
- `JsonStore` (`lib/core/services/json_store.dart`) — a shared helper that factors out the "read key → jsonDecode → build entity, or default" and "jsonEncode → write key" boilerplate that each feature's `*_local_datasource.dart` uses, returning `Either<Failure, T>`.

Each feature's local datasource owns its own storage keys (centralized in `AppConstants`, e.g. `keyCurrentGame`, `keyStatistics`, `keyCompletedPuzzles`) and its own read-modify-write policy. Data flow is straightforward: UI → Riverpod notifier/usecase → repository → local datasource → `StorageService`/`SharedPreferences`, and back. There is no cloud sync (explicitly listed as a "Planned" feature, not implemented).

## 6. External Integrations

None found. No REST/GraphQL API clients, no Firebase/analytics SDKs, no ads SDKs, and no `.env` files or credential/API-key references turned up in a repo-wide grep (the only "secret" hits are the game's own "secret achievement" flag, unrelated to credentials). `url_launcher` is present as a dependency but not confirmed wired to any specific external URL in the files reviewed. The only "external service" touchpoints are the Play Store and web deployment links mentioned in the README, and GitHub Actions itself for CI/CD.

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
```

CI (`ci.yml`, runs on every push/PR to main/master) pins Flutter 3.29.3, generates code, applies `dart fix --apply`, formats, analyzes, tests with coverage, and builds a split-per-ABI release APK as an artifact. A separate manual `BuildAPK.yml` does the same on `workflow_dispatch`. `release.yml` builds APK+AAB and publishes a GitHub Release on `v*` tags (uses an older pinned Flutter 3.24.0 — a minor inconsistency, see below).

**Test suite:** 26 test files under `test/`, covering engine logic (solver/generator/validator), datasources, repositories, entities, Riverpod providers/notifiers (including cube-specific completion and save/load flows), and a set of widget tests (including pause/blur behavior and the cube's auto-advance-on-face-completion flow). No integration/e2e (`integration_test/`) directory was found. One known, pre-existing environmental flake: the isolate-based puzzle-generation test (`newGame initializes with correct puzzle for difficulty`) occasionally times out under load — confirmed non-reproducible on repeated clean runs, not a code defect.

## 8. Notable Observations

- **Liquid Glass design language, applied app-wide:** shared surfaces (buttons, cards, the regular/cube game's top docks and number pads, pause sheets, dialogs, Statistics' scroll-adaptive header) render through the `GlassSurface` primitive described above, in both light and dark theme. Caller-supplied colors — brand-orange CTAs' accent tint, semantic stat/achievement tiles, a selected difficulty card — deliberately stay solid rather than glass, since glass is meant to change container material, not override intentional semantic color. The one caveat worth knowing: this is a `BackdropFilter`-based approximation, not real-time GPU refraction (Flutter has no equivalent), and it's been retrofitted onto plain `Container`/`Card` widgets one at a time, so a handful of screens (e.g. some Achievement-screen tiles) are intentionally left solid rather than converted.
- **`achievement_usecases.dart`'s difficulty-tracking TODO is resolved:** "Master of All" (win on every difficulty) now credits via `EvaluateAchievementDeltasUseCase.distinctProgressCredits` and `IncrementAchievementProgressBatchUseCase`'s `distinctProgress` param, rather than a plain per-win counter that couldn't distinguish "5 different difficulties" from "the same difficulty 5 times."
- **CI Flutter version drift:** `ci.yml`/`BuildAPK.yml` pin Flutter `3.29.3` while `release.yml` still pins `3.24.0` — the release pipeline could build against a materially older toolchain than what CI validates against.
- **Code comments show deliberate engineering discipline**, not just boilerplate: e.g. `main.dart` explains *why* both classic and cube games are eagerly restored before first frame, `json_store.dart` explains why it's deliberately kept thin rather than a general ORM, and `puzzle_generator.dart` documents why generation runs in a `compute()` isolate. This suggests a codebase maintained with care rather than one accumulating unreviewed AI-generated cruft.
- **iOS/macOS/Windows/Linux platform folders exist** in the repo (standard Flutter scaffolding) despite `pubspec.yaml`/CI only really targeting Android+Web and the changelog listing those as future work — likely dormant scaffolding rather than actively maintained targets; worth flagging as ambiguous rather than assuming intent.
- **No `.env`/secrets/API keys found** anywhere in `lib/` — the app is entirely offline/local-storage-based, which is consistent with its scope (no backend needed) but means anything like cloud sync or leaderboards would be a substantial new addition, not a config change.
- **Two parallel game engines by design, not duplication**: `sudoku` and `cube_sudoku` intentionally each have their own domain/data/presentation stack (confirmed via router comment: "a new mode alongside the regular game, not a replacement for it"), so overlapping-looking code (e.g., two achievement usecases, two local datasources) is an intentional feature boundary rather than an accidental copy-paste.
