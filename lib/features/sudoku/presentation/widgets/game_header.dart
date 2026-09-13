import 'package:flutter/material.dart';

/// The stat row: difficulty, mistake count, timer, and pause. Undo lives in
/// [NumberPad]'s action row now, so this widget only needs to display state
/// — it has no Riverpod dependency of its own.
///
/// Content only, deliberately — it renders inside the same `GlassSurface`
/// dock as [GameTopBar] (see `GameScreen`), so it no longer owns its own
/// card decoration.
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.difficulty,
    required this.timeElapsed,
    required this.mistakes,
    required this.onPause,
  });

  final String difficulty;
  final int timeElapsed;
  final int mistakes;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Text(
          difficulty.capitalize(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          'Mistake: $mistakes/3',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          _formatTime(timeElapsed),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        IconButton(
          onPressed: onPause,
          icon: const Icon(Icons.pause_rounded),
          tooltip: 'Pause',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
