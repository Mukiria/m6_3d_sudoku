import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
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
      appBar: AppBar(title: const Text('3D Sudoku Setup'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a difficulty for each of the six faces',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Expanded(
                child: ListView.separated(
                  itemCount: CubeFace.values.length,
                  separatorBuilder:
                      (_, _) => const SizedBox(height: AppConstants.spacingSm),
                  itemBuilder: (context, index) {
                    final face = CubeFace.values[index];
                    return _FaceSummaryTile(
                      face: face,
                      difficulty: _selections[face]!,
                      onChanged:
                          (difficulty) =>
                              _setFaceDifficulty(face, difficulty),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              AppButton(
                onPressed: _start,
                variant: AppButtonVariant.filled,
                size: AppButtonSize.large,
                backgroundColor: AppThemeExtension.brandOrange,
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
              borderRadius: BorderRadius.circular(20),
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
        return extension.difficultyHardColor;
    }
  }
}
