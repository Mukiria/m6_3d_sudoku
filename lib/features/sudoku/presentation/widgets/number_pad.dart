import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';

/// The game's control panel: an action row (Undo / Erase / Notes / Pencil
/// Marks / Hint) followed by the 1-9 number row. Undo, Erase, Pencil Marks,
/// and Hint act directly on their providers since they need no per-cell
/// context from the caller — only number selection is routed back up, since
/// the caller owns what "select a number" means for cell input.
class NumberPad extends ConsumerWidget {
  const NumberPad({
    super.key,
    required this.selectedNumber,
    required this.onNumberSelected,
    required this.onNoteModeToggle,
    required this.isNoteMode,
    required this.disabledNumbers,
  });

  final int? selectedNumber;
  final void Function(int) onNumberSelected;
  final void Function() onNoteModeToggle;
  final bool isNoteMode;
  final Set<int> disabledNumbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Scoped to just the fields this widget renders, via a record, so
    // NumberPad doesn't rebuild on every unrelated GameState change (most
    // notably the once-a-second timer tick, which used to rebuild this
    // whole widget for a value it never reads).
    final selection = ref.watch(
      gameControllerProvider.select(
        (s) =>
            s == null
                ? null
                : (
                  hintsUsed: s.hintsUsed,
                  hasHistory: s.moveHistory.isNotEmpty,
                  selectedCell: s.selectedCell,
                ),
      ),
    );
    final showPencilMarks = ref.watch(showPencilMarksProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (selection == null) return const SizedBox.shrink();

    final hintsRemaining = (3 - selection.hintsUsed).clamp(0, 3);

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
              onTap: () => ref.read(gameControllerProvider.notifier).undo(),
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
                      .read(gameControllerProvider.notifier)
                      .clearCell(cell.row, cell.col);
                }
              },
              colorScheme: colorScheme,
            ),
            _ActionButton(
              icon: Icons.edit_note_rounded,
              label: 'Notes',
              onTap: onNoteModeToggle,
              colorScheme: colorScheme,
              badgeText: isNoteMode ? 'ON' : 'OFF',
              badgeColor:
                  isNoteMode ? colorScheme.primary : colorScheme.outlineVariant,
              badgeTextColor:
                  isNoteMode
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
              onTap: () => ref.read(gameControllerProvider.notifier).useHint(),
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
            final isSelected = selectedNumber == number;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                onTap: isDisabled ? null : () => onNumberSelected(number),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
            );
          }),
        ),
      ],
    );
  }
}

/// The rounded white card shared by the action row and the number row.
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
