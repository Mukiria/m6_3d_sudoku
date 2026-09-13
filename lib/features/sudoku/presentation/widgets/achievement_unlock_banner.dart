import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';

/// A self-dismissing "Achievement Unlocked" toast, mounted over gameplay.
/// It watches [achievementUnlockQueueProvider] and shows one entry at a
/// time: slides/fades in, holds, then fades out and advances to the next
/// queued unlock (if any) once its animation completes. Tapping dismisses
/// it early.
class AchievementUnlockBanner extends ConsumerWidget {
  const AchievementUnlockBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(achievementUnlockQueueProvider);
    if (queue.isEmpty) return const SizedBox.shrink();

    final achievement = queue.first;
    final theme = Theme.of(context);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: GestureDetector(
            onTap:
                () =>
                    ref
                        .read(achievementUnlockQueueProvider.notifier)
                        .popFirst(),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      achievement.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ACHIEVEMENT UNLOCKED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            achievement.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .animate(
            key: ValueKey(achievement.id),
            onComplete:
                (_) =>
                    ref
                        .read(achievementUnlockQueueProvider.notifier)
                        .popFirst(),
          )
          .fadeIn(duration: 300.ms)
          .slideY(begin: -0.5, end: 0, curve: Curves.easeOutBack)
          .then(delay: 2200.ms)
          .fadeOut(duration: 400.ms)
          .slideY(begin: 0, end: -0.3, curve: Curves.easeIn),
    );
  }
}
