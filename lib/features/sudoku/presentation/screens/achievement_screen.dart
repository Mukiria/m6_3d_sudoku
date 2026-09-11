import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/shared/widgets/buttons.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/sudoku_providers.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/achievement.dart';

class AchievementScreen extends ConsumerWidget {
  const AchievementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;
    final achievementsAsync = ref.watch(achievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements'), centerTitle: true),
      body: achievementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load achievements',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  AppButton(
                    onPressed: () {
                      ref.invalidate(achievementsProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        data: (achievements) => _buildContent(context, achievements),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Achievement> achievements) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;

    // Group by category
    final categories =
        AchievementCategory.values.map((cat) {
          final categoryAchievements =
              achievements.where((a) => a.category == cat).toList();
          return _CategoryGroup(
            category: cat,
            achievements: categoryAchievements,
          );
        }).toList();

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;

    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  extension.difficultyExpertColor.withValues(alpha: 0.1),
                  extension.difficultyHardColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: extension.difficultyExpertColor.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.largeBorderRadius,
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 32,
                        color: extension.difficultyExpertColor,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievements',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$unlockedCount / $totalCount unlocked',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMd),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${((totalCount > 0 ? unlockedCount / totalCount : 0.0) * 100).toInt()}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: extension.difficultyExpertColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    LinearProgressIndicator(
                      value: totalCount > 0 ? unlockedCount / totalCount : 0.0,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        extension.difficultyExpertColor,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(),
              ],
            ),
          ),
        ),
        // Categories
        ...categories
            .map((group) => _buildCategorySliver(context, group))
            .toList(),
      ],
    );
  }

  Widget _buildCategorySliver(BuildContext context, _CategoryGroup group) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;

    if (group.achievements.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingLg,
          AppConstants.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      extension,
                      group.category,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    group.category.displayName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _getCategoryColor(extension, group.category),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${group.achievements.where((a) => a.isUnlocked).length} / ${group.achievements.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingMd),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.spacingMd,
                mainAxisSpacing: AppConstants.spacingMd,
                childAspectRatio: 0.9,
              ),
              itemCount: group.achievements.length,
              itemBuilder: (context, index) {
                final achievement = group.achievements[index];
                return _buildAchievementCard(context, achievement, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Achievement achievement,
    int index,
  ) {
    final theme = Theme.of(context);
    final extension = theme.extension<AppThemeExtension>()!;
    final colorScheme = theme.colorScheme;
    final isUnlocked = achievement.isUnlocked;
    final isSecret = achievement.isSecret && !isUnlocked;

    final progress =
        achievement.targetValue > 0
            ? achievement.currentProgress / achievement.targetValue
            : 0.0;

    return Container(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color:
                isUnlocked
                    ? _getCategoryColor(
                      extension,
                      achievement.category,
                    ).withValues(alpha: 0.1)
                    : colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
            borderRadius: BorderRadius.circular(AppConstants.largeBorderRadius),
            border: Border.all(
              color:
                  isUnlocked
                      ? _getCategoryColor(
                        extension,
                        achievement.category,
                      ).withValues(alpha: 0.3)
                      : colorScheme.outlineVariant,
              width: isUnlocked ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color:
                              isUnlocked
                                  ? _getCategoryColor(
                                    extension,
                                    achievement.category,
                                  ).withValues(alpha: 0.2)
                                  : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isUnlocked
                                    ? _getCategoryColor(
                                      extension,
                                      achievement.category,
                                    )
                                    : colorScheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isSecret && !isUnlocked ? '🔒' : achievement.icon,
                            style: TextStyle(
                              fontSize: isSecret && !isUnlocked ? 28 : 32,
                            ),
                          ),
                        ),
                      )
                      .animate(target: isUnlocked ? 1 : 0)
                      .scale(duration: 400.ms, curve: Curves.elasticOut)
                      .shimmer(duration: 2000.ms, delay: 500.ms),
                  if (isUnlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingMd),
              // Name
              Text(
                    isSecret && !isUnlocked ? '???' : achievement.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color:
                          isUnlocked
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                  .animate(target: isUnlocked ? 1 : 0)
                  .fadeIn(duration: 300.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: AppConstants.spacingXs),
              // Progress bar
              Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isUnlocked
                                  ? _getCategoryColor(
                                    extension,
                                    achievement.category,
                                  )
                                  : colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  )
                  .animate(target: isUnlocked ? 1 : 0)
                  .fadeIn(duration: 300.ms, delay: 300.ms)
                  .scaleX(
                    alignment: Alignment.centerLeft,
                    duration: 500.ms,
                    delay: 300.ms,
                  ),
              const SizedBox(height: AppConstants.spacingXs),
              // Progress text
              Text(
                isUnlocked
                    ? 'Unlocked${achievement.unlockedAt != null ? ' • ${_formatDate(achievement.unlockedAt!)}' : ''}'
                    : '${achievement.currentProgress} / ${achievement.targetValue}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
        .slideY(begin: 0.2, end: 0);
  }

  Color _getCategoryColor(
    AppThemeExtension extension,
    AchievementCategory category,
  ) {
    switch (category) {
      case AchievementCategory.wins:
        return extension.difficultyMediumColor;
      case AchievementCategory.perfect:
        return Colors.amber;
      case AchievementCategory.noHints:
        return Colors.purple;
      case AchievementCategory.difficulty:
        return extension.difficultyExpertColor;
      case AchievementCategory.speed:
        return Colors.orange;
      case AchievementCategory.streak:
        return Colors.red;
      case AchievementCategory.special:
        return Colors.teal;
      case AchievementCategory.cube:
        return AppThemeExtension.brandOrange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _CategoryGroup {
  final AchievementCategory category;
  final List<Achievement> achievements;

  _CategoryGroup({required this.category, required this.achievements});
}
