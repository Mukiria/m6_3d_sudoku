import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';

class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({
    super.key,
    required this.time,
    required this.mistakes,
    required this.hintsUsed,
    required this.difficulty,
  });

  final int time;
  final int mistakes;
  final int hintsUsed;
  final String difficulty;

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late ConfettiController _confettiController2;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController2 = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _confettiController.play();
        _confettiController2.play();
      }
    });

    // Recorded once per screen instance (initState only ever runs once),
    // not in build(), which can rerun on unrelated rebuilds (theme change,
    // rotation, text-scale change) and would otherwise double-count the
    // same completed game in persisted statistics.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(statisticsProvider.notifier)
          .recordGame(
            difficulty: widget.difficulty,
            timeSeconds: widget.time,
            mistakes: widget.mistakes,
            hintsUsed: widget.hintsUsed,
            completed: true,
          );

      _maybeShowDailyStreak();
    });
  }

  /// Records today as a completed-puzzle day and, only if this is the
  /// first puzzle completed today (regular game or Daily Challenge — both
  /// land here), auto-navigates to the daily streak celebration once the
  /// player has had a moment to see this "Puzzle Complete!" screen.
  Future<void> _maybeShowDailyStreak() async {
    final recordStreak = ref.read(recordDailyStreakCompletionUseCaseProvider);
    final result = await recordStreak();

    result.fold((_) {}, (data) {
      if (!data.isFirstCompletionToday) return;

      final today = DateTime.now();
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        context.push(
          AppRoutes.dailyStreak,
          extra: {
            'currentStreak': data.streak.currentStreak,
            'completedWeekdays': data.streak.completedWeekdaysThisWeek(today),
            'todayWeekday': today.weekday % 7,
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extension = theme.extension<AppThemeExtension>()!;

    Color difficultyColor;
    switch (widget.difficulty) {
      case 'easy':
        difficultyColor = extension.difficultyEasyColor!;
        break;
      case 'medium':
        difficultyColor = extension.difficultyMediumColor!;
        break;
      case 'hard':
        difficultyColor = extension.difficultyHardColor!;
        break;
      case 'expert':
        difficultyColor = extension.difficultyExpertColor!;
        break;
      default:
        difficultyColor = colorScheme.primary;
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  difficultyColor.withValues(alpha: 0.1),
                  colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirection: 1.57,
                        emissionFrequency: 0.05,
                        numberOfParticles: 20,
                        maxBlastForce: 10,
                        minBlastForce: 5,
                        colors: [
                          difficultyColor,
                          Colors.white,
                          Colors.yellow,
                          Colors.orange,
                          Colors.pink,
                        ],
                      ),
                    ),

                    Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: difficultyColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: difficultyColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .then()
                        .shimmer(duration: 1000.ms),

                    const SizedBox(height: AppConstants.spacingXl),

                    Text(
                          'Puzzle Complete!',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 300.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppConstants.spacingSm),

                    Text(
                          '${_capitalize(widget.difficulty)} difficulty solved',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 400.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: AppConstants.spacingXl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCompletionStat(
                          theme,
                          icon: Icons.timer_rounded,
                          label: 'Time',
                          value: _formatTime(widget.time),
                          color: extension.timerText!,
                          delay: 500,
                        ),
                        _buildCompletionStat(
                          theme,
                          icon: Icons.close_rounded,
                          label: 'Mistakes',
                          value: '${widget.mistakes}/3',
                          color: extension.mistakeIndicatorColor!,
                          delay: 600,
                        ),
                        _buildCompletionStat(
                          theme,
                          icon: Icons.lightbulb_rounded,
                          label: 'Hints',
                          value: '${widget.hintsUsed}/3',
                          color: extension.hintIndicatorColor!,
                          delay: 700,
                        ),
                      ],
                    ),

                    const Spacer(),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController2,
                        blastDirection: -1.57,
                        emissionFrequency: 0.05,
                        numberOfParticles: 20,
                        maxBlastForce: 10,
                        minBlastForce: 5,
                        colors: [
                          difficultyColor,
                          Colors.white,
                          Colors.yellow,
                          Colors.orange,
                          Colors.pink,
                        ],
                      ),
                    ),

                    Column(
                      children: [
                        AppButton(
                              onPressed: () {
                                context.go(
                                  AppRoutes.game,
                                  extra: widget.difficulty,
                                );
                              },
                              variant: AppButtonVariant.filled,
                              size: AppButtonSize.large,
                              icon: const Icon(Icons.refresh_rounded),
                              child: const Text('Play Next'),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 800.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: AppConstants.spacingMd),
                        AppButton(
                              onPressed: () => context.go(AppRoutes.home),
                              variant: AppButtonVariant.outlined,
                              size: AppButtonSize.large,
                              icon: const Icon(Icons.home_rounded),
                              child: const Text('Main Menu'),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 900.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: AppConstants.spacingMd),
                        AppButton(
                              onPressed: () => context.go(AppRoutes.statistics),
                              variant: AppButtonVariant.tonal,
                              size: AppButtonSize.large,
                              icon: const Icon(Icons.bar_chart_rounded),
                              child: const Text('View Statistics'),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 1000.ms)
                            .slideY(begin: 0.3, end: 0),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacingXl),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0,
              emissionFrequency: 0.02,
              numberOfParticles: 10,
              maxBlastForce: 5,
              minBlastForce: 2,
              colors: [difficultyColor, Colors.white, Colors.yellow],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController2,
              blastDirection: 3.14,
              emissionFrequency: 0.02,
              numberOfParticles: 10,
              maxBlastForce: 5,
              minBlastForce: 2,
              colors: [difficultyColor, Colors.white, Colors.yellow],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStat(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: delay.ms)
        .slideY(begin: 0.3, end: 0);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return '${str[0].toUpperCase()}${str.substring(1).toLowerCase()}';
  }
}
