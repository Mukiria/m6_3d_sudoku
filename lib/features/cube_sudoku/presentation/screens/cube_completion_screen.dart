import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

/// Shown once every one of the six faces has been solved. Reads the
/// completed session straight from [cubeGameControllerProvider] — the
/// controller is left in place (not cleared) once solved, the same way the
/// regular game's `GameState` stays around after completion, so this
/// screen needs no navigation payload of its own.
class CubeCompletionScreen extends ConsumerStatefulWidget {
  const CubeCompletionScreen({super.key});

  @override
  ConsumerState<CubeCompletionScreen> createState() =>
      _CubeCompletionScreenState();
}

class _CubeCompletionScreenState extends ConsumerState<CubeCompletionScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubeState = ref.watch(cubeGameControllerProvider);

    if (cubeState == null) {
      // Reached directly (e.g. a deep link, or a hot restart mid-flow)
      // without ever completing a cube — nothing to summarize.
      return Scaffold(
        body: Center(
          child: AppButton(
            onPressed: () => context.go(AppRoutes.home),
            variant: AppButtonVariant.filled,
            child: const Text('Back to Home'),
          ),
        ),
      );
    }

    final totalMistakes = CubeFace.values.fold<int>(
      0,
      (sum, face) => sum + cubeState.faceState(face).mistakes,
    );
    final totalHints = CubeFace.values.fold<int>(
      0,
      (sum, face) => sum + cubeState.faceState(face).hintsUsed,
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppThemeExtension.brandOrange.withValues(alpha: 0.1),
                  colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppThemeExtension.brandOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeExtension.brandOrange
                                    .withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.view_in_ar_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1000.ms),

                    const SizedBox(height: AppConstants.spacingXl),

                    Text(
                          'Cube Complete!',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppConstants.spacingSm),

                    Text(
                          'All six faces solved',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppConstants.spacingXl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _CompletionStat(
                          icon: Icons.timer_rounded,
                          label: 'Time',
                          value: _formatTime(cubeState.timeElapsed),
                          color: AppThemeExtension.brandBlue,
                          delay: 500,
                        ),
                        _CompletionStat(
                          icon: Icons.close_rounded,
                          label: 'Mistakes',
                          value: '$totalMistakes',
                          color: colorScheme.error,
                          delay: 600,
                        ),
                        _CompletionStat(
                          icon: Icons.lightbulb_rounded,
                          label: 'Hints',
                          value: '$totalHints',
                          color: Colors.amber.shade800,
                          delay: 700,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingXl),

                    _FaceBreakdown(cubeState: cubeState),

                    const Spacer(),

                    Column(
                      children: [
                        AppButton(
                              onPressed:
                                  () => context.go(AppRoutes.cubeDifficulty),
                              variant: AppButtonVariant.filled,
                              size: AppButtonSize.large,
                              backgroundColor: AppThemeExtension.brandOrange,
                              foregroundColor: Colors.white,
                              icon: const Icon(Icons.refresh_rounded),
                              child: const Text('New 3D Sudoku'),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 800.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: AppConstants.spacingMd),
                        AppButton(
                              onPressed: () => context.go(AppRoutes.home),
                              variant: AppButtonVariant.outlined,
                              size: AppButtonSize.large,
                              icon: const Icon(Icons.home_rounded),
                              child: const Text('Main Menu'),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 900.ms)
                            .slideY(begin: 0.3, end: 0),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXl),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.57,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              maxBlastForce: 10,
              minBlastForce: 5,
              colors: const [
                AppThemeExtension.brandOrange,
                Colors.white,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) return '${minutes}m ${secs}s';
    return '${secs}s';
  }
}

class _CompletionStat extends StatelessWidget {
  const _CompletionStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.delay,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .slideY(begin: 0.3, end: 0);
  }
}

class _FaceBreakdown extends StatelessWidget {
  const _FaceBreakdown({required this.cubeState});

  final CubeGameState cubeState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (final face in CubeFace.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      face.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    cubeState.faceState(face).difficulty.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Text(
                    '${cubeState.faceState(face).mistakes} mistakes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
