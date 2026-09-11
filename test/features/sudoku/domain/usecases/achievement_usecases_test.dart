import 'package:flutter_test/flutter_test.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/puzzle.dart';
import 'package:m6_sudoku/features/sudoku/domain/usecases/achievement_usecases.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';

GameState _completedState({
  Difficulty difficulty = Difficulty.medium,
  int timeElapsed = 300,
  int mistakes = 0,
  int hintsUsed = 0,
}) {
  final grid = List.generate(9, (_) => List.generate(9, (_) => 0));
  final puzzle = Puzzle(
    id: 'test',
    grid: grid,
    solution: grid,
    difficulty: difficulty.name,
    cluesCount: 0,
    createdAt: DateTime(2026, 1, 1),
  );
  return GameState(
    puzzleId: puzzle.id,
    puzzle: puzzle,
    userGrid: grid,
    notes: List.generate(9, (_) => List.generate(9, (_) => <int>{})),
    timeElapsed: timeElapsed,
    mistakes: mistakes,
    hintsUsed: hintsUsed,
    penaltyTime: 0,
    moveHistory: const [],
    redoStack: const [],
    status: GameStatus.completed,
    lastPlayed: DateTime(2026, 1, 1),
    difficulty: difficulty,
    selectedCell: null,
    selectedNumber: null,
    isNoteMode: false,
    highlightedCells: const {},
    conflictCells: const {},
    hintState: null,
    lastSaved: DateTime(2026, 1, 1),
  );
}

void main() {
  group('EvaluateAchievementDeltasUseCase', () {
    final useCase = EvaluateAchievementDeltasUseCase();

    test('always credits the base win achievements', () {
      final deltas = useCase(
        _completedState(),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(deltas['first_win'], 1);
      expect(deltas['ten_wins'], 1);
      expect(deltas['hundred_wins'], 1);
    });

    test('credits perfect-game achievements only with 0 mistakes and 0 hints', () {
      final perfect = useCase(
        _completedState(mistakes: 0, hintsUsed: 0),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(perfect['perfect_game'], 1);
      expect(perfect['five_perfect'], 1);

      final imperfect = useCase(
        _completedState(mistakes: 1, hintsUsed: 0),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(imperfect['perfect_game'], isNull);
      expect(imperfect['five_perfect'], isNull);
    });

    test('credits no-hints achievements only when hintsUsed is 0', () {
      final noHints = useCase(
        _completedState(hintsUsed: 0),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(noHints['no_hints'], 1);
      expect(noHints['ten_no_hints'], 1);

      final withHints = useCase(
        _completedState(hintsUsed: 1),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(withHints['no_hints'], isNull);
      expect(withHints['ten_no_hints'], isNull);
    });

    test('credits expert_winner only on expert difficulty', () {
      final expert = useCase(
        _completedState(difficulty: Difficulty.expert),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(expert['expert_winner'], 1);
      expect(expert['evil_conqueror'], isNull);

      final medium = useCase(
        _completedState(difficulty: Difficulty.medium),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(medium['expert_winner'], isNull);
    });

    test('credits evil_conqueror only on evil difficulty', () {
      final evil = useCase(
        _completedState(difficulty: Difficulty.evil),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(evil['evil_conqueror'], 1);
      expect(evil['expert_winner'], isNull);
    });

    test('credits speed_runner under 180 seconds, not at or above', () {
      final fast = useCase(
        _completedState(timeElapsed: 179),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(fast['speed_runner'], 1);

      final slow = useCase(
        _completedState(timeElapsed: 180),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(slow['speed_runner'], isNull);
    });

    test('credits lightning only for easy under 60 seconds', () {
      final lightning = useCase(
        _completedState(difficulty: Difficulty.easy, timeElapsed: 59),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(lightning['lightning'], 1);

      final notEasy = useCase(
        _completedState(difficulty: Difficulty.medium, timeElapsed: 59),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(notEasy['lightning'], isNull);

      final tooSlow = useCase(
        _completedState(difficulty: Difficulty.easy, timeElapsed: 60),
        now: DateTime(2026, 1, 1, 12),
      );
      expect(tooSlow['lightning'], isNull);
    });

    test('credits night_owl between midnight and 4am', () {
      final midnight = useCase(_completedState(), now: DateTime(2026, 1, 1, 0));
      expect(midnight['night_owl'], 1);
      expect(midnight['early_bird'], isNull);

      final threeAm = useCase(_completedState(), now: DateTime(2026, 1, 1, 3));
      expect(threeAm['night_owl'], 1);

      final fourAm = useCase(_completedState(), now: DateTime(2026, 1, 1, 4));
      expect(fourAm['night_owl'], isNull);
    });

    test('credits early_bird between 4am and 7am', () {
      final fiveAm = useCase(_completedState(), now: DateTime(2026, 1, 1, 5));
      expect(fiveAm['early_bird'], 1);
      expect(fiveAm['night_owl'], isNull);

      final sevenAm = useCase(_completedState(), now: DateTime(2026, 1, 1, 7));
      expect(sevenAm['early_bird'], isNull);
    });

    test('daytime hours credit neither night_owl nor early_bird', () {
      final noon = useCase(_completedState(), now: DateTime(2026, 1, 1, 12));
      expect(noon['night_owl'], isNull);
      expect(noon['early_bird'], isNull);
    });
  });
}
