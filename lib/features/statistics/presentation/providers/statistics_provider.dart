import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/features/statistics/data/datasources/statistics_local_datasource.dart';
import 'package:m6_sudoku/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:m6_sudoku/features/statistics/domain/entities/statistics.dart';
import 'package:m6_sudoku/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:m6_sudoku/features/statistics/domain/usecases/statistics_usecases.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

final statisticsLocalDataSourceProvider = Provider<StatisticsLocalDataSource>((
  ref,
) {
  final storage = ref.read(storageServiceProvider);
  return StatisticsLocalDataSource(storage);
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final dataSource = ref.read(statisticsLocalDataSourceProvider);
  return StatisticsRepositoryImpl(dataSource);
});

final getStatisticsUseCaseProvider = Provider<GetStatisticsUseCase>((ref) {
  final repo = ref.read(statisticsRepositoryProvider);
  return GetStatisticsUseCase(repo);
});

final updateStatisticsUseCaseProvider = Provider<UpdateStatisticsUseCase>((
  ref,
) {
  final repo = ref.read(statisticsRepositoryProvider);
  return UpdateStatisticsUseCase(repo);
});

final addGameRecordUseCaseProvider = Provider<AddGameRecordUseCase>((ref) {
  final repo = ref.read(statisticsRepositoryProvider);
  return AddGameRecordUseCase(repo);
});

final resetStatisticsUseCaseProvider = Provider<ResetStatisticsUseCase>((ref) {
  final repo = ref.read(statisticsRepositoryProvider);
  return ResetStatisticsUseCase(repo);
});

final statisticsProvider =
    StateNotifierProvider<StatisticsController, AsyncValue<Statistics>>((ref) {
      return StatisticsController(ref);
    });

final recentGamesProvider = StateProvider<List<GameRecord>>((ref) => []);

class StatisticsController extends StateNotifier<AsyncValue<Statistics>> {
  StatisticsController(this._ref) : super(const AsyncValue.loading()) {
    _loadStatistics();
  }

  final Ref _ref;

  Future<void> _loadStatistics() async {
    state = const AsyncValue.loading();
    final getStatistics = _ref.read(getStatisticsUseCaseProvider);
    final result = await getStatistics();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (statistics) => AsyncValue.data(statistics),
    );
  }

  Future<void> recordGame({
    required String difficulty,
    required int timeSeconds,
    required int mistakes,
    required int hintsUsed,
    required bool completed,
  }) async {
    final record = GameRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      difficulty: difficulty,
      timeSeconds: timeSeconds,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      completed: completed,
    );

    final addRecord = _ref.read(addGameRecordUseCaseProvider);
    await addRecord(record);

    final currentStats = state.value;
    if (currentStats != null) {
      final updatedStats = _updateStats(currentStats, record);
      final updateStats = _ref.read(updateStatisticsUseCaseProvider);
      await updateStats(updatedStats);
      state = AsyncValue.data(updatedStats);
    }

    _ref.read(recentGamesProvider.notifier).state =
        [record, ..._ref.read(recentGamesProvider)].take(10).toList();
  }

  Statistics _updateStats(Statistics current, GameRecord record) {
    final newGamesPlayed = current.gamesPlayed + 1;
    final newGamesWon = current.gamesWon + (record.completed ? 1 : 0);
    final newTotalTime = current.totalTimeSeconds + record.timeSeconds;
    final newHintsUsed = current.hintsUsed + record.hintsUsed;
    final newMistakesMade = current.mistakesMade + record.mistakes;

    final newBestTimes = Map<String, int>.from(current.bestTimesByDifficulty);
    if (record.completed) {
      final currentBest = newBestTimes[record.difficulty] ?? 0;
      if (currentBest == 0 || record.timeSeconds < currentBest) {
        newBestTimes[record.difficulty] = record.timeSeconds;
      }
    }

    final newGamesWonByDiff = Map<String, int>.from(
      current.gamesWonByDifficulty,
    );
    final newGamesPlayedByDiff = Map<String, int>.from(
      current.gamesPlayedByDifficulty,
    );
    newGamesPlayedByDiff[record.difficulty] =
        (newGamesPlayedByDiff[record.difficulty] ?? 0) + 1;
    if (record.completed) {
      newGamesWonByDiff[record.difficulty] =
          (newGamesWonByDiff[record.difficulty] ?? 0) + 1;
    }

    final newStreak = record.completed ? current.currentStreak + 1 : 0;
    final newBestStreak =
        newStreak > current.bestStreak ? newStreak : current.bestStreak;

    return Statistics(
      gamesPlayed: newGamesPlayed,
      gamesWon: newGamesWon,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      totalTimeSeconds: newTotalTime,
      hintsUsed: newHintsUsed,
      mistakesMade: newMistakesMade,
      bestTimesByDifficulty: newBestTimes,
      gamesWonByDifficulty: newGamesWonByDiff,
      gamesPlayedByDifficulty: newGamesPlayedByDiff,
      lastPlayed: record.date,
      cubesCompleted: current.cubesCompleted,
    );
  }

  /// Folds a single cube face's completion into the same per-difficulty
  /// maps [recordGame] feeds — a face is a real, independently-solved
  /// puzzle of its own difficulty, so it counts immediately, the moment it
  /// completes, rather than being deferred until (or lost if) the whole
  /// six-face cube never gets finished. Deliberately narrower than
  /// [recordGame]/[_updateStats]: it never touches bestTimesByDifficulty,
  /// the win streak, or the aggregate gamesPlayed/gamesWon — the cube has
  /// no reliable per-face timer (CubeGameState tracks one shared clock for
  /// the whole session, not one per face), and "one of six faces" isn't the
  /// same unit as a standalone game for streak purposes.
  Future<void> recordCubeFaceCompletion(String difficulty) async {
    final current = state.value;
    if (current == null) return;

    final newGamesPlayedByDiff = Map<String, int>.from(
      current.gamesPlayedByDifficulty,
    );
    newGamesPlayedByDiff[difficulty] =
        (newGamesPlayedByDiff[difficulty] ?? 0) + 1;
    final newGamesWonByDiff = Map<String, int>.from(
      current.gamesWonByDifficulty,
    );
    newGamesWonByDiff[difficulty] = (newGamesWonByDiff[difficulty] ?? 0) + 1;

    final updated = current.copyWith(
      gamesPlayedByDifficulty: newGamesPlayedByDiff,
      gamesWonByDifficulty: newGamesWonByDiff,
    );
    final updateStats = _ref.read(updateStatisticsUseCaseProvider);
    await updateStats(updated);
    state = AsyncValue.data(updated);
  }

  /// One full six-face cube solved — the cube-level counterpart to
  /// [gamesPlayed]/[gamesWon].
  Future<void> recordCubeCompletion() async {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      cubesCompleted: current.cubesCompleted + 1,
    );
    final updateStats = _ref.read(updateStatisticsUseCaseProvider);
    await updateStats(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> resetStatistics() async {
    state = const AsyncValue.loading();
    final resetStats = _ref.read(resetStatisticsUseCaseProvider);
    final result = await resetStats();

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (_) {
        _ref.read(recentGamesProvider.notifier).state = [];
        return AsyncValue.data(_defaultStats());
      },
    );
  }

  Statistics _defaultStats() {
    return const Statistics(
      gamesPlayed: 0,
      gamesWon: 0,
      currentStreak: 0,
      bestStreak: 0,
      totalTimeSeconds: 0,
      hintsUsed: 0,
      mistakesMade: 0,
      bestTimesByDifficulty: {},
      gamesWonByDifficulty: {},
      gamesPlayedByDifficulty: {},
      lastPlayed: null,
      cubesCompleted: 0,
    );
  }
}
