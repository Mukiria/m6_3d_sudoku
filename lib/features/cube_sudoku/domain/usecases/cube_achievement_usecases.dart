import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

/// Which cube-specific achievements unlock or progress on a completed
/// six-face cube, and by how much — the cube counterpart to
/// EvaluateAchievementDeltasUseCase, evaluated once the whole cube is
/// done rather than per face (each face's own difficulty already feeds
/// the shared per-difficulty stats separately — see
/// CubeGameController.setValue).
class EvaluateCubeAchievementDeltasUseCase {
  EvaluateCubeAchievementDeltasUseCase();

  /// Every achievement [completedState] should progress, as id → delta.
  /// Pure and synchronous — callers are expected to apply the result in one
  /// batched write (see IncrementAchievementProgressBatchUseCase) rather
  /// than one write per achievement. Only meaningful once
  /// [CubeGameState.isComplete] is true; callers are expected to guard on
  /// that before invoking this.
  Map<String, int> call(CubeGameState completedState) {
    final totalMistakes = CubeFace.values.fold<int>(
      0,
      (sum, face) => sum + completedState.faceState(face).mistakes,
    );
    final totalHints = CubeFace.values.fold<int>(
      0,
      (sum, face) => sum + completedState.faceState(face).hintsUsed,
    );
    final allEvil = CubeFace.values.every(
      (face) => completedState.faceState(face).difficulty == Difficulty.evil,
    );

    return <String, int>{
      // Cube Master
      'first_cube': 1,

      // Flawless Cube (0 mistakes, 0 hints across every face)
      if (totalMistakes == 0 && totalHints == 0) 'flawless_cube': 1,

      // Speed Cuber (whole cube under 20 minutes)
      if (completedState.timeElapsed < 1200) 'speed_cuber': 1,

      // Evil Six (secret) - every face solved at Evil difficulty
      if (allEvil) 'evil_cube': 1,
    };
  }
}
