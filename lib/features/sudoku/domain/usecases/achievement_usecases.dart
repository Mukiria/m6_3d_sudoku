import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/core/errors/failures.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/achievement_repository.dart';

/// Which achievements unlock or progress on a completed game, and by how
/// much — the actual unlock policy (thresholds, difficulty rules, time-of-
/// day rules), previously private business logic embedded in
/// `GameController` (a presentation-layer state controller) rather than the
/// domain layer where a rule like "Evil difficulty unlocks Evil Conqueror"
/// belongs.
class EvaluateAchievementDeltasUseCase {
  EvaluateAchievementDeltasUseCase();

  /// Every achievement [completedState] should progress, as id → delta.
  /// Pure and synchronous — callers are expected to apply the result in one
  /// batched write (see [IncrementAchievementProgressBatchUseCase]) rather
  /// than one write per achievement.
  ///
  /// [now] is injectable for testing; defaults to the real current time.
  Map<String, int> call(GameState completedState, {DateTime? now}) {
    final difficulty = completedState.difficulty.name;
    final timeElapsed = completedState.timeElapsed;
    final mistakes = completedState.mistakes;
    final hintsUsed = completedState.hintsUsed;
    final hour = (now ?? DateTime.now()).hour;

    return <String, int>{
      // First Win / Ten Wins / Hundred Wins
      'first_win': 1,
      'ten_wins': 1,
      'hundred_wins': 1,

      // Perfect Game (0 mistakes, 0 hints)
      if (mistakes == 0 && hintsUsed == 0) ...{
        'perfect_game': 1,
        'five_perfect': 1,
      },

      // No Hints
      if (hintsUsed == 0) ...{'no_hints': 1, 'ten_no_hints': 1},

      // Expert Winner
      if (difficulty == 'expert') 'expert_winner': 1,

      // Evil Conqueror (secret)
      if (difficulty == 'evil') 'evil_conqueror': 1,

      // All Difficulties ('Master of All') is credited by distinct
      // difficulty, not a plain count — see [distinctProgressCredits].

      // Speed Runner (under 3 minutes = 180 seconds)
      if (timeElapsed < 180) 'speed_runner': 1,

      // Lightning Fast (Easy under 1 minute = 60 seconds)
      if (difficulty == 'easy' && timeElapsed < 60) 'lightning': 1,

      // Streaks are handled by statistics

      // Daily Champion - handled by daily challenge completion, not here

      // Night Owl (midnight - 4 AM)
      if (hour >= 0 && hour < 4) 'night_owl': 1,

      // Early Bird (4 AM - 7 AM)
      if (hour >= 4 && hour < 7) 'early_bird': 1,
    };
  }

  /// Achievements that must progress by *distinct* value rather than a
  /// plain count. 'all_difficulties' ("Master of All" — win at least once
  /// on every difficulty) is the only one today: crediting it with a bare
  /// `+1` per win, the way [call]'s other entries work, would let 5 wins on
  /// the same difficulty unlock it, since a plain counter can't tell "5
  /// different difficulties" apart from "the same difficulty 5 times". This
  /// records *which* difficulty was just won instead, so
  /// [IncrementAchievementProgressBatchUseCase] only advances progress the
  /// first time each difficulty name shows up (see its `distinctProgress`
  /// param).
  Map<String, String> distinctProgressCredits(GameState completedState) {
    return {'all_difficulties': completedState.difficulty.name};
  }
}

class GetAchievementsUseCase {
  GetAchievementsUseCase(this._repository);

  final AchievementRepository _repository;

  Future<Either<Failure, List<Achievement>>> call() {
    return _repository.getAchievements();
  }
}

class UnlockAchievementUseCase {
  UnlockAchievementUseCase(this._repository);

  final AchievementRepository _repository;

  Future<Either<Failure, void>> call(String id) {
    return _repository.unlockAchievement(id);
  }
}

class UpdateAchievementProgressUseCase {
  UpdateAchievementProgressUseCase(this._repository);

  final AchievementRepository _repository;

  Future<Either<Failure, void>> call(String id, int progress) {
    return _repository.updateProgress(id, progress);
  }
}

class IncrementAchievementProgressUseCase {
  IncrementAchievementProgressUseCase(this._repository);

  final AchievementRepository _repository;

  /// Returns the unlocked [Achievement] if this call just unlocked it,
  /// otherwise `null`.
  Future<Either<Failure, Achievement?>> call(String id, int amount) {
    return _repository.incrementProgress(id, amount);
  }
}

class IncrementAchievementProgressBatchUseCase {
  IncrementAchievementProgressBatchUseCase(this._repository);

  final AchievementRepository _repository;

  /// Returns every achievement this call unlocked (possibly empty).
  ///
  /// [distinctProgress] carries achievement ids that must progress by a
  /// *distinct* value rather than a plain count — see
  /// [AchievementRepository.incrementProgressBatch]'s doc.
  Future<Either<Failure, List<Achievement>>> call(
    Map<String, int> deltas, {
    Map<String, String> distinctProgress = const {},
  }) {
    return _repository.incrementProgressBatch(
      deltas,
      distinctProgress: distinctProgress,
    );
  }
}

class GetUnlockedAchievementsUseCase {
  GetUnlockedAchievementsUseCase(this._repository);

  final AchievementRepository _repository;

  Future<Either<Failure, List<Achievement>>> call() {
    return _repository.getUnlockedAchievements();
  }
}

class GetLockedAchievementsUseCase {
  GetLockedAchievementsUseCase(this._repository);

  final AchievementRepository _repository;

  Future<Either<Failure, List<Achievement>>> call() {
    return _repository.getLockedAchievements();
  }
}
