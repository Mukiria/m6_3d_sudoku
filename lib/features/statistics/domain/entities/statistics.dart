import 'package:equatable/equatable.dart';

class Statistics extends Equatable {
  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      gamesPlayed: json['gamesPlayed'] ?? 0,
      gamesWon: json['gamesWon'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      bestStreak: json['bestStreak'] ?? 0,
      totalTimeSeconds: json['totalTimeSeconds'] ?? 0,
      hintsUsed: json['hintsUsed'] ?? 0,
      mistakesMade: json['mistakesMade'] ?? 0,
      bestTimesByDifficulty: Map<String, int>.from(
        json['bestTimesByDifficulty'] ?? {},
      ),
      gamesWonByDifficulty: Map<String, int>.from(
        json['gamesWonByDifficulty'] ?? {},
      ),
      gamesPlayedByDifficulty: Map<String, int>.from(
        json['gamesPlayedByDifficulty'] ?? {},
      ),
      lastPlayed:
          json['lastPlayed'] != null
              ? DateTime.parse(json['lastPlayed'])
              : null,
      cubesCompleted: json['cubesCompleted'] ?? 0,
    );
  }
  const Statistics({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalTimeSeconds,
    required this.hintsUsed,
    required this.mistakesMade,
    required this.bestTimesByDifficulty,
    required this.gamesWonByDifficulty,
    required this.gamesPlayedByDifficulty,
    required this.lastPlayed,
    required this.cubesCompleted,
  });

  final int gamesPlayed;
  final int gamesWon;
  final int currentStreak;
  final int bestStreak;
  final int totalTimeSeconds;
  final int hintsUsed;
  final int mistakesMade;
  final Map<String, int> bestTimesByDifficulty;
  final Map<String, int> gamesWonByDifficulty;
  final Map<String, int> gamesPlayedByDifficulty;
  final DateTime? lastPlayed;

  /// Full six-face 3D Sudoku cubes solved. Each face's own difficulty is
  /// folded into [gamesPlayedByDifficulty]/[gamesWonByDifficulty] separately
  /// as it completes (see CubeGameController.setValue) — this is just the
  /// cube-level counterpart to [gamesPlayed]/[gamesWon].
  final int cubesCompleted;

  Statistics copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? currentStreak,
    int? bestStreak,
    int? totalTimeSeconds,
    int? hintsUsed,
    int? mistakesMade,
    Map<String, int>? bestTimesByDifficulty,
    Map<String, int>? gamesWonByDifficulty,
    Map<String, int>? gamesPlayedByDifficulty,
    DateTime? lastPlayed,
    int? cubesCompleted,
  }) {
    return Statistics(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      totalTimeSeconds: totalTimeSeconds ?? this.totalTimeSeconds,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakesMade: mistakesMade ?? this.mistakesMade,
      bestTimesByDifficulty:
          bestTimesByDifficulty ?? this.bestTimesByDifficulty,
      gamesWonByDifficulty: gamesWonByDifficulty ?? this.gamesWonByDifficulty,
      gamesPlayedByDifficulty:
          gamesPlayedByDifficulty ?? this.gamesPlayedByDifficulty,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      cubesCompleted: cubesCompleted ?? this.cubesCompleted,
    );
  }

  double get winRate => gamesPlayed > 0 ? gamesWon / gamesPlayed : 0.0;

  int get averageTimeSeconds => gamesWon > 0 ? totalTimeSeconds ~/ gamesWon : 0;

  String get formattedAverageTime {
    final seconds = averageTimeSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  String get formattedTotalTime {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    final seconds = totalTimeSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Map<String, dynamic> toJson() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'totalTimeSeconds': totalTimeSeconds,
      'hintsUsed': hintsUsed,
      'mistakesMade': mistakesMade,
      'bestTimesByDifficulty': bestTimesByDifficulty,
      'gamesWonByDifficulty': gamesWonByDifficulty,
      'gamesPlayedByDifficulty': gamesPlayedByDifficulty,
      'lastPlayed': lastPlayed?.toIso8601String(),
      'cubesCompleted': cubesCompleted,
    };
  }

  @override
  List<Object?> get props => [
    gamesPlayed,
    gamesWon,
    currentStreak,
    bestStreak,
    totalTimeSeconds,
    hintsUsed,
    mistakesMade,
    bestTimesByDifficulty,
    gamesWonByDifficulty,
    gamesPlayedByDifficulty,
    lastPlayed,
    cubesCompleted,
  ];
}

class GameRecord extends Equatable {
  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      difficulty: json['difficulty'] ?? '',
      timeSeconds: json['timeSeconds'] ?? 0,
      mistakes: json['mistakes'] ?? 0,
      hintsUsed: json['hintsUsed'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }
  const GameRecord({
    required this.id,
    required this.date,
    required this.difficulty,
    required this.timeSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.completed,
  });

  final String id;
  final DateTime date;
  final String difficulty;
  final int timeSeconds;
  final int mistakes;
  final int hintsUsed;
  final bool completed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'difficulty': difficulty,
      'timeSeconds': timeSeconds,
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'completed': completed,
    };
  }

  @override
  List<Object?> get props => [
    id,
    date,
    difficulty,
    timeSeconds,
    mistakes,
    hintsUsed,
    completed,
  ];
}
