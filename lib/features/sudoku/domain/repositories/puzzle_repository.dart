import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';

abstract class PuzzleRepository {
  Future<Either<Failure, Puzzle>> generatePuzzle(String difficulty);

  Future<Either<Failure, Puzzle>> getPuzzle(String id);

  Future<Either<Failure, void>> savePuzzle(Puzzle puzzle);

  Future<Either<Failure, Puzzle?>> getCurrentPuzzle();

  Future<Either<Failure, void>> saveGameState(GameState state);

  Future<Either<Failure, GameState?>> getGameState();

  Future<Either<Failure, void>> clearGameState();

  Future<Either<Failure, List<Puzzle>>> getPuzzleHistory();

  Future<Either<Failure, void>> savePuzzleToHistory(Puzzle puzzle);
}
