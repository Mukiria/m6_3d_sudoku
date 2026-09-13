import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/core/theme/app_theme.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageServiceImpl(prefs);

  final container = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storageService)],
  );

  // Restore any in-progress game before the first frame renders, so
  // "Continue Game" reflects it immediately after a cold start rather than
  // only after some other screen happens to read gameControllerProvider.
  await container.read(gameControllerProvider.notifier).loadGame();
  // Same restoration for a paused 3D Sudoku session — its own save slot,
  // loaded independently so "Continue 3D Sudoku" is equally immediate.
  await container.read(cubeGameControllerProvider.notifier).loadCubeGame();

  runApp(
    UncontrolledProviderScope(container: container, child: const M6SudokuApp()),
  );
}

class M6SudokuApp extends ConsumerStatefulWidget {
  const M6SudokuApp({super.key});

  @override
  ConsumerState<M6SudokuApp> createState() => _M6SudokuAppState();
}

class _M6SudokuAppState extends ConsumerState<M6SudokuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Per-move autosave (plus a 30s backup timer) covers normal play, but
  // neither fires on its own when the app is backgrounded or the process is
  // killed — so without this, up to ~30s of ticked timeElapsed could be
  // lost between the last real move and the app going away. `paused` and
  // `hidden` cover backgrounding (task-switch, screen lock); `detached`
  // covers the tail end of an actual close. Flushing on all three is what
  // makes "Continue Game"/"Continue 3D Sudoku" reliably reflect the exact
  // moment the player left, not just the moment of their last tap.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(gameControllerProvider.notifier).saveNow();
      ref.read(cubeGameControllerProvider.notifier).saveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize audio service on first build
    ref.listen(audioServiceProvider, (_, __) {});

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      // AppTheme.lightTheme/darkTheme already register every extension
      // (AppThemeExtension, GlassTokens) themselves — no .copyWith needed
      // here. A prior .copyWith(extensions: [AppThemeExtension.light])
      // used to re-assert just that one extension, which silently
      // *replaced* the whole list and dropped GlassTokens from the active
      // theme (GlassTokens.of falls back to its own light default either
      // way, which is exactly how that went unnoticed in light mode and
      // only broke visibly once dark mode was actually tested).
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // WCAG 1.4.4 (Resize Text) requires text be scalable up to 200%
            // without loss of content or function — this floor just keeps
            // layouts from breaking at the extreme low end; the previous
            // 1.3 ceiling silently overrode every user's OS-level
            // accessibility text-size preference above that.
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler
                  .clamp(minScaleFactor: 0.8, maxScaleFactor: 2.0)
                  .scale(1.0),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
