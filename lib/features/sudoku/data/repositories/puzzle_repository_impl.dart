import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/puzzle_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/puzzle_repository.dart';

class PuzzleRepositoryImpl implements PuzzleRepository {
  PuzzleRepositoryImpl(this._dataSource);

  final PuzzleLocalDataSource _dataSource;

  @override
  Future<Either<Failure, Puzzle>> generatePuzzle(String difficulty) {
    return _dataSource.generatePuzzle(difficulty);
  }

  @override
  Future<Either<Failure, Puzzle>> getPuzzle(String id) {
    return _dataSource.getCurrentPuzzle().then(
      (result) => result.fold(
        (failure) => Left(failure),
        (puzzle) =>
            puzzle != null
                ? Right(puzzle)
                : const Left(NotFoundFailure('Puzzle not found')),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> savePuzzle(Puzzle puzzle) {
    return _dataSource.savePuzzle(puzzle);
  }

  @override
  Future<Either<Failure, Puzzle?>> getCurrentPuzzle() {
    return _dataSource.getCurrentPuzzle();
  }

  @override
  Future<Either<Failure, void>> saveGameState(GameState state) {
    return _dataSource.saveGameState(state);
  }

  @override
  Future<Either<Failure, GameState?>> getGameState() {
    return _dataSource.getGameState();
  }

  @override
  Future<Either<Failure, void>> clearGameState() {
    return _dataSource.clearGameState();
  }

  @override
  Future<Either<Failure, List<Puzzle>>> getPuzzleHistory() {
    return _dataSource.getPuzzleHistory();
  }

  @override
  Future<Either<Failure, void>> savePuzzleToHistory(Puzzle puzzle) {
    return _dataSource.savePuzzleToHistory(puzzle);
  }
}
