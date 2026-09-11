import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/puzzle_repository.dart';
import 'package:m6_sudoku/features/sudoku/engine/candidates.dart';

class HintCell {
  const HintCell({
    required this.row,
    required this.col,
    required this.value,
    required this.isFixed,
    required this.hintType,
    required this.explanation,
  });

  final int row;
  final int col;
  final int value;
  final bool isFixed;
  final HintType hintType;
  final String explanation;
}

class GeneratePuzzleUseCase {
  GeneratePuzzleUseCase(this._repository);

  final PuzzleRepository _repository;

  Future<Either<Failure, Puzzle>> call(String difficulty) {
    return _repository.generatePuzzle(difficulty);
  }
}

class ValidateMoveUseCase {
  ValidateMoveUseCase();

  Either<Failure, bool> call({
    required List<List<int>> grid,
    required int row,
    required int col,
    required int value,
  }) {
    if (value < 1 || value > 9) {
      return const Left(ValidationFailure('Value must be between 1 and 9'));
    }

    if (row < 0 || row >= 9 || col < 0 || col >= 9) {
      return const Left(ValidationFailure('Invalid cell position'));
    }

    if (grid[row][col] != 0) {
      return const Left(ValidationFailure('Cell is already filled'));
    }

    for (int c = 0; c < 9; c++) {
      if (c != col && grid[row][c] == value) {
        return const Right(false);
      }
    }

    for (int r = 0; r < 9; r++) {
      if (r != row && grid[r][col] == value) {
        return const Right(false);
      }
    }

    final startRow = (row ~/ 3) * 3;
    final startCol = (col ~/ 3) * 3;

    for (int r = startRow; r < startRow + 3; r++) {
      for (int c = startCol; c < startCol + 3; c++) {
        if (r != row && c != col && grid[r][c] == value) {
          return const Right(false);
        }
      }
    }

    return const Right(true);
  }
}

class CheckCompletionUseCase {
  CheckCompletionUseCase();

  Either<Failure, bool> call({
    required List<List<int>> grid,
    required List<List<int>> solution,
  }) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (grid[r][c] != solution[r][c]) {
          return const Right(false);
        }
      }
    }
    return const Right(true);
  }
}

class GetHintUseCase {
  GetHintUseCase(this._repository);

  final PuzzleRepository _repository;

  Future<Either<Failure, HintCell?>> call({required GameState state}) async {
    final puzzle = state.puzzle;
    // Computed once per call (bitmask sweep — see engine/candidates.dart)
    // instead of re-deriving each cell's candidates from scratch on every
    // lookup inside the naked/hidden-single scans below.
    final candidateGrid = computeCandidateGrid(state.userGrid, puzzle.grid);

    // First try to find a logical hint (naked single)
    final logicalHint = _findNakedSingle(state, candidateGrid);
    if (logicalHint != null) {
      return Right(logicalHint);
    }

    // Then try hidden single
    final hiddenHint = _findHiddenSingle(state, candidateGrid);
    if (hiddenHint != null) {
      return Right(hiddenHint);
    }

    // Fallback to direct reveal
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (state.userGrid[r][c] == 0 && puzzle.grid[r][c] == 0) {
          final solutionValue = puzzle.solution[r][c];
          return Right(
            HintCell(
              row: r,
              col: c,
              value: solutionValue,
              isFixed: false,
              hintType: HintType.directReveal,
              explanation: 'The solution value for this cell is $solutionValue',
            ),
          );
        }
      }
    }
    return const Right(null);
  }

  HintCell? _findNakedSingle(
    GameState state,
    List<List<Set<int>>> candidateGrid,
  ) {
    final puzzle = state.puzzle;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (state.userGrid[r][c] == 0 && puzzle.grid[r][c] == 0) {
          final candidates = candidateGrid[r][c];
          if (candidates.length == 1) {
            return HintCell(
              row: r,
              col: c,
              value: candidates.first,
              isFixed: false,
              hintType: HintType.nakedSingle,
              explanation:
                  'This cell can only be ${candidates.first} (naked single)',
            );
          }
        }
      }
    }
    return null;
  }

  HintCell? _findHiddenSingle(
    GameState state,
    List<List<Set<int>>> candidateGrid,
  ) {
    final puzzle = state.puzzle;
    // Check rows
    for (int r = 0; r < 9; r++) {
      for (int digit = 1; digit <= 9; digit++) {
        int count = 0;
        int? lastCol;
        for (int c = 0; c < 9; c++) {
          if (state.userGrid[r][c] == 0 && puzzle.grid[r][c] == 0) {
            final candidates = candidateGrid[r][c];
            if (candidates.contains(digit)) {
              count++;
              lastCol = c;
            }
          }
        }
        if (count == 1 && lastCol != null) {
          return HintCell(
            row: r,
            col: lastCol,
            value: digit,
            isFixed: false,
            hintType: HintType.hiddenSingle,
            explanation:
                'Digit $digit can only go in this cell in this row (hidden single)',
          );
        }
      }
    }
    // Check columns
    for (int c = 0; c < 9; c++) {
      for (int digit = 1; digit <= 9; digit++) {
        int count = 0;
        int? lastRow;
        for (int r = 0; r < 9; r++) {
          if (state.userGrid[r][c] == 0 && puzzle.grid[r][c] == 0) {
            final candidates = candidateGrid[r][c];
            if (candidates.contains(digit)) {
              count++;
              lastRow = r;
            }
          }
        }
        if (count == 1 && lastRow != null) {
          return HintCell(
            row: lastRow,
            col: c,
            value: digit,
            isFixed: false,
            hintType: HintType.hiddenSingle,
            explanation:
                'Digit $digit can only go in this cell in this column (hidden single)',
          );
        }
      }
    }
    // Check boxes
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        for (int digit = 1; digit <= 9; digit++) {
          int count = 0;
          int? lastR, lastC;
          for (int r = 0; r < 3; r++) {
            for (int c = 0; c < 3; c++) {
              final cellR = boxRow * 3 + r;
              final cellC = boxCol * 3 + c;
              if (state.userGrid[cellR][cellC] == 0 &&
                  puzzle.grid[cellR][cellC] == 0) {
                final candidates = candidateGrid[cellR][cellC];
                if (candidates.contains(digit)) {
                  count++;
                  lastR = cellR;
                  lastC = cellC;
                }
              }
            }
          }
          if (count == 1 && lastR != null && lastC != null) {
            return HintCell(
              row: lastR,
              col: lastC,
              value: digit,
              isFixed: false,
              hintType: HintType.hiddenSingle,
              explanation:
                  'Digit $digit can only go in this cell in this box (hidden single)',
            );
          }
        }
      }
    }
    return null;
  }

}

class GetGameStateUseCase {
  GetGameStateUseCase(this._repository);

  final PuzzleRepository _repository;

  Future<Either<Failure, GameState?>> call() {
    return _repository.getGameState();
  }
}

class SaveGameStateUseCase {
  SaveGameStateUseCase(this._repository);

  final PuzzleRepository _repository;

  Future<Either<Failure, void>> call(GameState state) {
    return _repository.saveGameState(state);
  }
}
