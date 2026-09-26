import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/shared/widgets/cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : _HomeColors.background;
    final textColor = isDark ? Colors.white : _HomeColors.text;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.spacingXl),

              // Title
              Center(
                child: Semantics(
                  label: AppConstants.appName,
                  child: Image.asset(
                    'assets/images/m6-sudoku-logotype.png',
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: AppConstants.spacingXl),

              // Continue Game or New Game
              Consumer(
                builder: (context, ref, child) {
                  final gameState = ref.watch(gameControllerProvider);
                  final hasSavedGame =
                      gameState != null &&
                      gameState.status != GameStatus.completed &&
                      gameState.status != GameStatus.failed;

                  return Column(
                    children: [
                      if (hasSavedGame) ...[
                        AppButton(
                              onPressed:
                                  () => _continueGame(context, ref, gameState),
                              variant: AppButtonVariant.filled,
                              size: AppButtonSize.large,
                              glassTint: AppThemeExtension.brandOrange
                                  .withValues(alpha: 0.85),
                              foregroundColor: Colors.white,
                              child: const Text('Continue Game'),
                            )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: 200.ms)
                            .slideX(begin: -0.2, end: 0),
                        const SizedBox(height: AppConstants.spacingMd),
                      ],
                      AppButton(
                            onPressed:
                                () =>
                                    context.push(AppRoutes.difficultySelection),
                            variant: AppButtonVariant.filled,
                            size: AppButtonSize.large,
                            glassTint: AppThemeExtension.brandOrange.withValues(
                              alpha: 0.85,
                            ),
                            foregroundColor: Colors.white,
                            icon: const Icon(Icons.add_rounded),
                            child: const Text('New Game'),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 300.ms)
                          .slideX(begin: 0.2, end: 0),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // 3D Sudoku — a separate mode with its own save slot (see
              // CubeGameLocalDataSource), so it gets its own
              // Continue/Play pair rather than sharing the one above.
              Consumer(
                builder: (context, ref, child) {
                  final cubeState = ref.watch(cubeGameControllerProvider);
                  final hasSavedCube =
                      cubeState != null && !cubeState.isComplete;

                  return Column(
                    children: [
                      if (hasSavedCube) ...[
                        AppButton(
                              onPressed:
                                  () => _continueCube(context, ref, cubeState),
                              variant: AppButtonVariant.filled,
                              size: AppButtonSize.large,
                              glassTint: AppThemeExtension.brandOrange
                                  .withValues(alpha: 0.85),
                              foregroundColor: Colors.white,
                              icon: const Icon(Icons.view_in_ar_rounded),
                              child: const Text('Continue 3D Sudoku'),
                            )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: 350.ms)
                            .slideX(begin: -0.2, end: 0),
                        const SizedBox(height: AppConstants.spacingMd),
                      ],
                      AppButton(
                            onPressed:
                                () => context.push(AppRoutes.cubeDifficulty),
                            variant: AppButtonVariant.filled,
                            size: AppButtonSize.large,
                            glassTint: AppThemeExtension.brandOrange.withValues(
                              alpha: 0.85,
                            ),
                            foregroundColor: Colors.white,
                            icon: const Icon(Icons.view_in_ar_rounded),
                            child: const Text('Play 3D Sudoku'),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms, delay: 400.ms)
                          .slideX(begin: 0.2, end: 0),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppConstants.spacingXl),

              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                          icon: Icons.calendar_today_rounded,
                          label: 'Daily',
                          onPressed:
                              () => context.push(AppRoutes.dailyChallenge),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 450.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: _QuickActionButton(
                          icon: Icons.bar_chart_rounded,
                          label: 'Statistics',
                          onPressed: () => context.push(AppRoutes.statistics),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 500.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                          icon: Icons.emoji_events_rounded,
                          label: 'Awards',
                          onPressed: () => context.push(AppRoutes.achievements),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 550.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Expanded(
                    child: _QuickActionButton(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onPressed: () => context.push(AppRoutes.settings),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                  ),
                ],
              ),

              const Spacer(),

              // Mascot
              Center(
                    child: Image.asset(
                      'assets/images/m6-sudoku-mascot.png',
                      height: 160,
                      fit: BoxFit.contain,
                      excludeFromSemantics: true,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 650.ms)
                  .slideY(
                    begin: 1.0,
                    end: 0,
                    duration: 500.ms,
                    delay: 650.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: AppConstants.spacingSm),

              // Version
              Text(
                'Version ${AppConstants.appVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 300.ms, delay: 700.ms),
            ],
          ),
        ),
      ),
    );
  }

  void _continueGame(BuildContext context, WidgetRef ref, GameState gameState) {
    ref.read(gameControllerProvider.notifier).continueGame(gameState);
    // 'continue' tells GameScreen the session is already loaded (regular or
    // daily) — it must not try to match/regenerate a puzzle from this string.
    context.push(AppRoutes.game, extra: 'continue');
  }

  void _continueCube(
    BuildContext context,
    WidgetRef ref,
    CubeGameState cubeState,
  ) {
    ref.read(cubeGameControllerProvider.notifier).continueCubeGame(cubeState);
    context.push(AppRoutes.cubeGame);
  }
}

/// Background and text color for the home screen's flat backdrop in light
/// mode — dark mode uses a plain black backdrop with white text instead.
class _HomeColors {
  _HomeColors._();

  static const Color background = Color(0xFFFFFBF2);
  static const Color text = Color(0xFF2C2A28);
}

/// A quick-action tile: a thin wrapper over [AppCard] (sized to fit its
/// icon+label content rather than a fixed button height) so these four
/// buttons render as the same neutral glass surface as every other card in
/// the app — the flat backdrop color shows through, tinted, rather than
/// being covered by an opaque card.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : _HomeColors.text;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: AppThemeExtension.brandOrange),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
