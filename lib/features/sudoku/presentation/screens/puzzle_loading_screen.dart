import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

class PuzzleLoadingScreen extends ConsumerStatefulWidget {
  const PuzzleLoadingScreen({super.key, required this.difficulty});

  final String difficulty;

  @override
  ConsumerState<PuzzleLoadingScreen> createState() =>
      _PuzzleLoadingScreenState();
}

class _PuzzleLoadingScreenState extends ConsumerState<PuzzleLoadingScreen> {
  bool _isGenerating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  Future<void> _generatePuzzle() async {
    try {
      final difficulty = Difficulty.values.firstWhere(
        (d) => d.name == widget.difficulty,
        orElse: () => Difficulty.easy,
      );
      await ref.read(gameControllerProvider.notifier).newGame(difficulty);
      if (mounted) {
        context.go(AppRoutes.game, extra: widget.difficulty);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _error = 'Failed to generate puzzle: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;

    Color difficultyColor;
    switch (widget.difficulty) {
      case 'easy':
        difficultyColor = extension.difficultyEasyColor;
        break;
      case 'medium':
        difficultyColor = extension.difficultyMediumColor;
        break;
      case 'hard':
        difficultyColor = extension.difficultyHardColor;
        break;
      case 'expert':
        difficultyColor = extension.difficultyExpertColor;
        break;
      default:
        difficultyColor = colorScheme.primary;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              difficultyColor.withValues(alpha: 0.1),
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
                // Puzzle piece animation
                Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: difficultyColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: difficultyColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.grid_3x3_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1500.ms),

                const SizedBox(height: AppConstants.spacingXl),

                // Title
                Text(
                      'Generating Puzzle',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: AppConstants.spacingSm),

                // Difficulty
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: difficultyColor, width: 1.5),
                      ),
                      child: Text(
                        widget.difficulty.capitalize(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: difficultyColor,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: AppConstants.spacingXl),

                // Loading indicator or error
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
                      _generatePuzzle();
                    },
                    variant: AppButtonVariant.filled,
                    child: const Text('Retry'),
                  ),
                ] else ...[
                  SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            difficultyColor,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .scale(
                        duration: 400.ms,
                        delay: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: AppConstants.spacingLg),

                  Text(
                        'Creating unique solution...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
