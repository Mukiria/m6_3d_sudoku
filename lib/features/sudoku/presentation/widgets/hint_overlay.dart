import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';

class HintOverlay extends StatelessWidget {
  const HintOverlay({
    super.key,
    required this.hintState,
    required this.onDismiss,
  });

  final HintState hintState;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;

    Color hintColor;
    IconData hintIcon;
    String title;

    switch (hintState.type) {
      case HintType.nakedSingle:
        hintColor = Colors.green;
        hintIcon = Icons.lightbulb_rounded;
        title = 'Naked Single';
        break;
      case HintType.hiddenSingle:
        hintColor = Colors.blue;
        hintIcon = Icons.search_rounded;
        title = 'Hidden Single';
        break;
      case HintType.directReveal:
        hintColor = Colors.orange;
        hintIcon = Icons.visibility_rounded;
        title = 'Direct Reveal';
        break;
      default:
        hintColor = extension.hintButtonText;
        hintIcon = Icons.lightbulb_rounded;
        title = 'Hint';
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background overlay
          Container(
            color: Colors.black.withValues(alpha: 0.5),
          ).animate().fadeIn(duration: 300.ms),

          // Hint card
          Center(
            child: Container(
              margin: const EdgeInsets.all(AppConstants.spacingLg),
              padding: const EdgeInsets.all(AppConstants.spacingXl),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  AppConstants.largeBorderRadius,
                ),
                border: Border.all(color: hintColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: hintColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: hintColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(hintIcon, color: hintColor, size: 40),
                      )
                      .animate()
                      .scale(duration: 500.ms, curve: Curves.elasticOut)
                      .shimmer(duration: 1500.ms),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Title
                  Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: hintColor,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Explanation
                  Text(
                        hintState.explanation,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: AppConstants.spacingMd),

                  // Cell position
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hintColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Row ${hintState.cell.row + 1}, Column ${hintState.cell.col + 1}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hintColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                  const SizedBox(height: AppConstants.spacingLg),

                  // Value revealed
                  Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: hintColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            hintState.value.toString(),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 500.ms)
                      .scale(
                        duration: 500.ms,
                        delay: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .shimmer(duration: 2000.ms),

                  const SizedBox(height: AppConstants.spacingXl),

                  // Dismiss button
                  SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onDismiss,
                          style: FilledButton.styleFrom(
                            backgroundColor: hintColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius,
                              ),
                            ),
                          ),
                          child: Text(
                            'Got it!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
