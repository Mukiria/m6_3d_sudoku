import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/shared/widgets/app_header_bar.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

/// Lets the player choose a difficulty for each of the six cube faces
/// before a 3D Sudoku session starts — each face independently, via its
/// own inline dropdown, rather than a "set all faces" shortcut that could
/// silently overwrite choices already made for other faces.
class CubeDifficultySelectionScreen extends ConsumerStatefulWidget {
  const CubeDifficultySelectionScreen({super.key});

  @override
  ConsumerState<CubeDifficultySelectionScreen> createState() =>
      _CubeDifficultySelectionScreenState();
}

class _CubeDifficultySelectionScreenState
    extends ConsumerState<CubeDifficultySelectionScreen> {
  late Map<CubeFace, Difficulty> _selections;

  @override
  void initState() {
    super.initState();
    final defaultDifficulty = Difficulty.values.firstWhere(
      (d) => d.name == ref.read(settingsProvider).selectedDifficulty,
      orElse: () => Difficulty.medium,
    );
    _selections = {for (final face in CubeFace.values) face: defaultDifficulty};
  }

  void _setFaceDifficulty(CubeFace face, Difficulty difficulty) {
    setState(() => _selections[face] = difficulty);
  }

  void _start() {
    context.push(AppRoutes.cubePuzzleLoading, extra: _selections);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const AppHeaderBar(title: Text('M6 3D Sudoku Setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HowToPlayCard(),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Choose a difficulty for each of the six faces',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              for (final face in CubeFace.values)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.spacingSm,
                  ),
                  child: _FaceSummaryTile(
                    face: face,
                    difficulty: _selections[face]!,
                    onChanged:
                        (difficulty) => _setFaceDifficulty(face, difficulty),
                  ),
                ),
              const SizedBox(height: AppConstants.spacingMd),
              AppButton(
                onPressed: _start,
                variant: AppButtonVariant.filled,
                size: AppButtonSize.large,
                glassTint: AppThemeExtension.brandOrange.withValues(
                  alpha: 0.85,
                ),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.view_in_ar_rounded),
                child: const Text('Start 3D Sudoku'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceSummaryTile extends StatelessWidget {
  const _FaceSummaryTile({
    required this.face,
    required this.difficulty,
    required this.onChanged,
  });

  final CubeFace face;
  final Difficulty difficulty;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extension = theme.extension<AppThemeExtension>()!;
    final difficultyColor = _difficultyColor(difficulty, extension);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.grid_3x3_rounded, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              '${face.displayName} face',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: difficultyColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Difficulty>(
                value: difficulty,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: difficultyColor,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: difficultyColor,
                ),
                dropdownColor: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                items: [
                  for (final option in Difficulty.values)
                    DropdownMenuItem(
                      value: option,
                      child: Text(
                        option.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _difficultyColor(option, extension),
                        ),
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(Difficulty difficulty, AppThemeExtension extension) {
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
        return extension.difficultyEvilColor;
    }
  }
}

/// A short, static rundown of how Browse View's gestures work — the
/// cube's controls are otherwise entirely undiscoverable the first time
/// someone opens it, since nothing on screen hints that it's draggable.
class _HowToPlayCard extends StatelessWidget {
  const _HowToPlayCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const accent = AppThemeExtension.brandOrange;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: accent, size: 20),
              const SizedBox(width: AppConstants.spacingSm),
              Text(
                'Rotating the cube',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingSm),
          const _HowToPlayLine(
            icon: Icons.view_in_ar_outlined,
            text:
                'Pinch in on the puzzle, or tap the cube icon at the top, '
                'to open the rotating cube view.',
          ),
          const _HowToPlayLine(
            icon: Icons.drag_indicator_rounded,
            text: 'Drag anywhere on the cube to spin it and see each face.',
          ),
          const _HowToPlayLine(
            icon: Icons.center_focus_strong_rounded,
            text:
                'Tap the face that\'s facing you (or pinch out) to open it '
                'full-screen and start solving.',
          ),
          const _HowToPlayLine(
            icon: Icons.zoom_in_map_rounded,
            text:
                'Pinch in while solving (or tap the cube icon again) to '
                'shrink back onto the cube.',
          ),
          const _HowToPlayLine(
            icon: Icons.circle_outlined,
            text: 'Tap a dot above the cube to jump straight to that face.',
          ),
        ],
      ),
    );
  }
}

class _HowToPlayLine extends StatelessWidget {
  const _HowToPlayLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppConstants.spacingSm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
