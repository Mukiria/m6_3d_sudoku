import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/engine/models/difficulty.dart';
import 'package:m6_sudoku/features/sudoku/presentation/widgets/difficulty_picker.dart';

class DifficultySelectionScreen extends ConsumerWidget {
  const DifficultySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Difficulty'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your challenge',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spacingLg),
              Expanded(
                child: ListView.separated(
                  itemCount: Difficulty.values.length,
                  separatorBuilder:
                      (context, index) =>
                          const SizedBox(height: AppConstants.spacingMd),
                  itemBuilder: (context, index) {
                    final difficulty = Difficulty.values[index];
                    final isSelected =
                        settings.selectedDifficulty == difficulty.name;

                    return DifficultyPicker(
                          difficulty: difficulty,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(settingsProvider.notifier)
                                .updateDifficulty(difficulty.name);
                            context.push(
                              AppRoutes.puzzleLoading,
                              extra: difficulty.name,
                            );
                          },
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (index * 100).ms)
                        .slideX(begin: 0.2, end: 0);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
