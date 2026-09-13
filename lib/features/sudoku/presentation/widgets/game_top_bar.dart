import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:m6_sudoku/core/routing/app_router.dart';
import 'package:m6_sudoku/features/settings/presentation/providers/settings_provider.dart';
import 'package:m6_sudoku/features/sudoku/presentation/providers/game_provider.dart';

/// The row of icon buttons at the top of the merged glass dock (see
/// [GameHeader] and the `GlassSurface` wrapping both in `GameScreen`): back,
/// quick theme cycle, statistics, and settings. Statistics/Settings pause
/// the game timer for the trip and resume it on return.
///
/// These render as plain icons on the dock's own glass, not individual
/// circular cards — the whole row is already one floating glass surface,
/// so a second layer of per-icon "chips" would just be redundant chrome.
class GameTopBar extends ConsumerWidget {
  const GameTopBar({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final backColor =
        theme.brightness == Brightness.dark ? Colors.white : color;

    return Row(
      children: [
        _DockIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          color: backColor,
          onTap: onBack,
        ),
        const Spacer(),
        _DockIconButton(
          icon: Icons.palette_outlined,
          tooltip: 'Theme',
          color: color,
          onTap: () => _cycleTheme(context, ref),
        ),
        _DockIconButton(
          icon: Icons.leaderboard_rounded,
          tooltip: 'Statistics',
          color: color,
          onTap: () => _visit(context, ref, AppRoutes.statistics),
        ),
        _DockIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          color: color,
          onTap: () => _visit(context, ref, AppRoutes.settings),
        ),
      ],
    );
  }

  Future<void> _visit(BuildContext context, WidgetRef ref, String route) async {
    ref.read(timerControllerProvider).pause();
    await context.push(route);
    ref.read(timerControllerProvider).start();
  }

  void _cycleTheme(BuildContext context, WidgetRef ref) {
    const order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
    final current = ref.read(settingsProvider).themeMode;
    final next = order[(order.indexOf(current) + 1) % order.length];
    ref.read(settingsProvider.notifier).updateThemeMode(next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme: ${next.name.capitalize()}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// Required, not optional — an icon-only button with no tooltip has no
  /// accessible name at all (this used to be nullable, defaulting to an
  /// empty-string Tooltip message, which is exactly how the back button on
  /// every gameplay screen ended up silent to screen readers).
  final String tooltip;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 22, color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

extension _ThemeModeCapitalize on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
