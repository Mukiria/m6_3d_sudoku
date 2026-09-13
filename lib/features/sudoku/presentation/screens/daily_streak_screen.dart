import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';

const List<String> _weekdayLabels = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

/// Flat backdrop color for this screen — matches Home's.
const Color _backgroundColor = Color(0xFFFFFBF2);

/// Text color for content laid directly over [_backgroundColor], no scrim
/// behind it.
const Color _textColor = Color(0xFF2C2A28);

/// Shown once, right after the first puzzle of the day is completed —
/// celebrates the player's current daily streak (consecutive days with at
/// least one puzzle completed) with this week's progress at a glance.
class DailyStreakScreen extends StatelessWidget {
  const DailyStreakScreen({
    super.key,
    required this.currentStreak,
    required this.completedWeekdays,
    required this.todayWeekday,
  });

  final int currentStreak;
  final Set<int> completedWeekdays;

  /// Sunday=0 .. Saturday=6. Days after this one haven't happened yet this
  /// week, so they're rendered as upcoming rather than missed.
  final int todayWeekday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Same flat backdrop color as the Home screen, for a consistent
      // identity across the app's "moment" screens.
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            children: [
              const SizedBox(height: AppConstants.spacingXl),

              Text(
                'Daily Streak',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _textColor,
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: AppConstants.spacingXl),

              _SunBadge(
                streak: currentStreak,
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: AppConstants.spacingXl),

              _WeekStrip(
                    completedWeekdays: completedWeekdays,
                    todayWeekday: todayWeekday,
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: AppConstants.spacingXl),

              Text(
                    'You\'re one grid closer to Sudoku mastery!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _textColor.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const Spacer(),

              AppButton(
                    onPressed: () => context.go(AppRoutes.home),
                    variant: AppButtonVariant.filled,
                    size: AppButtonSize.large,
                    backgroundColor: AppThemeExtension.brandOrange,
                    foregroundColor: Colors.white,
                    width: double.infinity,
                    child: const Text('Continue'),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: AppConstants.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SunBadge extends StatelessWidget {
  const _SunBadge({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
                Icons.wb_sunny_rounded,
                size: 220,
                color: AppThemeExtension.brandOrange,
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2200.ms, delay: 800.ms),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.completedWeekdays,
    required this.todayWeekday,
  });

  final Set<int> completedWeekdays;
  final int todayWeekday;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final isPast = i <= todayWeekday;
          final isCompleted = completedWeekdays.contains(i);

          return Column(
            children: [
              Text(
                _weekdayLabels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color:
                      isPast ? _textColor : _textColor.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isCompleted
                          ? AppThemeExtension.brandOrange
                          : Colors.black.withValues(alpha: 0.08),
                ),
                child:
                    isCompleted
                        ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: Colors.white,
                        )
                        : null,
              ),
            ],
          );
        }),
      ),
    );
  }
}
