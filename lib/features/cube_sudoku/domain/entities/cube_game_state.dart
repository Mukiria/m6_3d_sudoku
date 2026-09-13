import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';

part 'cube_game_state.freezed.dart';
part 'cube_game_state.g.dart';

@freezed
class CubeGameState with _$CubeGameState {
  const factory CubeGameState({
    required String cubeId,
    // Keyed by CubeFace.name rather than CubeFace itself — json_serializable
    // handles a plain enum field natively, but an enum-keyed Map is enough
    // of an edge case in codegen that keying by the already-stable `.name`
    // string sidesteps it entirely. Use [faceState]/[withFaceState] rather
    // than indexing this directly.
    required Map<String, GameState> faceStates,
    required CubeFace activeFace,
    // One shared clock for the whole cube session, rather than one per
    // face — mirrors how a single [GameState.timeElapsed] already works for
    // the regular game.
    required int timeElapsed,
    required DateTime lastPlayed,
    required DateTime lastSaved,
    @Default(1) int saveVersion,
  }) = _CubeGameState;

  factory CubeGameState.fromJson(Map<String, dynamic> json) =>
      _$CubeGameStateFromJson(json);

  const CubeGameState._();

  /// Bumped whenever the persisted shape of [CubeGameState] changes in a way
  /// that's not safely backward-compatible — mirrors
  /// [GameState.currentSaveVersion]'s role for the regular single-puzzle
  /// save. [CubeGameLocalDataSource] discards any saved cube session whose
  /// `saveVersion` doesn't match this, rather than risk deserializing it
  /// into a broken state.
  static const int currentSaveVersion = 1;

  GameState faceState(CubeFace face) => faceStates[face.name]!;

  CubeGameState withFaceState(CubeFace face, GameState state) {
    return copyWith(faceStates: {...faceStates, face.name: state});
  }

  GameState get activeFaceState => faceState(activeFace);

  bool get isComplete =>
      faceStates.values.every((s) => s.status == GameStatus.completed);

  int get facesCompleted =>
      faceStates.values.where((s) => s.status == GameStatus.completed).length;
}
