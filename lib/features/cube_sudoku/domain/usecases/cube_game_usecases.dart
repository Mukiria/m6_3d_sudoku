import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/repositories/cube_game_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

class GenerateCubePuzzlesUseCase {
  GenerateCubePuzzlesUseCase(this._repository);

  final CubeGameRepository _repository;

  Future<Either<Failure, Map<CubeFace, Puzzle>>> call(
    Map<CubeFace, Difficulty> difficulties,
  ) {
    return _repository.generateCubePuzzles(difficulties);
  }
}

class GetCubeGameStateUseCase {
  GetCubeGameStateUseCase(this._repository);

  final CubeGameRepository _repository;

  Future<Either<Failure, CubeGameState?>> call() {
    return _repository.getCubeGameState();
  }
}

class SaveCubeGameStateUseCase {
  SaveCubeGameStateUseCase(this._repository);

  final CubeGameRepository _repository;

  Future<Either<Failure, void>> call(CubeGameState state) {
    return _repository.saveCubeGameState(state);
  }
}

class ClearCubeGameStateUseCase {
  ClearCubeGameStateUseCase(this._repository);

  final CubeGameRepository _repository;

  Future<Either<Failure, void>> call() {
    return _repository.clearCubeGameState();
  }
}
