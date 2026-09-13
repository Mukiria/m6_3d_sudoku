import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
class GameState with _$GameState {
  const factory GameState({
    required String puzzleId,
    required Puzzle puzzle,
    required List<List<int>> userGrid,
    required List<List<Set<int>>> notes,
    required int timeElapsed,
    required int mistakes,
    required int hintsUsed,
    required int penaltyTime,
    required List<Move> moveHistory,
    required List<Move> redoStack,
    required GameStatus status,
    required DateTime lastPlayed,
    required Difficulty difficulty,
    required CellPosition? selectedCell,
    required int? selectedNumber,
    required bool isNoteMode,
    required Set<CellPosition> highlightedCells,
    required Set<CellPosition> conflictCells,
    required HintState? hintState,
    required DateTime lastSaved,
    @Default(1) int saveVersion,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  /// Bumped whenever the persisted shape of [GameState] changes in a way
  /// that's not safely backward-compatible. [PuzzleLocalDataSource] discards
  /// any saved game whose `saveVersion` doesn't match this, rather than risk
  /// deserializing it into a broken state.
  static const int currentSaveVersion = 1;
}

@freezed
class HintState with _$HintState {
  const factory HintState({
    required HintType type,
    required CellPosition cell,
    required int value,
    required String explanation,
    required DateTime shownAt,
  }) = _HintState;

  factory HintState.fromJson(Map<String, dynamic> json) =>
      _$HintStateFromJson(json);
}

enum HintType {
  directReveal,
  nakedSingle,
  hiddenSingle,
  nakedPair,
  hiddenPair,
  pointingPair,
  boxLineReduction,
}

@freezed
class Move with _$Move {
  const factory Move({
    required int row,
    required int col,
    required int? previousValue,
    required int? newValue,
    required MoveType type,
    required DateTime timestamp,
  }) = _Move;

  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);
}

enum MoveType { value, note, hint, undo, clear, redo }

enum GameStatus { playing, paused, completed, failed }

@freezed
class CellPosition with _$CellPosition {
  const factory CellPosition({required int row, required int col}) =
      _CellPosition;

  factory CellPosition.fromJson(Map<String, dynamic> json) =>
      _$CellPositionFromJson(json);
}
