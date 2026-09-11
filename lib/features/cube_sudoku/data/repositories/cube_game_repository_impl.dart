import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/cube_sudoku/data/datasources/cube_game_local_datasource.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/repositories/cube_game_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

class CubeGameRepositoryImpl implements CubeGameRepository {
  CubeGameRepositoryImpl(this._dataSource);

  final CubeGameLocalDataSource _dataSource;

  @override
  Future<Either<Failure, Map<CubeFace, Puzzle>>> generateCubePuzzles(
    Map<CubeFace, Difficulty> difficulties,
  ) {
    return _dataSource.generateCubePuzzles(difficulties);
  }

  @override
  Future<Either<Failure, CubeGameState?>> getCubeGameState() {
    return _dataSource.getCubeGameState();
  }

  @override
  Future<Either<Failure, void>> saveCubeGameState(CubeGameState state) {
    return _dataSource.saveCubeGameState(state);
  }

  @override
  Future<Either<Failure, void>> clearCubeGameState() {
    return _dataSource.clearCubeGameState();
  }
}
