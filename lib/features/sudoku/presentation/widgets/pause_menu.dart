import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

class PauseMenu extends ConsumerWidget {
  const PauseMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;
    final gameState = ref.watch(gameControllerProvider);

    // A bottom sheet's builder is only given loose width constraints, and
    // GlassSurface (unlike the plain Container this replaced) sizes itself
    // to its content rather than stretching to fill on its own — without
    // this, the sheet renders as a narrow, centered card instead of a
    // full-width sheet.
    return SizedBox(
      width: double.infinity,
      child: GlassSurface(
        variant: GlassVariant.strong,
        // Dark mode's usual translucent-white glass tint reads as barely
        // there over an already-near-black scaffold — a near-opaque black
        // instead gives the pause sheet a real, deliberate surface of its
        // own to sit on, rather than blending into the page behind it.
        tintColor:
            theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.95)
                : null,
        topLeftRadius: AppConstants.largeBorderRadius,
        topRightRadius: AppConstants.largeBorderRadius,
        bottomLeftRadius: 0,
        bottomRightRadius: 0,
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppConstants.spacingLg),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Game Paused',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Time: ${_formatTime(gameState?.timeElapsed ?? 0)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
              // GameScreen's own pause-sheet completion handler (see
              // _showPauseOverlay) is what actually resumes the game and
              // timer, for every way this sheet can close (this button,
              // swipe-to-dismiss, tapping the scrim) — this just closes it.
              onPressed: () => context.pop(),
              variant: AppButtonVariant.filled,
              size: AppButtonSize.large,
              glassTint: AppThemeExtension.brandOrange.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.play_arrow_rounded),
              child: const Text('Resume'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              onPressed: () {
                context.go(AppRoutes.home);
              },
              variant: AppButtonVariant.filled,
              size: AppButtonSize.large,
              glassTint: extension.difficultyEasyColor.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.home_rounded),
              child: const Text('Main Menu'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              onPressed: () {
                if (gameState != null) {
                  ref
                      .read(gameControllerProvider.notifier)
                      .newGame(
                        Difficulty.values.firstWhere(
                          (d) => d.name == gameState.difficulty.name,
                          orElse: () => Difficulty.easy,
                        ),
                      );
                }
                context.pop();
              },
              variant: AppButtonVariant.filled,
              size: AppButtonSize.large,
              glassTint: extension.difficultyEasyColor.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.refresh_rounded),
              child: const Text('Restart'),
            ),
            const SizedBox(height: AppConstants.spacingLg),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
