import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/providers/cube_game_provider.dart';
import 'package:m6_sudoku/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

import '../../../../fakes/fake_services.dart';

/// StatisticsController kicks off an async storage read from its
/// constructor; reading statisticsProvider before that resolves would see
/// AsyncLoading and silently no-op any recordCube* call made in the
/// meantime (the same "drop if not yet loaded" behavior recordGame already
/// has) — so tests that assert on stats need to wait it out first.
Future<void> _awaitStatisticsLoaded(ProviderContainer container) async {
  var value = container.read(statisticsProvider);
  var attempts = 0;
  while (value is AsyncLoading && attempts < 50) {
    await Future<void>.delayed(Duration.zero);
    value = container.read(statisticsProvider);
    attempts++;
  }
  if (value.hasError) {
    fail(
      'statisticsProvider failed to load: ${value.error}\n${value.stackTrace}',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'completing all six faces flips isComplete exactly once, at the end, and feeds per-difficulty stats as each face completes',
    () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
      );
      addTearDown(container.dispose);
      // cubeGameControllerProvider/statisticsProvider are both autoDispose —
      // a plain container.read() alone doesn't keep them alive across a real
      // await point (no widget tree here holding a permanent ref.watch the
      // way the app does), so a stray gap between reads would silently
      // recreate them with fresh (null/loading) state. A permanent listener
      // is the standard way to pin an autoDispose provider for the life of a
      // test.
      container.listen(cubeGameControllerProvider, (_, _) {});
      container.listen(statisticsProvider, (_, _) {});
      await _awaitStatisticsLoaded(container);

      final controller = container.read(cubeGameControllerProvider.notifier);
      await controller.newCubeGame({
        for (final face in CubeFace.values) face: Difficulty.easy,
      });

      var state = container.read(cubeGameControllerProvider)!;
      expect(state.isComplete, false);
      expect(state.facesCompleted, 0);

      final faces = CubeFace.values.toList();
      for (var fi = 0; fi < faces.length; fi++) {
        final face = faces[fi];
        final faceState = state.faceState(face);
        final empties = <List<int>>[];
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (faceState.puzzle.grid[r][c] == 0) empties.add([r, c]);
          }
        }

        for (var i = 0; i < empties.length; i++) {
          final r = empties[i][0];
          final c = empties[i][1];
          final solutionValue = faceState.puzzle.solution[r][c];
          controller.setValue(face, r, c, solutionValue);

          final isLastCellOfFace = i == empties.length - 1;
          final isLastFace = fi == faces.length - 1;
          final after = container.read(cubeGameControllerProvider)!;

          if (isLastCellOfFace) {
            expect(
              after.faceState(face).status,
              GameStatus.completed,
              reason: '${face.name} should be completed after its last cell',
            );
            expect(after.facesCompleted, fi + 1);

            // recordCubeFaceCompletion fires synchronously inside setValue,
            // but persists via an unawaited Future — give it a tick to land
            // before asserting on statisticsProvider's state.
            await Future<void>.delayed(Duration.zero);
            final stats = container.read(statisticsProvider).value!;
            expect(
              stats.gamesPlayedByDifficulty['easy'],
              fi + 1,
              reason:
                  'each completed face should count immediately, not '
                  'wait for the whole cube',
            );
            expect(stats.gamesWonByDifficulty['easy'], fi + 1);
          }

          if (isLastCellOfFace && isLastFace) {
            expect(
              after.isComplete,
              true,
              reason: 'cube should be complete after the 6th face',
            );
          } else {
            expect(
              after.isComplete,
              false,
              reason:
                  'cube must not report complete before every face is done '
                  '(face ${face.name}, cell $i/${empties.length})',
            );
          }
        }

        state = container.read(cubeGameControllerProvider)!;
      }

      expect(state.facesCompleted, 6);
      expect(state.isComplete, true);

      // Cube-level completion (cubesCompleted, achievement evaluation) is
      // recorded from CubeCompletionScreen once the player actually reaches
      // it, not by the controller itself — verified separately at the
      // screen/use-case level, not here.
      final finalStats = container.read(statisticsProvider).value!;
      expect(finalStats.cubesCompleted, 0);
    },
  );

  test(
    'a face failing at 3 mistakes never blocks the other five from completing',
    () async {
      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(cubeGameControllerProvider, (_, _) {});
      container.listen(statisticsProvider, (_, _) {});

      final controller = container.read(cubeGameControllerProvider.notifier);
      await controller.newCubeGame({
        for (final face in CubeFace.values) face: Difficulty.easy,
      });

      var state = container.read(cubeGameControllerProvider)!;
      const failFace = CubeFace.front;
      final failFaceState = state.faceState(failFace);
      var wrongsGiven = 0;
      for (var r = 0; r < 9 && wrongsGiven < 3; r++) {
        for (var c = 0; c < 9 && wrongsGiven < 3; c++) {
          if (failFaceState.puzzle.grid[r][c] != 0) continue;
          final correct = failFaceState.puzzle.solution[r][c];
          final wrong = correct == 9 ? 1 : correct + 1;
          controller.setValue(failFace, r, c, wrong);
          wrongsGiven++;
        }
      }

      state = container.read(cubeGameControllerProvider)!;
      expect(state.faceState(failFace).status, GameStatus.failed);
      expect(state.faceState(failFace).mistakes, 3);

      for (final face in CubeFace.values.where((f) => f != failFace)) {
        final faceState = state.faceState(face);
        for (var r = 0; r < 9; r++) {
          for (var c = 0; c < 9; c++) {
            if (faceState.puzzle.grid[r][c] == 0) {
              controller.setValue(face, r, c, faceState.puzzle.solution[r][c]);
            }
          }
        }
        state = container.read(cubeGameControllerProvider)!;
        expect(state.faceState(face).status, GameStatus.completed);
      }

      expect(state.facesCompleted, 5);
      expect(
        state.isComplete,
        false,
        reason:
            'a failed face should permanently block cube completion until retried',
      );
    },
  );
}
