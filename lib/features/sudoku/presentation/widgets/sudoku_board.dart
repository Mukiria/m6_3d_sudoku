import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';

/// Caps the rendered board size on very large screens (tablets, desktop)
/// so cells stay comfortably readable instead of growing unbounded.
const double _maxBoardSize = 900.0;

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    super.key,
    required this.puzzle,
    required this.userGrid,
    required this.notes,
    required this.selectedCell,
    required this.highlightedCells,
    required this.conflictCells,
    required this.isNoteMode,
    required this.selectionEpoch,
    required this.onCellTap,
    required this.onCellLongPress,
  });

  final Puzzle puzzle;
  final List<List<int>> userGrid;
  final List<List<Set<int>>> notes;
  final CellPosition? selectedCell;
  final Set<CellPosition> highlightedCells;
  final Set<CellPosition> conflictCells;
  final bool isNoteMode;

  /// Bumped by the caller each time [selectedCell] changes to a different
  /// cell. Cells key their fade animation off this so a fresh selection
  /// always restarts the 3-second fade from full strength, rather than
  /// picking up wherever the previous cell's animation left off.
  final int selectionEpoch;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col) onCellLongPress;

  @override
  Widget build(BuildContext context) {
    final extension = Theme.of(context).extension<AppThemeExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight =
            constraints.hasBoundedHeight ? constraints.maxHeight : maxWidth;
        final side = math.min(maxWidth, maxHeight).clamp(0.0, _maxBoardSize);
        final cellSize = side / AppConstants.gridSize;

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: extension.gridBackgroundColor,
                  border: Border.all(
                    color: extension.subGridLineColor,
                    width: 2.0,
                  ),
                ),
                child: _SudokuBoardView(
                  puzzle: puzzle,
                  userGrid: userGrid,
                  notes: notes,
                  selectedCell: selectedCell,
                  highlightedCells: highlightedCells,
                  conflictCells: conflictCells,
                  cellSize: cellSize,
                  selectionEpoch: selectionEpoch,
                  onCellTap: onCellTap,
                  onCellLongPress: onCellLongPress,
                  extension: extension,
                  colorScheme: colorScheme,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renders the 81 cells in a single [GridView.builder] so every column and
/// row shares one layout pass — this is what guarantees the grid is a
/// perfect square with perfectly aligned borders. Grid lines are drawn as
/// part of each cell's own border (see [_SudokuCell]) rather than by a
/// separate overlay, so they can never drift out of alignment with the
/// cells they outline.
class _SudokuBoardView extends StatelessWidget {
  const _SudokuBoardView({
    required this.puzzle,
    required this.userGrid,
    required this.notes,
    required this.selectedCell,
    required this.highlightedCells,
    required this.conflictCells,
    required this.cellSize,
    required this.selectionEpoch,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.extension,
    required this.colorScheme,
  });

  final Puzzle puzzle;
  final List<List<int>> userGrid;
  final List<List<Set<int>>> notes;
  final CellPosition? selectedCell;
  final Set<CellPosition> highlightedCells;
  final Set<CellPosition> conflictCells;
  final double cellSize;
  final int selectionEpoch;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col) onCellLongPress;
  final AppThemeExtension extension;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppConstants.gridSize,
      ),
      itemCount: AppConstants.totalCells,
      itemBuilder: (context, index) {
        final row = index ~/ AppConstants.gridSize;
        final col = index % AppConstants.gridSize;
        final position = CellPosition(row: row, col: col);
        final isFixed = puzzle.grid[row][col] != 0;
        final userValue = userGrid[row][col];
        final value =
            userValue != 0
                ? userValue
                : (isFixed ? puzzle.grid[row][col] : null);

        return _SudokuCell(
          key: ValueKey('cell_$row$col'),
          row: row,
          col: col,
          value: value,
          cellNotes: notes[row][col],
          isFixed: isFixed,
          isSelected: selectedCell == position,
          isHighlighted: highlightedCells.contains(position),
          isConflicted: conflictCells.contains(position),
          cellSize: cellSize,
          selectionEpoch: selectionEpoch,
          onCellTap: onCellTap,
          onCellLongPress: onCellLongPress,
          extension: extension,
          colorScheme: colorScheme,
        );
      },
    );
  }
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    super.key,
    required this.row,
    required this.col,
    required this.value,
    required this.cellNotes,
    required this.isFixed,
    required this.isSelected,
    required this.isHighlighted,
    required this.isConflicted,
    required this.cellSize,
    required this.selectionEpoch,
    required this.onCellTap,
    required this.onCellLongPress,
    required this.extension,
    required this.colorScheme,
  });

  /// How long the highlight stays at full strength before it starts to
  /// fade out.
  static const int _highlightHoldMs = 3000;

  /// How long the fade-out transition itself takes, once it starts.
  static const int _highlightFadeOutMs = 400;

  static const Duration _highlightAnimationDuration = Duration(
    milliseconds: _highlightHoldMs + _highlightFadeOutMs,
  );

  /// The fraction of [_highlightAnimationDuration] spent holding at full
  /// strength before the fade-out begins — fed into an [Interval] so the
  /// tween sits at its `begin` value until this point, then eases to `end`.
  static const double _highlightHoldFraction =
      _highlightHoldMs / (_highlightHoldMs + _highlightFadeOutMs);

  final int row;
  final int col;
  final int? value;
  final Set<int> cellNotes;
  final bool isFixed;
  final bool isSelected;
  final bool isHighlighted;
  final bool isConflicted;
  final double cellSize;
  final int selectionEpoch;
  final void Function(int row, int col) onCellTap;
  final void Function(int row, int col) onCellLongPress;
  final AppThemeExtension extension;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    // Background color and border are the only things that change with
    // selection state — the cell's footprint never changes, so selection
    // and highlighting can never shift neighboring cells or push the grid
    // out of alignment.
    //
    // The blue selection/highlight tint holds at full strength for three
    // seconds, then fades out. Keying the tween on [selectionEpoch] (bumped
    // by the caller whenever the selected cell changes) forces every cell's
    // animation to restart from full strength the moment a new cell is
    // selected, instead of picking up wherever the previous selection's fade
    // left off.
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(selectionEpoch),
        tween: Tween<double>(begin: 1.0, end: 0.0),
        duration: _highlightAnimationDuration,
        curve: const Interval(
          _highlightHoldFraction,
          1.0,
          curve: Curves.easeIn,
        ),
        builder: (context, highlightStrength, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: _backgroundColor(highlightStrength),
              border: _border(),
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Semantics(
            label: _semanticsLabel,
            value: _semanticsValue,
            selected: isSelected,
            button: true,
            child: InkWell(
              onTap: () => onCellTap(row, col),
              onLongPress: () => onCellLongPress(row, col),
              splashColor: colorScheme.primary.withValues(alpha: 0.12),
              highlightColor: colorScheme.primary.withValues(alpha: 0.06),
              // The visual content below (a bare digit, or a grid of note
              // digits) would otherwise surface as its own, uncoordinated
              // semantics nodes — excluded so the single label/value above
              // is what a screen reader actually reports for this cell.
              child: Center(child: ExcludeSemantics(child: _buildContent())),
            ),
          ),
        ),
      ),
    );
  }

  /// "Row 3, column 5, given" / "..., conflicts with another cell" — the
  /// conflict callout here is also this cell's non-color indicator for
  /// screen-reader users; [_border] gives sighted users an equivalent
  /// non-color (shape-based) cue for the same state.
  String get _semanticsLabel {
    final parts = ['Row ${row + 1}, column ${col + 1}'];
    if (isFixed) parts.add('given');
    if (isConflicted) parts.add('conflicts with another cell');
    return parts.join(', ');
  }

  String get _semanticsValue {
    if (value != null) return value.toString();
    if (cellNotes.isEmpty) return 'empty';
    final sorted = cellNotes.toList()..sort();
    return 'candidate notes ${sorted.join(', ')}';
  }

  /// The color this cell settles at once its highlight (if any) has fully
  /// faded away.
  Color _restingColor() {
    if (isFixed) return extension.cellFixedBackground;
    return extension.cellBackground;
  }

  /// Blends from [_restingColor] to the active blue highlight color as
  /// [highlightStrength] goes from 0.0 to 1.0. Conflicts are left out of the
  /// fade entirely — they should stay fully visible until resolved.
  Color _backgroundColor(double highlightStrength) {
    Color base;
    if (isConflicted) {
      base = extension.cellErrorBackground;
    } else if (!isSelected && !isHighlighted) {
      base = _restingColor();
    } else {
      final activeColor =
          isSelected
              ? extension.cellSelectedBackground
              : extension.cellRelatedBackground;
      base =
          Color.lerp(_restingColor(), activeColor, highlightStrength) ??
          _restingColor();
    }

    // A faint checkerboard over the 3x3 boxes so they stay easy to tell
    // apart at a glance — dark mode's boxes are otherwise indistinguishable
    // since the thick subgrid lines already read as fairly subtle against a
    // dark background. Left out of light mode, where the existing outline
    // is already clear enough on its own.
    if (colorScheme.brightness == Brightness.dark && _isEvenSubgrid) {
      base = Color.alphaBlend(Colors.white.withValues(alpha: 0.1), base);
    }
    return base;
  }

  /// The 3x3 boxes form their own 3x3 arrangement (indices 0-8, left-to-right
  /// then top-to-bottom) — "even" here means that arrangement's own
  /// checkerboard, the same corners-and-center pattern common in printed
  /// Sudoku puzzles, not anything about individual row/column parity.
  bool get _isEvenSubgrid {
    final boxRow = row ~/ AppConstants.subGridSize;
    final boxCol = col ~/ AppConstants.subGridSize;
    return (boxRow * AppConstants.subGridSize + boxCol).isEven;
  }

  /// Thin lines between cells, thick lines every three cells to mark the
  /// 3x3 boxes. Only the right/bottom edges are drawn — the last row/column
  /// of a box relies on the outer board border instead — so no two cells
  /// ever draw overlapping edges of differing widths.
  ///
  /// A conflicted cell breaks that pattern deliberately: it gets a full
  /// boxed outline on all four sides, not just a color change, so the
  /// conflict reads by shape as well as by hue for players who can't rely
  /// on color alone to tell it apart from the selection highlight.
  Border _border() {
    if (isConflicted) {
      return Border.all(color: extension.cellErrorBorder, width: 2.0);
    }

    final thin = BorderSide(color: extension.cellBorder, width: 1.0);
    final thick = BorderSide(color: extension.subGridLineColor, width: 2.0);

    return Border(
      right:
          col == AppConstants.gridSize - 1
              ? BorderSide.none
              : ((col + 1) % AppConstants.subGridSize == 0 ? thick : thin),
      bottom:
          row == AppConstants.gridSize - 1
              ? BorderSide.none
              : ((row + 1) % AppConstants.subGridSize == 0 ? thick : thin),
    );
  }

  Widget _buildContent() {
    if (value != null) {
      return _NumberCell(
        value: value!,
        isFixed: isFixed,
        isConflicted: isConflicted,
        cellSize: cellSize,
      );
    }

    if (cellNotes.isNotEmpty) {
      return SizedBox(
        width: cellSize,
        height: cellSize,
        child: _NotesGrid(notes: cellNotes, cellSize: cellSize),
      );
    }

    return const SizedBox.shrink();
  }
}

class _NumberCell extends StatelessWidget {
  const _NumberCell({
    required this.value,
    required this.isFixed,
    required this.isConflicted,
    required this.cellSize,
  });

  final int value;
  final bool isFixed;
  final bool isConflicted;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final fontSize = (cellSize * 0.38).clamp(11.0, 26.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value.toString(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: isFixed ? FontWeight.w700 : FontWeight.w600,
          color:
              isConflicted
                  ? Colors.redAccent
                  : (isDark ? Colors.white : AppThemeExtension.brandBlue),
          height: 1.0,
        ),
      ),
    );
  }
}

/// A clean 3x3 mini-grid of candidate notes, laid out with [Table] so every
/// slot gets an exact, equal share of the cell — no two notes can ever
/// collide, and each digit sits in the same spot regardless of which other
/// notes are present.
class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes, required this.cellSize});

  final Set<int> notes;
  final double cellSize;

  // grey.shade400 against the light-theme cell background (#FFFFFF) computes
  // to ~1.88:1 — well under the 4.5:1 WCAG 1.4.3 requires at this size.
  // Against the dark-theme background (#2C2C2C) the same grey is ~7.44:1,
  // comfortably fine, so only the light-theme value needs to change.
  static const Color _noteColorLight = Color(0xFF6B6B6B); // ~5.3:1 on white
  static const Color _noteColorDark = Color(0xFFBDBDBD); // grey.shade400

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final noteColor = isDark ? _noteColorDark : _noteColorLight;
    final unit = cellSize / AppConstants.subGridSize;
    final fontSize = (unit * 0.6).clamp(7.0, 13.0);

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FlexColumnWidth(),
      },
      children: List.generate(AppConstants.subGridSize, (r) {
        return TableRow(
          children: List.generate(AppConstants.subGridSize, (c) {
            final number = r * AppConstants.subGridSize + c + 1;
            final showNote = notes.contains(number);

            return SizedBox(
              height: unit,
              child:
                  showNote
                      ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: noteColor,
                            height: 1.0,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            );
          }),
        );
      }),
    );
  }
}
