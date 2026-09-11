import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

import '../../../../fakes/fake_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadCubeGame restores an in-progress cube session persisted by a previous session', () async {
    final storage = FakeStorageService();

    final containerA = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        audioServiceProvider.overrideWithValue(FakeAudioService()),
      ],
    );
    addTearDown(containerA.dispose);
    // cubeGameControllerProvider is autoDispose; a bare .read() doesn't
    // keep it alive across the awaits below, so pin it the same way the
    // app's own widgets (ref.watch) do.
    containerA.listen(cubeGameControllerProvider, (_, _) {});

    final controllerA = containerA.read(cubeGameControllerProvider.notifier);
    await controllerA.newCubeGame({
      for (final face in CubeFace.values) face: Difficulty.easy,
    });
    final stateA = containerA.read(cubeGameControllerProvider)!;
    final cubeIdA = stateA.cubeId;

    // A real move on one face, so autosave (per-move persistence) actually
    // writes, and on a different face too, so the round-trip has to
    // preserve more than one face's state.
    final frontState = stateA.faceState(CubeFace.front);
    int? emptyRow, emptyCol;
    outer:
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (frontState.puzzle.grid[r][c] == 0) {
          emptyRow = r;
          emptyCol = c;
          break outer;
        }
      }
    }
    // setActiveFace alone doesn't trigger a save (it's cheap UI navigation
    // state, not gameplay progress) — set it before the move below so the
    // move's own save captures both.
    controllerA.setActiveFace(CubeFace.back);
    controllerA.selectCell(CubeFace.front, emptyRow!, emptyCol!);
    controllerA.setValue(
      CubeFace.front,
      emptyRow,
      emptyCol,
      frontState.puzzle.solution[emptyRow][emptyCol],
    );
    await Future<void>.delayed(Duration.zero);

    final afterMoveA = containerA.read(cubeGameControllerProvider)!;
    final activeFaceA = afterMoveA.activeFace;
    final frontMistakesA = afterMoveA.faceState(CubeFace.front).mistakes;
    final frontUserValueA =
        afterMoveA.faceState(CubeFace.front).userGrid[emptyRow][emptyCol];

    // A fresh container over the same storage simulates a cold restart: a
    // brand new CubeGameController with no in-memory state.
    final containerB = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        audioServiceProvider.overrideWithValue(FakeAudioService()),
      ],
    );
    addTearDown(containerB.dispose);
    containerB.listen(cubeGameControllerProvider, (_, _) {});

    expect(containerB.read(cubeGameControllerProvider), isNull);

    await containerB.read(cubeGameControllerProvider.notifier).loadCubeGame();

    final restored = containerB.read(cubeGameControllerProvider);
    expect(restored, isNotNull);
    expect(restored!.cubeId, cubeIdA);
    expect(restored.activeFace, activeFaceA);
    expect(
      restored.faceState(CubeFace.front).userGrid[emptyRow][emptyCol],
      frontUserValueA,
    );
    expect(restored.faceState(CubeFace.front).mistakes, frontMistakesA);
    // Every face's own state round-trips, not just the one that was
    // actively played.
    for (final face in CubeFace.values) {
      expect(restored.faceState(face).difficulty, Difficulty.easy);
      expect(restored.faceState(face).puzzleId, stateA.faceState(face).puzzleId);
    }
  });
}
