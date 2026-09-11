import 'package:dartz/dartz.dart';
import 'package:m6_sudoku/features/statistics/domain/entities/statistics.dart';
import 'package:m6_sudoku/core/services/json_store.dart';
import 'package:m6_sudoku/core/services/storage_service.dart';
import 'package:m6_sudoku/core/errors/failures.dart';

class StatisticsLocalDataSource {
  StatisticsLocalDataSource(StorageService storage)
    : _json = JsonStore(storage);

  final JsonStore _json;

  static const String _statsKey = 'statistics';
  static const String _gamesKey = 'game_records';

  Future<Either<Failure, Statistics>> getStatistics() async {
    return _json.readJson(
      _statsKey,
      (decoded) => Statistics.fromJson(decoded as Map<String, dynamic>),
      _defaultStatistics,
      'get statistics',
    );
  }

  Future<Either<Failure, void>> updateStatistics(Statistics statistics) {
    return _json.writeJson(_statsKey, statistics.toJson(), 'update statistics');
  }

  Future<Either<Failure, void>> addGameRecord(GameRecord record) async {
    final gamesResult = await getRecentGames();
    final games = gamesResult.fold((_) => <GameRecord>[], (g) => g);
    final updatedGames = [record, ...games].take(100).toList();
    return _json.writeJson(
      _gamesKey,
      updatedGames.map((g) => g.toJson()).toList(),
      'add game record',
    );
  }

  Future<Either<Failure, List<GameRecord>>> getRecentGames({
    int limit = 10,
  }) async {
    final result = _json.readJson(
      _gamesKey,
      (decoded) =>
          (decoded as List)
              .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
              .toList(),
      () => <GameRecord>[],
      'get recent games',
    );
    return result.map((games) => games.take(limit).toList());
  }

  Future<Either<Failure, void>> resetStatistics() {
    return _json.removeKeys([_statsKey, _gamesKey], 'reset statistics');
  }

  Statistics _defaultStatistics() {
    return Statistics(
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
    );
  }
}
