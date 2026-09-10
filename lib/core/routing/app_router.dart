import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/features/home/presentation/screens/home_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/game_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/difficulty_selection_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/completion_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/daily_streak_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/puzzle_loading_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/daily_challenge_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/screens/achievement_screen.dart';
import 'package:m6_sudoku/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:m6_sudoku/features/settings/presentation/screens/settings_screen.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/pause_menu.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder:
            (context, state) => const MaterialPage(child: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.difficultySelection,
        name: 'difficulty',
        pageBuilder:
            (context, state) =>
                const MaterialPage(child: DifficultySelectionScreen()),
      ),

      // Game route — slide up transition
      GoRoute(
        path: AppRoutes.game,
        name: 'game',
        pageBuilder: (context, state) {
          final difficulty =
              state.extra as String? ?? AppConstants.difficultyEasy;
          return CustomTransitionPage(
            key: state.pageKey,
            child: GameScreen(difficulty: difficulty),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          );
        },
      ),

      GoRoute(
        path: AppRoutes.statistics,
        name: 'statistics',
        pageBuilder:
            (context, state) => const MaterialPage(child: StatisticsScreen()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder:
            (context, state) => const MaterialPage(child: SettingsScreen()),
      ),
      GoRoute(
        path: AppRoutes.pause,
        name: 'pause',
        pageBuilder: (context, state) => const MaterialPage(child: PauseMenu()),
      ),

      // Completion route — slide up transition
      GoRoute(
        path: AppRoutes.completion,
        name: 'completion',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final page = CompletionScreen(
            time: extra?['time'] as int? ?? 0,
            mistakes: extra?['mistakes'] as int? ?? 0,
            hintsUsed: extra?['hintsUsed'] as int? ?? 0,
            difficulty:
                extra?['difficulty'] as String? ?? AppConstants.difficultyEasy,
          );
          return CustomTransitionPage(
            key: state.pageKey,
            child: page,
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          );
        },
      ),

      // Daily streak celebration — slide up transition, matches completion.
      GoRoute(
        path: AppRoutes.dailyStreak,
        name: 'dailyStreak',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final page = DailyStreakScreen(
            currentStreak: extra?['currentStreak'] as int? ?? 1,
            completedWeekdays:
                extra?['completedWeekdays'] as Set<int>? ?? const {},
            todayWeekday: extra?['todayWeekday'] as int? ?? 0,
          );
          return CustomTransitionPage(
            key: state.pageKey,
            child: page,
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              );
            },
          );
        },
      ),

      GoRoute(
        path: AppRoutes.puzzleLoading,
        name: 'puzzleLoading',
        pageBuilder: (context, state) {
          final difficulty =
              state.extra as String? ?? AppConstants.difficultyEasy;
          return MaterialPage(
            child: PuzzleLoadingScreen(difficulty: difficulty),
          );
        },
      ),

      // Achievements & Daily Challenge — fade + scale
      GoRoute(
        path: AppRoutes.dailyChallenge,
        name: 'dailyChallenge',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DailyChallengeScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
            ),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        name: 'achievements',
        pageBuilder:
            (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AchievementScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  state.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go Home'),
                ),
              ],
            ),
          ),
        ),
  );
});

class AppRoutes {
  static const String home = '/';
  static const String difficultySelection = '/difficulty';
  static const String game = '/game';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String pause = '/pause';
  static const String completion = '/completion';
  static const String dailyStreak = '/daily-streak';
  static const String puzzleLoading = '/loading';
  static const String dailyChallenge = '/daily';
  static const String achievements = '/achievements';

  static String get homeRoute => home;
  static String get difficultyRoute => difficultySelection;
  static String get gameRoute => game;
  static String get statisticsRoute => statistics;
  static String get settingsRoute => settings;
  static String get pauseRoute => pause;
  static String get completionRoute => completion;
  static String get dailyStreakRoute => dailyStreak;
  static String get puzzleLoadingRoute => puzzleLoading;
  static String get dailyChallengeRoute => dailyChallenge;
  static String get achievementsRoute => achievements;
}
