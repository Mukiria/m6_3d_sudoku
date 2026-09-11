import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

abstract class CubeGameRepository {
  /// Generates one puzzle per face at its chosen [difficulties] entry, all
  /// in parallel.
  Future<Either<Failure, Map<CubeFace, Puzzle>>> generateCubePuzzles(
    Map<CubeFace, Difficulty> difficulties,
  );

  Future<Either<Failure, CubeGameState?>> getCubeGameState();

  Future<Either<Failure, void>> saveCubeGameState(CubeGameState state);

  Future<Either<Failure, void>> clearCubeGameState();
}
