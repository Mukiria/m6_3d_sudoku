import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/sudoku_board.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

/// One cube face's board — a thin wrapper around the existing [SudokuBoard]
/// that also renders a "this face failed" overlay in place of interaction
/// once its 3-mistake limit is hit (the other five faces are unaffected).
class CubeFaceBoard extends StatelessWidget {
  const CubeFaceBoard({
    super.key,
    required this.face,
    required this.gameState,
    required this.showPencilMarks,
    required this.selectionEpoch,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.onRetry,
  });

  final CubeFace face;
  final GameState gameState;
  final bool showPencilMarks;
  final int selectionEpoch;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col) onCellLongPress;
  final VoidCallback onRetry;

  static List<List<Set<int>>> _emptyNotesGrid() =>
      List.generate(9, (_) => List.generate(9, (_) => <int>{}));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SudokuBoard(
          puzzle: gameState.puzzle,
          userGrid: gameState.userGrid,
          notes: showPencilMarks ? gameState.notes : _emptyNotesGrid(),
          selectedCell: gameState.selectedCell,
          highlightedCells: gameState.highlightedCells,
          conflictCells: gameState.conflictCells,
          isNoteMode: gameState.isNoteMode,
          selectionEpoch: selectionEpoch,
          onCellTap: onCellTap,
          onCellLongPress: onCellLongPress,
        ),
        if (gameState.status == GameStatus.failed)
          Positioned.fill(child: _FailedFaceOverlay(face: face, onRetry: onRetry)),
      ],
    );
  }
}

class _FailedFaceOverlay extends StatelessWidget {
  const _FailedFaceOverlay({required this.face, required this.onRetry});

  final CubeFace face;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      label: '${face.displayName} face failed. Too many mistakes.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: AppConstants.spacingSm),
                Text(
                  '${face.displayName} face failed',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Too many mistakes. The other faces are unaffected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingMd),
                AppButton(
                  onPressed: onRetry,
                  variant: AppButtonVariant.filled,
                  icon: const Icon(Icons.refresh_rounded),
                  child: const Text('Retry this face'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
