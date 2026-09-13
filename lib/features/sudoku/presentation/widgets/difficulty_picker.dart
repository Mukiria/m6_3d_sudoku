import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

/// A single difficulty option — clues count, an estimated time, and a
/// selected/unselected visual state.
///
/// Extracted out of `DifficultySelectionScreen`'s inline `DifficultyCard` so
/// it can be reused wherever a difficulty needs picking: the existing
/// single-puzzle flow (no [label]) and, per cube face, the 3D Sudoku
/// difficulty-selection screen (labelled with that face's name).
class DifficultyPicker extends StatelessWidget {
  const DifficultyPicker({
    super.key,
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
    this.label,
  });

  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  /// An identifying heading shown above the card, e.g. a cube face name
  /// ("Front face"). Omitted (`null`) when there's only ever one puzzle to
  /// pick a difficulty for, as on the existing single-puzzle screen.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;

    final difficultyColor = _colorFor(difficulty, extension);

    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          // Selected is a semantic signal (this is the chosen difficulty),
          // not decorative chrome, so it keeps its solid, color-coded
          // highlight; unselected cards get their surface from the
          // GlassSurface wrapping this content instead (see below).
          decoration:
              isSelected
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      AppConstants.largeBorderRadius,
                    ),
                    border: Border.all(color: difficultyColor, width: 2.5),
                    color: difficultyColor.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: difficultyColor.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                  : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingSm),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? difficultyColor
                              : difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      difficulty.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : difficultyColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _descriptionFor(difficulty),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.format_list_numbered_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${difficulty.cluesCount} clues',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _estimatedTimeFor(difficulty),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: difficultyColor,
                      size: 28,
                    ).animate().scale(
                      duration: 200.ms,
                      curve: Curves.elasticOut,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return isSelected
        ? content
        : GlassSurface(
          cornerRadius: AppConstants.largeBorderRadius,
          child: content,
        );
  }

  Color _colorFor(Difficulty difficulty, AppThemeExtension extension) {
    switch (difficulty) {
      case Difficulty.easy:
        return extension.difficultyEasyColor;
      case Difficulty.medium:
        return extension.difficultyMediumColor;
      case Difficulty.hard:
        return extension.difficultyHardColor;
      case Difficulty.expert:
        return extension.difficultyExpertColor;
      case Difficulty.evil:
        return extension.difficultyHardColor; // Use hard color for evil
    }
  }

  String _descriptionFor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return 'Perfect for beginners. More clues, easier patterns.';
      case Difficulty.medium:
        return 'Balanced challenge. Standard Sudoku experience.';
      case Difficulty.hard:
        return 'Requires advanced techniques. Fewer clues.';
      case Difficulty.expert:
        return 'Expert level. Minimal clues, complex logic needed.';
      case Difficulty.evil:
        return 'Evil level. Minimal clues, extremely difficult.';
    }
  }

  String _estimatedTimeFor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return '5-10 min';
      case Difficulty.medium:
        return '10-20 min';
      case Difficulty.hard:
        return '20-40 min';
      case Difficulty.expert:
        return '40+ min';
      case Difficulty.evil:
        return '40+ min';
    }
  }
}
