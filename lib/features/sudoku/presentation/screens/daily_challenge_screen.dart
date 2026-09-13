import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/daily_challenge.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

class DailyChallengeScreen extends ConsumerStatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  ConsumerState<DailyChallengeScreen> createState() =>
      _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends ConsumerState<DailyChallengeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;
    final dailyChallengeAsync = ref.watch(dailyChallengeProvider);
    final statsAsync = ref.watch(dailyChallengeStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenge'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(dailyChallengeProvider);
              ref.invalidate(dailyChallengeStatsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: dailyChallengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load daily challenge',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  AppButton(
                    onPressed: () {
                      ref.invalidate(dailyChallengeProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data:
            (challenge) => statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildContent(context, challenge, null),
              data: (stats) => _buildContent(context, challenge, stats),
            ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DailyChallenge challenge,
    DailyChallengeStats? stats,
  ) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;
    final isCompleted = challenge.isCompleted;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and status
          _buildHeader(theme, extension, colorScheme, challenge, isCompleted),
          const SizedBox(height: AppConstants.spacingXl),

          // Stats row
          if (stats != null)
            _buildStatsRow(theme, extension, colorScheme, stats),
          const SizedBox(height: AppConstants.spacingXl),

          // Puzzle preview or completion info
          if (isCompleted) ...[
            _buildCompletionCard(theme, extension, colorScheme, challenge),
          ] else ...[
            _buildPlayButton(theme, extension, colorScheme, context, challenge),
          ],

          const SizedBox(height: AppConstants.spacingXl),

          // Rules
          _buildRules(theme, extension, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
    DailyChallenge challenge,
    bool isCompleted,
  ) {
    final date = DateTime.parse(challenge.date);
    final formattedDate =
        '${_getMonthName(date.month)} ${date.day}, ${date.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? extension.difficultyEasyColor.withValues(alpha: 0.1)
                    : extension.difficultyMediumColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isCompleted
                      ? extension.difficultyEasyColor
                      : extension.difficultyMediumColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.calendar_today_rounded,
                size: 16,
                color:
                    isCompleted
                        ? extension.difficultyEasyColor
                        : extension.difficultyMediumColor,
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isCompleted
                          ? extension.difficultyEasyColor
                          : extension.difficultyMediumColor,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(),
        const SizedBox(height: AppConstants.spacingMd),
        Text(
          isCompleted ? 'Challenge Completed!' : 'Today\'s Challenge',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(),
        const SizedBox(height: AppConstants.spacingXs),
        Text(
          isCompleted
              ? 'Come back tomorrow for a new puzzle'
              : 'Medium difficulty • Same puzzle for everyone',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(),
      ],
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
    DailyChallengeStats stats,
  ) {
    return Column(
      children: [
        _buildStatItem(
          theme,
          extension,
          colorScheme,
          'Played',
          stats.totalPlayed.toString(),
          Icons.games_rounded,
          extension.difficultyMediumColor,
          fullWidth: true,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _buildStatItem(
          theme,
          extension,
          colorScheme,
          'Completed',
          stats.totalCompleted.toString(),
          Icons.check_circle_rounded,
          extension.difficultyEasyColor,
          fullWidth: true,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _buildStatItem(
          theme,
          extension,
          colorScheme,
          'Streak',
          '${stats.currentStreak}',
          Icons.local_fire_department_rounded,
          extension.difficultyHardColor,
          fullWidth: true,
        ),
        const SizedBox(height: AppConstants.spacingMd),
        _buildStatItem(
          theme,
          extension,
          colorScheme,
          'Best Time',
          stats.bestStreak > 0 ? _formatTime(stats.bestStreak) : '--',
          Icons.timer_rounded,
          extension.difficultyExpertColor,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child:
          fullWidth
              ? Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: AppConstants.spacingMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: AppConstants.spacingXs),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildCompletionCard(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
    DailyChallenge challenge,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            extension.difficultyEasyColor.withValues(alpha: 0.2),
            extension.difficultyEasyColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        border: Border.all(
          color: extension.difficultyEasyColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: extension.difficultyEasyColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Challenge Completed!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: extension.difficultyEasyColor,
                      ),
                    ),
                    Text(
                      'Puzzle solved on ${_formatDate(challenge.date)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Row(
            children: [
              Expanded(
                child: _buildCompletionStat(
                  theme,
                  colorScheme: colorScheme,
                  label: 'Time',
                  value: _formatTime(challenge.timeElapsed ?? 0),
                  icon: Icons.timer_rounded,
                  color: extension.timerText,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _buildCompletionStat(
                  theme,
                  colorScheme: colorScheme,
                  label: 'Mistakes',
                  value: '${challenge.mistakes}/3',
                  icon: Icons.close_rounded,
                  color: extension.mistakeIndicatorColor,
                ),
              ),
              const SizedBox(width: AppConstants.spacingMd),
              Expanded(
                child: _buildCompletionStat(
                  theme,
                  colorScheme: colorScheme,
                  label: 'Hints',
                  value: '${challenge.hintsUsed}/3',
                  icon: Icons.lightbulb_rounded,
                  color: extension.hintIndicatorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildCompletionStat(
    ThemeData theme, {
    required ColorScheme colorScheme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayButton(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
    BuildContext context,
    DailyChallenge challenge,
  ) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                extension.difficultyMediumColor.withValues(alpha: 0.2),
                extension.difficultyMediumColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
            border: Border.all(
              color: extension.difficultyMediumColor.withValues(alpha: 0.3),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.grid_3x3_rounded,
                  size: 120,
                  color: extension.difficultyMediumColor.withValues(alpha: 0.1),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Play Daily Challenge',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: extension.difficultyMediumColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      'Medium • ${challenge.puzzle.cluesCount} clues',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(),
        const SizedBox(height: AppConstants.spacingLg),
        AppButton(
          onPressed: () {
            context.push(AppRoutes.game, extra: 'daily_${challenge.date}');
          },
          variant: AppButtonVariant.filled,
          size: AppButtonSize.large,
          icon: const Icon(Icons.play_arrow_rounded),
          child: const Text('Start Challenge'),
        ).animate().fadeIn(delay: 300.ms).slideY(),
      ],
    );
  }

  Widget _buildRules(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMd),
          _buildRuleItem(
            theme,
            extension,
            colorScheme,
            'Same puzzle for everyone, everywhere',
            Icons.public_rounded,
          ),
          _buildRuleItem(
            theme,
            extension,
            colorScheme,
            'New puzzle every day at midnight UTC',
            Icons.schedule_rounded,
          ),
          _buildRuleItem(
            theme,
            extension,
            colorScheme,
            'Compete for best time and streak',
            Icons.emoji_events_rounded,
          ),
          _buildRuleItem(
            theme,
            extension,
            colorScheme,
            'Hints and mistakes tracked separately',
            Icons.help_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(
    ThemeData theme,
    AppThemeExtension extension,
    ColorScheme colorScheme,
    String text,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: extension.difficultyMediumColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: extension.difficultyMediumColor),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }
}
