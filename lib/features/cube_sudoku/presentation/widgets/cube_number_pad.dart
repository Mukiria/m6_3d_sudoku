import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart'
    show showPencilMarksProvider;

/// [face]'s control panel — the cube-sudoku counterpart of the regular
/// game's `NumberPad`, wired to [cubeGameControllerProvider] for one face
/// instead of the single-board `gameControllerProvider`. Kept as its own
/// widget (rather than generalizing `NumberPad`) so the existing single-
/// puzzle screen's controller wiring stays untouched.
class CubeNumberPad extends ConsumerWidget {
  const CubeNumberPad({super.key, required this.face});

  final CubeFace face;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(
      cubeGameControllerProvider.select((s) {
        if (s == null) return null;
        final f = s.faceState(face);
        return (
          selectedNumber: f.selectedNumber,
          isNoteMode: f.isNoteMode,
          userGrid: f.userGrid,
          hintsUsed: f.hintsUsed,
          hasHistory: f.moveHistory.isNotEmpty,
          selectedCell: f.selectedCell,
          isPlayable: f.status == GameStatus.playing,
        );
      }),
    );
    final showPencilMarks = ref.watch(showPencilMarksProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (selection == null) return const SizedBox.shrink();

    // A failed/completed face has nothing left to input — its board shows
    // its own overlay (see CubeFaceBoard) instead.
    if (!selection.isPlayable) return const SizedBox.shrink();

    final hintsRemaining = (3 - selection.hintsUsed).clamp(0, 3);
    final disabledNumbers = _disabledNumbers(selection.userGrid);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionCard(
          colorScheme: colorScheme,
          children: [
            _ActionButton(
              icon: Icons.undo_rounded,
              label: 'Undo',
              isEnabled: selection.hasHistory,
              onTap: () => ref.read(cubeGameControllerProvider.notifier).undo(face),
              colorScheme: colorScheme,
            ),
            _ActionButton(
              icon: Icons.backspace_outlined,
              label: 'Erase',
              isEnabled: selection.selectedCell != null,
              onTap: () {
                final cell = selection.selectedCell;
                if (cell != null) {
                  ref
                      .read(cubeGameControllerProvider.notifier)
                      .clearCell(face, cell.row, cell.col);
                }
              },
              colorScheme: colorScheme,
            ),
            _ActionButton(
              icon: Icons.edit_note_rounded,
              label: 'Notes',
              onTap:
                  () => ref
                      .read(cubeGameControllerProvider.notifier)
                      .toggleNoteMode(face),
              colorScheme: colorScheme,
              badgeText: selection.isNoteMode ? 'ON' : 'OFF',
              badgeColor:
                  selection.isNoteMode
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
              badgeTextColor:
                  selection.isNoteMode
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
            ),
            _ActionButton(
              icon:
                  showPencilMarks
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
              label: 'Pencil',
              onTap:
                  () =>
                      ref.read(showPencilMarksProvider.notifier).state =
                          !showPencilMarks,
              colorScheme: colorScheme,
              badgeText: showPencilMarks ? 'ON' : 'OFF',
              badgeColor:
                  showPencilMarks
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
              badgeTextColor:
                  showPencilMarks
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
            ),
            _ActionButton(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Hint',
              isEnabled: hintsRemaining > 0,
              onTap:
                  () => ref.read(cubeGameControllerProvider.notifier).useHint(face),
              colorScheme: colorScheme,
              badgeText: 'Free x$hintsRemaining',
              badgeColor: colorScheme.primary,
              badgeTextColor: colorScheme.onPrimary,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _ActionCard(
          colorScheme: colorScheme,
          children: List.generate(9, (index) {
            final number = index + 1;
            final isDisabled = disabledNumbers.contains(number);
            final isSelected = selection.selectedNumber == number;

            return Expanded(
              child: Semantics(
                label:
                    isDisabled
                        ? 'Enter $number, all nine placed already'
                        : 'Enter $number',
                selected: isSelected,
                button: true,
                enabled: !isDisabled,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                  onTap:
                      isDisabled
                          ? null
                          : () => ref
                              .read(cubeGameControllerProvider.notifier)
                              .selectNumber(face, number),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ExcludeSemantics(
                      child: Text(
                        number.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color:
                              isDisabled
                                  ? colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.35,
                                  )
                                  : (isDark
                                      ? Colors.white
                                      : AppThemeExtension.brandBlue),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Set<int> _disabledNumbers(List<List<int>> userGrid) {
    final counts = <int, int>{};
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final val = userGrid[r][c];
        if (val != 0) counts[val] = (counts[val] ?? 0) + 1;
      }
    }
    final disabled = <int>{};
    for (int i = 1; i <= 9; i++) {
      if ((counts[i] ?? 0) >= 9) disabled.add(i);
    }
    return disabled;
  }
}

/// The rounded white card shared by the action row and the number row —
/// visually identical to `NumberPad`'s private counterpart.
class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.children, required this.colorScheme});

  final List<Widget> children;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingSm,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.isEnabled = true,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isEnabled;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;

  @override
  Widget build(BuildContext context) {
    final color =
        isEnabled
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: AppConstants.spacingXs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 24, color: color),
                  if (badgeText != null)
                    Positioned(
                      right: -14,
                      top: -8,
                      child: _Badge(
                        text: badgeText!,
                        color: badgeColor ?? colorScheme.primary,
                        textColor: badgeTextColor ?? colorScheme.onPrimary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
  });

  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }
}
