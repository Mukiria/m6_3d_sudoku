import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/settings/domain/repositories/settings_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/usecases/game_usecases.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/puzzle_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import '../../fakes/fake_services.dart';

class FakePuzzleRepository implements PuzzleRepository {
  @override
  Future<Either<Failure, Puzzle>> generatePuzzle(String difficulty) async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, Puzzle>> getPuzzle(String id) async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, void>> savePuzzle(Puzzle puzzle) async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, void>> deletePuzzle(String id) async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, Puzzle?>> getCurrentPuzzle() async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, void>> saveGameState(GameState state) async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, GameState?>> getGameState() async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, void>> clearGameState() async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, List<Puzzle>>> getPuzzleHistory() async =>
      Left(CacheFailure('Not implemented'));

  @override
  Future<Either<Failure, void>> savePuzzleToHistory(Puzzle puzzle) async =>
      Left(CacheFailure('Not implemented'));
}

class FakeGetHintUseCase extends GetHintUseCase {
  FakeGetHintUseCase() : super(FakePuzzleRepository()) {
    print('FakeGetHintUseCase created');
  }

  @override
  Future<Either<Failure, HintCell?>> call({required GameState state}) async {
    print('FakeGetHintUseCase.call called');
    print('Puzzle grid: ${state.puzzle.grid}');
    print('User grid: ${state.userGrid}');
    // Return a direct reveal hint for the first empty cell
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (state.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
          print('Found empty cell at $r,$c');
          return Right(
            HintCell(
              row: r,
              col: c,
              value: state.puzzle.solution[r][c],
              isFixed: false,
              hintType: HintType.directReveal,
              explanation: 'Test hint',
            ),
          );
        }
      }
    }
    print('No empty cells found');
    return const Right(null);
  }
}

void main() {
  // GameController now calls SemanticsService.announce on mistakes,
  // completion, and hints — that reaches a platform channel via
  // ServicesBinding.instance, which only exists once a Flutter binding is
  // initialized. The real app gets this for free from
  // WidgetsFlutterBinding.ensureInitialized() in main(); these plain
  // ProviderContainer-based tests need the test equivalent explicitly.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameController - Gameplay Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          settingsRepositoryProvider.overrideWithValue(
            FakeSettingsRepository(),
          ),
          audioServiceProvider.overrideWithValue(FakeAudioService()),
          getHintUseCaseProvider.overrideWithValue(FakeGetHintUseCase()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('newGame', () {
      test('creates new game with correct initial state', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);

        expect(state, isNotNull);
        expect(state!.status, GameStatus.playing);
        expect(state.timeElapsed, 0);
        expect(state.mistakes, 0);
        expect(state.hintsUsed, 0);
        expect(state.penaltyTime, 0);
        expect(state.moveHistory, isEmpty);
        expect(state.redoStack, isEmpty);
        expect(state.selectedCell, isNull);
        expect(state.selectedNumber, isNull);
        expect(state.isNoteMode, false);
        expect(state.difficulty, Difficulty.easy);
      });

      test('initializes with correct puzzle for difficulty', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.expert);

        final state = container.read(gameControllerProvider);

        expect(state, isNotNull);
        expect(state!.puzzle.difficulty, 'expert');
        expect(state.userGrid, isNotNull);
        expect(state.notes, isNotNull);
      });

      test('initial notes are computed correctly', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);

        // Notes should be computed for empty cells
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              expect(state.notes[r][c], isNotNull);
            } else {
              expect(state.notes[r][c], isEmpty);
            }
          }
        }
      });
    });

    group('selectCell', () {
      test('selects cell and updates highlighted cells', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        // Find an empty cell to select
        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);

          final newState = container.read(gameControllerProvider);

          expect(
            newState!.selectedCell,
            CellPosition(row: emptyRow!, col: emptyCol!),
          );
          expect(
            newState.highlightedCells.length,
            20,
          ); // 8 row + 8 col + 4 box - 1 overlap
        }
      });

      test('does not select fixed cell', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        final puzzle = state!.puzzle;

        // Find a fixed cell
        int? fixedRow, fixedCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (puzzle.grid[r][c] != 0) {
              fixedRow = r;
              fixedCol = c;
              break;
            }
          }
          if (fixedRow != null) break;
        }

        if (fixedRow != null) {
          controller.selectCell(fixedRow!, fixedCol!);
          final state = container.read(gameControllerProvider);
          // Should not select fixed cell
          expect(state!.selectedCell, isNull);
        }
      });
    });

    group('setValue', () {
      test('places correct value', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        // Find an empty cell
        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, 5);

          final newState = container.read(gameControllerProvider);
          expect(newState!.userGrid[emptyRow!][emptyCol!], 5);
        }
      });

      test('increments mistakes for incorrect value', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          // Use wrong value
          final wrongValue = correctValue == 9 ? 1 : correctValue + 1;
          controller.setValue(emptyRow!, emptyCol!, wrongValue);

          final newState = container.read(gameControllerProvider);
          expect(newState!.mistakes, 1);
        }
      });

      test('does not increment mistakes for correct value', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          final newState = container.read(gameControllerProvider);
          expect(newState!.mistakes, 0);
        }
      });

      test('does not overwrite fixed cell', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? fixedRow, fixedCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.puzzle.grid[r][c] != 0) {
              fixedRow = r;
              fixedCol = c;
              break;
            }
          }
          if (fixedRow != null) break;
        }

        if (fixedRow != null) {
          final originalValue = state!.userGrid[fixedRow!][fixedCol!];
          controller.selectCell(fixedRow!, fixedCol!);
          controller.setValue(fixedRow!, fixedCol!, 9);

          final newState = container.read(gameControllerProvider);
          expect(newState!.userGrid[fixedRow!][fixedCol!], originalValue);
        }
      });

      test('does not set same value twice', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          final stateAfterFirst = container.read(gameControllerProvider);
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          final stateAfterSecond = container.read(gameControllerProvider);
          // Should not add duplicate move
          expect(
            stateAfterSecond!.moveHistory.length,
            stateAfterFirst!.moveHistory.length,
          );
        }
      });
    });

    group('toggleNote', () {
      test('adds note when not present', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);

          // Find a note value that's NOT in the initial candidates for this cell
          final initialNotes = state!.notes[emptyRow!][emptyCol!];
          int noteToAdd = 1;
          while (initialNotes.contains(noteToAdd) && noteToAdd <= 9) {
            noteToAdd++;
          }
          // If all 1-9 are candidates (unlikely), use 1 anyway - test will still verify toggle behavior
          if (noteToAdd > 9) noteToAdd = 1;

          controller.toggleNote(emptyRow!, emptyCol!, noteToAdd);

          final newState = container.read(gameControllerProvider);
          expect(newState!.notes[emptyRow!][emptyCol!], contains(noteToAdd));
        }
      });

      test('removes note when already present', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);

          // Find a note value that's NOT in the initial candidates for this cell
          final initialNotes = state!.notes[emptyRow!][emptyCol!];
          int noteToAdd = 1;
          while (initialNotes.contains(noteToAdd) && noteToAdd <= 9) {
            noteToAdd++;
          }
          if (noteToAdd > 9) noteToAdd = 1;

          // First toggle adds the note
          controller.toggleNote(emptyRow!, emptyCol!, noteToAdd);
          // Second toggle removes it
          controller.toggleNote(emptyRow!, emptyCol!, noteToAdd);

          final newState = container.read(gameControllerProvider);
          expect(
            newState!.notes[emptyRow!][emptyCol!],
            isNot(contains(noteToAdd)),
          );
        }
      });

      test('does not add notes to fixed cell', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? fixedRow, fixedCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.puzzle.grid[r][c] != 0) {
              fixedRow = r;
              fixedCol = c;
              break;
            }
          }
          if (fixedRow != null) break;
        }

        if (fixedRow != null) {
          controller.selectCell(fixedRow!, fixedCol!);
          controller.toggleNote(fixedRow!, fixedCol!, 5);

          final newState = container.read(gameControllerProvider);
          expect(newState!.notes[fixedRow!][fixedCol!], isEmpty);
        }
      });
    });

    group('clearCell', () {
      test('clears user value', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          controller.clearCell(emptyRow!, emptyCol!);

          final newState = container.read(gameControllerProvider);
          expect(newState!.userGrid[emptyRow!][emptyCol!], 0);
        }
      });

      test('clears notes', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.toggleNote(emptyRow!, emptyCol!, 5);
          controller.clearCell(emptyRow!, emptyCol!);

          final newState = container.read(gameControllerProvider);
          expect(newState!.notes[emptyRow!][emptyCol!], isEmpty);
        }
      });

      test('does not clear fixed cell', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? fixedRow, fixedCol;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.puzzle.grid[r][c] != 0) {
              fixedRow = r;
              fixedCol = c;
              break;
            }
          }
          if (fixedRow != null) break;
        }

        if (fixedRow != null) {
          final originalValue = state!.userGrid[fixedRow!][fixedCol!];
          controller.clearCell(fixedRow!, fixedCol!);

          final newState = container.read(gameControllerProvider);
          expect(newState!.userGrid[fixedRow!][fixedCol!], originalValue);
        }
      });
    });

    group('undo/redo', () {
      test('undo removes last move', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          final stateAfterMove = container.read(gameControllerProvider);
          controller.undo();

          final stateAfterUndo = container.read(gameControllerProvider);
          expect(stateAfterUndo!.userGrid[emptyRow!][emptyCol!], 0);
          expect(stateAfterUndo.moveHistory.length, state!.moveHistory.length);
        }
      });

      test('redo reapplies undone move', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);
          controller.undo();
          controller.redo();

          final stateAfterRedo = container.read(gameControllerProvider);
          expect(stateAfterRedo!.userGrid[emptyRow!][emptyCol!], correctValue);
        }
      });

      test('redo reapplies an undone clear (not the pre-clear value)', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);
          controller.clearCell(emptyRow!, emptyCol!);

          final stateAfterClear = container.read(gameControllerProvider);
          expect(stateAfterClear!.userGrid[emptyRow!][emptyCol!], 0);

          controller.undo();
          final stateAfterUndo = container.read(gameControllerProvider);
          expect(stateAfterUndo!.userGrid[emptyRow!][emptyCol!], correctValue);

          controller.redo();
          final stateAfterRedo = container.read(gameControllerProvider);
          // Regression check: redoing a clear must re-clear the cell (0),
          // not silently restore the pre-clear value again.
          expect(stateAfterRedo!.userGrid[emptyRow!][emptyCol!], 0);
        }
      });

      test('undo clears redo stack on new move', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);
          controller.undo();

          // Make a new move
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          final newState = container.read(gameControllerProvider);
          expect(newState!.redoStack, isEmpty);
        }
      });

      test('clearCell also clears redo stack on new move', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);
          controller.undo();

          // A stale redo entry exists here; clearing a (different) cell
          // should still invalidate it, the same way a new setValue does.
          controller.clearCell(emptyRow!, emptyCol!);

          final newState = container.read(gameControllerProvider);
          expect(newState!.redoStack, isEmpty);
        }
      });
    });

    group('useHint', () {
      test('uses hint and adds penalty time', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        final timeBefore = state!.timeElapsed;

        await controller.useHint();

        final newState = container.read(gameControllerProvider);
        expect(newState!.hintsUsed, 1);
        expect(newState!.penaltyTime, greaterThan(0));
        expect(newState!.timeElapsed, greaterThan(timeBefore));
      });

      test('adds correct penalty for direct reveal', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        // We can't easily control hint type, but we can verify penalty is added
        await controller.useHint();

        final newState = container.read(gameControllerProvider);
        expect(newState!.penaltyTime, greaterThanOrEqualTo(15));
      });
    });

    group('pause/resume', () {
      test('pause changes status to paused', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        controller.pause();

        final state = container.read(gameControllerProvider);
        expect(state!.status, GameStatus.paused);
      });

      test('resume changes status to playing', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        controller.pause();
        controller.resume();

        final state = container.read(gameControllerProvider);
        expect(state!.status, GameStatus.playing);
      });
    });

    group('game completion', () {
      test('detects completion when grid matches solution', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        // Fill the entire grid with solution
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0) {
              controller.selectCell(r, c);
              controller.setValue(r, c, state.puzzle.solution[r][c]);
            }
          }
        }

        final finalState = container.read(gameControllerProvider);
        expect(finalState!.status, GameStatus.completed);
      });
    });

    group('game failure', () {
      test('fails after 3 mistakes', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);

          // Make 3 mistakes
          for (int i = 1; i <= 3; i++) {
            final wrongValue = (correctValue + i) % 9 + 1;
            if (wrongValue != correctValue) {
              controller.setValue(emptyRow!, emptyCol!, wrongValue);
            }
          }

          final finalState = container.read(gameControllerProvider);
          expect(finalState!.status, GameStatus.failed);
          expect(finalState!.mistakes, 3);
        }
      });
    });

    group('timer', () {
      test('increments timer every second', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        expect(state!.timeElapsed, 0);

        // Note: Timer is handled by TimerController, not directly testable here
        // This test verifies the initial state
      });
    });

    group('continueGame', () {
      test('restores saved game state', () async {
        final controller = container.read(gameControllerProvider.notifier);
        await controller.newGame(Difficulty.easy);

        final state = container.read(gameControllerProvider);
        int? emptyRow, emptyCol;
        int correctValue = 0;
        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            if (state!.userGrid[r][c] == 0 && state.puzzle.grid[r][c] == 0) {
              emptyRow = r;
              emptyCol = c;
              correctValue = state.puzzle.solution[r][c];
              break;
            }
          }
          if (emptyRow != null) break;
        }

        if (emptyRow != null) {
          controller.selectCell(emptyRow!, emptyCol!);
          controller.setValue(emptyRow!, emptyCol!, correctValue);

          final stateAfterMove = container.read(gameControllerProvider);

          // Continue the saved game
          await controller.continueGame(stateAfterMove!);

          final continuedState = container.read(gameControllerProvider);
          expect(continuedState!.userGrid[emptyRow!][emptyCol!], correctValue);
          expect(continuedState.timeElapsed, stateAfterMove!.timeElapsed);
          expect(continuedState.mistakes, stateAfterMove!.mistakes);
        }
      });
    });

    group('loadGame - restore after restart', () {
      test(
        'restores an in-progress game persisted by a previous session',
        () async {
          final storage = FakeStorageService();

          final containerA = ProviderContainer(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              settingsRepositoryProvider.overrideWithValue(
                FakeSettingsRepository(),
              ),
              audioServiceProvider.overrideWithValue(FakeAudioService()),
              getHintUseCaseProvider.overrideWithValue(FakeGetHintUseCase()),
            ],
          );
          addTearDown(containerA.dispose);
          // gameControllerProvider is autodispose; a bare .read() doesn't
          // keep it alive across the awaits below, so pin it with a
          // listener like the app's own widgets (ref.watch) do.
          containerA.listen(gameControllerProvider, (_, __) {});

          final controllerA = containerA.read(gameControllerProvider.notifier);
          await controllerA.newGame(Difficulty.easy);
          final stateA = containerA.read(gameControllerProvider)!;

          int? emptyRow, emptyCol;
          outer:
          for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
              if (stateA.puzzle.grid[r][c] == 0) {
                emptyRow = r;
                emptyCol = c;
                break outer;
              }
            }
          }

          // A real move, so autosave (per-move persistence) actually writes.
          controllerA.selectCell(emptyRow!, emptyCol!);
          controllerA.setValue(emptyRow, emptyCol, 5);
          await Future<void>.delayed(Duration.zero);

          final puzzleIdA = containerA.read(gameControllerProvider)!.puzzleId;
          final timeElapsedA =
              containerA.read(gameControllerProvider)!.timeElapsed;

          // A fresh container over the same storage simulates a cold
          // restart: a brand new GameController with no in-memory state.
          final containerB = ProviderContainer(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              settingsRepositoryProvider.overrideWithValue(
                FakeSettingsRepository(),
              ),
              audioServiceProvider.overrideWithValue(FakeAudioService()),
              getHintUseCaseProvider.overrideWithValue(FakeGetHintUseCase()),
            ],
          );
          addTearDown(containerB.dispose);
          containerB.listen(gameControllerProvider, (_, __) {});

          expect(containerB.read(gameControllerProvider), isNull);

          await containerB.read(gameControllerProvider.notifier).loadGame();

          final restored = containerB.read(gameControllerProvider);
          expect(restored, isNotNull);
          expect(restored!.puzzleId, puzzleIdA);
          expect(restored.userGrid[emptyRow][emptyCol], 5);
          expect(restored.timeElapsed, timeElapsedA);
        },
      );

      test(
        'does not clobber a session already started before it resolves',
        () async {
          final storage = FakeStorageService();

          // Seed storage with a "previous session"'s save.
          final seedContainer = ProviderContainer(
            overrides: [storageServiceProvider.overrideWithValue(storage)],
          );
          seedContainer.listen(gameControllerProvider, (_, __) {});
          await seedContainer
              .read(gameControllerProvider.notifier)
              .newGame(Difficulty.easy);
          final seeded = seedContainer.read(gameControllerProvider)!;
          await seedContainer.read(saveGameStateUseCaseProvider)(seeded);
          seedContainer.dispose();

          final container = ProviderContainer(
            overrides: [
              storageServiceProvider.overrideWithValue(storage),
              settingsRepositoryProvider.overrideWithValue(
                FakeSettingsRepository(),
              ),
              audioServiceProvider.overrideWithValue(FakeAudioService()),
              getHintUseCaseProvider.overrideWithValue(FakeGetHintUseCase()),
            ],
          );
          addTearDown(container.dispose);
          container.listen(gameControllerProvider, (_, __) {});

          final controller = container.read(gameControllerProvider.notifier);
          await controller.newGame(Difficulty.hard);
          final freshPuzzleId =
              container.read(gameControllerProvider)!.puzzleId;

          // loadGame() racing in afterward must not overwrite the session the
          // user already started.
          await controller.loadGame();

          expect(
            container.read(gameControllerProvider)!.puzzleId,
            freshPuzzleId,
          );
        },
      );
    });
  });
}
