import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/core/theme/app_theme.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

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

class M6SudokuApp extends ConsumerWidget {
  const M6SudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Initialize audio service on first build
    ref.listen(audioServiceProvider, (_, __) {});

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        extensions: [AppThemeExtension.light],
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        extensions: [AppThemeExtension.dark],
      ),
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
