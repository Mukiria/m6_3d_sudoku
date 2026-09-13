import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/statistics/domain/entities/statistics.dart';
import 'package:m6_sudoku/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/shared/widgets/cards.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final statisticsAsync = ref.watch(statisticsProvider);
    final recentGames = ref.watch(recentGamesProvider);

    void onBack() =>
        context.canPop() ? context.pop() : context.go(AppRoutes.home);

    return statisticsAsync.when(
      loading:
          () => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color:
                      theme.brightness == Brightness.dark ? Colors.white : null,
                ),
                tooltip: 'Home',
                onPressed: onBack,
              ),
              title: const Text('Statistics'),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stack) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color:
                      theme.brightness == Brightness.dark ? Colors.white : null,
                ),
                tooltip: 'Home',
                onPressed: onBack,
              ),
              title: const Text('Statistics'),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load statistics',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
      data:
          (stats) => Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _GlassAppBarDelegate(
                    title: 'Statistics',
                    onBack: onBack,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Stats — two per row (50% width each).
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth =
                                (constraints.maxWidth -
                                    AppConstants.spacingMd) /
                                2;
                            return Wrap(
                              spacing: AppConstants.spacingMd,
                              runSpacing: AppConstants.spacingMd,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Games Played',
                                    stats.gamesPlayed.toString(),
                                    Icons.games_rounded,
                                    extension.difficultyMediumColor,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Games Won',
                                    stats.gamesWon.toString(),
                                    Icons.emoji_events_rounded,
                                    extension.difficultyEasyColor,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Cubes Completed',
                                    stats.cubesCompleted.toString(),
                                    Icons.view_in_ar_rounded,
                                    AppThemeExtension.brandOrange,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Win Rate',
                                    '${(stats.winRate * 100).toStringAsFixed(1)}%',
                                    Icons.trending_up_rounded,
                                    extension.difficultyMediumColor,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Best Streak',
                                    '${stats.bestStreak}',
                                    Icons.local_fire_department_rounded,
                                    extension.difficultyHardColor,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Avg Time',
                                    stats.formattedAverageTime,
                                    Icons.timer_outlined,
                                    extension.difficultyExpertColor,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Current Streak',
                                    '${stats.currentStreak}',
                                    Icons.local_fire_department_outlined,
                                    extension.difficultyHardColor,
                                    fullWidth: true,
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _buildStatCard(
                                    theme,
                                    extension,
                                    'Total Time',
                                    stats.formattedTotalTime,
                                    Icons.timer_rounded,
                                    extension.difficultyExpertColor,
                                    fullWidth: true,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: AppConstants.spacingXl),

                        // Difficulty Stats
                        Text(
                          'Difficulty Performance',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingMd),

                        ...Difficulty.values.map(
                          (difficulty) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppConstants.spacingMd,
                            ),
                            child: _buildDifficultyCard(
                              theme,
                              extension,
                              difficulty,
                              stats,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppConstants.spacingXl),

                        // Recent Games
                        if (recentGames.isNotEmpty) ...[
                          Text(
                            'Recent Games',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingMd),
                          ...recentGames
                              .take(5)
                              .map(
                                (game) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppConstants.spacingSm,
                                  ),
                                  child: _buildGameRecordCard(theme, game),
                                ),
                              ),
                          const SizedBox(height: AppConstants.spacingXl),
                        ],

                        // Reset Button
                        AppButton(
                          onPressed: () => _showResetDialog(context, ref),
                          variant: AppButtonVariant.outlined,
                          child: const Text('Reset Statistics'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    AppThemeExtension extension,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment:
            fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard(
    ThemeData theme,
    AppThemeExtension extension,
    Difficulty difficulty,
    Statistics stats,
  ) {
    final color = _getDifficultyColor(extension, difficulty);
    final played = stats.gamesPlayedByDifficulty[difficulty.name] ?? 0;
    final won = stats.gamesWonByDifficulty[difficulty.name] ?? 0;
    final bestTime = stats.bestTimesByDifficulty[difficulty.name] ?? 0;
    final winRate = played > 0 ? won / played : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              difficulty.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.games_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text('$played played', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: extension.difficultyEasyColor,
                    ),
                    const SizedBox(width: 4),
                    Text('$won won', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (bestTime > 0) ...[
                      Icon(
                        Icons.timer_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Best: ${_formatTime(bestTime)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                    ],
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(winRate * 100).toStringAsFixed(0)}% win rate',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRecordCard(ThemeData theme, GameRecord game) {
    final color = _getDifficultyColor(
      theme.extension<AppThemeExtension>()!,
      Difficulty.values.firstWhere(
        (d) => d.name == game.difficulty,
        orElse: () => Difficulty.medium,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              game.difficulty.capitalize(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (game.completed)
                      Icon(Icons.check_circle_rounded, size: 16, color: color)
                    else
                      Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        game.completed ? 'Completed' : 'Incomplete',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(game.timeSeconds),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (game.mistakes > 0) ...[
                      Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${game.mistakes} mistakes',
                        style: theme.textTheme.labelSmall,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (game.hintsUsed > 0) ...[
                      Icon(
                        Icons.lightbulb_rounded,
                        size: 12,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${game.hintsUsed} hints',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            game.date.timeAgo,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(
    AppThemeExtension extension,
    Difficulty difficulty,
  ) {
    switch (difficulty) {
      case Difficulty.easy:
        return extension.difficultyEasyColor;
      case Difficulty.medium:
        return extension.difficultyMediumColor;
      case Difficulty.hard:
        return extension.difficultyHardColor;
      case Difficulty.expert:
        return extension.difficultyExpertColor;
      case Difficulty.evil:
        return extension.difficultyEvilColor;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Statistics'),
            content: const Text(
              'This will permanently delete all your statistics and game history. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(statisticsProvider.notifier).resetStatistics();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Statistics reset')),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}

/// A glass top bar that shrinks as the page scrolls — the one screen in the
/// app whose header genuinely needs to respond to scroll position, since it
/// sits over the same long list of cards its blur is meant to reveal.
class _GlassAppBarDelegate extends SliverPersistentHeaderDelegate {
  _GlassAppBarDelegate({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  static const double _expandedHeight = 96;
  static const double _collapsedHeight = 56;

  @override
  double get minExtent => _collapsedHeight;

  @override
  double get maxExtent => _expandedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final t = (shrinkOffset / (_expandedHeight - _collapsedHeight)).clamp(
      0.0,
      1.0,
    );
    final theme = Theme.of(context);

    return GlassSurface(
      cornerRadius: 0,
      padding: EdgeInsets.only(bottom: lerpDouble(16, 6, t)!),
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color:
                      theme.brightness == Brightness.dark ? Colors.white : null,
                ),
                tooltip: 'Home',
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: lerpDouble(26, 18, t),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _GlassAppBarDelegate oldDelegate) {
    return title != oldDelegate.title || onBack != oldDelegate.onBack;
  }
}

extension DateTimeExtension on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }
}
