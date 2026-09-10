import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/core/audio/audio_manager.dart';
import 'package:m6_sudoku/core/audio/audio_service.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/puzzle_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/daily_challenge_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/daily_streak_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/data/datasources/achievement_local_datasource.dart';
import 'package:m6_sudoku/features/sudoku/data/repositories/puzzle_repository_impl.dart';
import 'package:m6_sudoku/features/sudoku/data/repositories/daily_challenge_repository_impl.dart';
import 'package:m6_sudoku/features/sudoku/data/repositories/daily_streak_repository_impl.dart';
import 'package:m6_sudoku/features/sudoku/data/repositories/achievement_repository_impl.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/puzzle_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/daily_challenge_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/daily_streak_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/repositories/achievement_repository.dart';
import 'package:m6_sudoku/features/sudoku/domain/usecases/game_usecases.dart';
import 'package:m6_sudoku/features/sudoku/domain/usecases/daily_challenge_usecases.dart';
import 'package:m6_sudoku/features/sudoku/domain/usecases/daily_streak_usecases.dart';
import 'package:m6_sudoku/features/sudoku/domain/usecases/achievement_usecases.dart';
import 'package:m6_sudoku/features/sudoku/engine/generator/puzzle_generator.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_challenge.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize storage service in main.dart');
});

final puzzleGeneratorProvider = Provider<PuzzleGenerator>((ref) {
  return PuzzleGenerator();
});

final puzzleLocalDataSourceProvider = Provider<PuzzleLocalDataSource>((ref) {
  final storage = ref.read(storageServiceProvider);
  final generator = ref.read(puzzleGeneratorProvider);
  return PuzzleLocalDataSource(storage, generator);
});

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  final dataSource = ref.read(puzzleLocalDataSourceProvider);
  return PuzzleRepositoryImpl(dataSource);
});

final generatePuzzleUseCaseProvider = Provider<GeneratePuzzleUseCase>((ref) {
  final repo = ref.read(puzzleRepositoryProvider);
  return GeneratePuzzleUseCase(repo);
});

final getGameStateUseCaseProvider = Provider<GetGameStateUseCase>((ref) {
  final repo = ref.read(puzzleRepositoryProvider);
  return GetGameStateUseCase(repo);
});

final saveGameStateUseCaseProvider = Provider<SaveGameStateUseCase>((ref) {
  final repo = ref.read(puzzleRepositoryProvider);
  return SaveGameStateUseCase(repo);
});

final validateMoveUseCaseProvider = Provider<ValidateMoveUseCase>((ref) {
  return ValidateMoveUseCase();
});

final checkCompletionUseCaseProvider = Provider<CheckCompletionUseCase>((ref) {
  return CheckCompletionUseCase();
});

final getHintUseCaseProvider = Provider<GetHintUseCase>((ref) {
  final repo = ref.read(puzzleRepositoryProvider);
  return GetHintUseCase(repo);
});

final dailyChallengeLocalDataSourceProvider =
    Provider<DailyChallengeLocalDataSource>((ref) {
      final storage = ref.read(storageServiceProvider);
      return DailyChallengeLocalDataSource(storage);
    });

final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((
  ref,
) {
  final dataSource = ref.read(dailyChallengeLocalDataSourceProvider);
  return DailyChallengeRepositoryImpl(dataSource);
});

final getOrGenerateDailyChallengeUseCaseProvider =
    Provider<GetOrGenerateDailyChallengeUseCase>((ref) {
      final repo = ref.read(dailyChallengeRepositoryProvider);
      return GetOrGenerateDailyChallengeUseCase(repo);
    });

final completeDailyChallengeUseCaseProvider =
    Provider<CompleteDailyChallengeUseCase>((ref) {
      final repo = ref.read(dailyChallengeRepositoryProvider);
      return CompleteDailyChallengeUseCase(repo);
    });

final getDailyChallengeStatsUseCaseProvider =
    Provider<GetDailyChallengeStatsUseCase>((ref) {
      final repo = ref.read(dailyChallengeRepositoryProvider);
      return GetDailyChallengeStatsUseCase(repo);
    });

final isDailyChallengeCompletedUseCaseProvider =
    Provider<IsDailyChallengeCompletedUseCase>((ref) {
      final repo = ref.read(dailyChallengeRepositoryProvider);
      return IsDailyChallengeCompletedUseCase(repo);
    });

final dailyChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  final useCase = ref.read(getOrGenerateDailyChallengeUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (challenge) => challenge,
  );
});

final dailyChallengeStatsProvider = FutureProvider<DailyChallengeStats>((
  ref,
) async {
  final useCase = ref.read(getDailyChallengeStatsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (stats) => stats,
  );
});

final dailyStreakLocalDataSourceProvider = Provider<DailyStreakLocalDataSource>(
  (ref) {
    final storage = ref.read(storageServiceProvider);
    return DailyStreakLocalDataSource(storage);
  },
);

final dailyStreakRepositoryProvider = Provider<DailyStreakRepository>((ref) {
  final dataSource = ref.read(dailyStreakLocalDataSourceProvider);
  return DailyStreakRepositoryImpl(dataSource);
});

final recordDailyStreakCompletionUseCaseProvider =
    Provider<RecordDailyStreakCompletionUseCase>((ref) {
      final repo = ref.read(dailyStreakRepositoryProvider);
      return RecordDailyStreakCompletionUseCase(repo);
    });

final achievementLocalDataSourceProvider = Provider<AchievementLocalDataSource>(
  (ref) {
    final storage = ref.read(storageServiceProvider);
    return AchievementLocalDataSource(storage);
  },
);

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final dataSource = ref.read(achievementLocalDataSourceProvider);
  return AchievementRepositoryImpl(dataSource);
});

final getAchievementsUseCaseProvider = Provider<GetAchievementsUseCase>((ref) {
  final repo = ref.read(achievementRepositoryProvider);
  return GetAchievementsUseCase(repo);
});

final unlockAchievementUseCaseProvider = Provider<UnlockAchievementUseCase>((
  ref,
) {
  final repo = ref.read(achievementRepositoryProvider);
  return UnlockAchievementUseCase(repo);
});

final updateAchievementProgressUseCaseProvider =
    Provider<UpdateAchievementProgressUseCase>((ref) {
      final repo = ref.read(achievementRepositoryProvider);
      return UpdateAchievementProgressUseCase(repo);
    });

final incrementAchievementProgressUseCaseProvider =
    Provider<IncrementAchievementProgressUseCase>((ref) {
      final repo = ref.read(achievementRepositoryProvider);
      return IncrementAchievementProgressUseCase(repo);
    });

final getUnlockedAchievementsUseCaseProvider =
    Provider<GetUnlockedAchievementsUseCase>((ref) {
      final repo = ref.read(achievementRepositoryProvider);
      return GetUnlockedAchievementsUseCase(repo);
    });

final getLockedAchievementsUseCaseProvider =
    Provider<GetLockedAchievementsUseCase>((ref) {
      final repo = ref.read(achievementRepositoryProvider);
      return GetLockedAchievementsUseCase(repo);
    });

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final useCase = ref.read(getAchievementsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (achievements) => achievements,
  );
});

final unlockedAchievementsProvider = FutureProvider<List<Achievement>>((
  ref,
) async {
  final useCase = ref.read(getUnlockedAchievementsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (achievements) => achievements,
  );
});

/// Queue of achievements newly unlocked during the current session, in the
/// order they unlocked. [AchievementUnlockBanner] watches this to animate
/// each one in turn, popping the front entry once its animation finishes
/// (or the player taps to dismiss it early).
class AchievementUnlockQueue extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => [];

  void push(Achievement achievement) {
    state = [...state, achievement];
  }

  void popFirst() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }
}

final achievementUnlockQueueProvider =
    NotifierProvider<AchievementUnlockQueue, List<Achievement>>(
      AchievementUnlockQueue.new,
    );

final audioManagerProvider = Provider<AudioManager>((ref) {
  return AudioManager.instance;
});

final audioServiceProvider = Provider<AudioService>((ref) {
  final audioManager = ref.read(audioManagerProvider);
  final soundEnabled = ref.watch(
    settingsProvider.select((settings) => settings.soundEnabled),
  );

  audioManager.initialize();
  // Kept in sync with the settings toggle for the lifetime of the app.
  audioManager.setMuted(!soundEnabled);

  return AudioService(audioManager);
});
