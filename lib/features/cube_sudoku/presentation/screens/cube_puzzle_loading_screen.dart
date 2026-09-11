import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

class CubePuzzleLoadingScreen extends ConsumerStatefulWidget {
  const CubePuzzleLoadingScreen({super.key, required this.difficulties});

  final Map<CubeFace, Difficulty> difficulties;

  @override
  ConsumerState<CubePuzzleLoadingScreen> createState() =>
      _CubePuzzleLoadingScreenState();
}

class _CubePuzzleLoadingScreenState
    extends ConsumerState<CubePuzzleLoadingScreen> {
  bool _isGenerating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePuzzles();
  }

  Future<void> _generatePuzzles() async {
    try {
      await ref
          .read(cubeGameControllerProvider.notifier)
          .newCubeGame(widget.difficulties);
      if (mounted) {
        context.go(AppRoutes.cubeGame);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Failed to generate puzzles: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
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
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppThemeExtension.brandOrange,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeExtension.brandOrange.withValues(
                              alpha: 0.3,
                            ),
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
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 3000.ms, curve: Curves.linear),

                const SizedBox(height: AppConstants.spacingXl),

                Text(
                  'Building Your Cube',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                const SizedBox(height: AppConstants.spacingSm),

                Text(
                  'Generating all six puzzles in parallel…',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                const SizedBox(height: AppConstants.spacingXl),

                if (_error != null) ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 60,
                    color: extension.cellErrorBorder,
                  ).animate().fadeIn(duration: 400.ms).shake(),
                  const SizedBox(height: AppConstants.spacingLg),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: extension.cellErrorBorder,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingLg),
                  AppButton(
                    onPressed: () {
                      setState(() {
                        _isGenerating = true;
                        _error = null;
                      });
                      _generatePuzzles();
                    },
                    variant: AppButtonVariant.filled,
                    child: const Text('Retry'),
                  ),
                ] else
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppThemeExtension.brandOrange,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
