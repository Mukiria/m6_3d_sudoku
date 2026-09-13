import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

/// The cube-sudoku counterpart of the regular game's `PauseMenu`. Pausing a
/// cube session is a pure UI/timer concern (see [CubeTimerController]) —
/// nothing here changes any face's own [GameStatus], so restarting only
/// ever regenerates puzzles, never silently un-fails or un-completes a
/// face.
class CubePauseSheet extends ConsumerWidget {
  const CubePauseSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubeState = ref.watch(cubeGameControllerProvider);

    // A bottom sheet's builder is only given loose width constraints, and
    // GlassSurface sizes itself to its content rather than stretching to
    // fill on its own — this keeps the sheet full-width instead of a
    // narrow, centered card (see PauseMenu for the same fix).
    return SizedBox(
      width: double.infinity,
      child: GlassSurface(
        variant: GlassVariant.strong,
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '3D Sudoku Paused',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Time: ${_formatTime(cubeState?.timeElapsed ?? 0)} · '
              '${cubeState?.facesCompleted ?? 0}/6 faces solved',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLg),
            AppButton(
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
              onPressed: () => context.go(AppRoutes.home),
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.large,
              icon: const Icon(Icons.home_rounded),
              child: const Text('Main Menu'),
            ),
            const SizedBox(height: AppConstants.spacingMd),
            AppButton(
              onPressed: () {
                if (cubeState != null) {
                  ref.read(cubeGameControllerProvider.notifier).newCubeGame({
                    for (final face in CubeFace.values)
                      face: cubeState.faceState(face).difficulty,
                  });
                }
                context.pop();
              },
              // Outlined, not a second filled/tinted CTA — Resume is the one
              // action this sheet should weight as primary.
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.large,
              icon: const Icon(Icons.refresh_rounded),
              child: const Text('Restart Cube'),
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
