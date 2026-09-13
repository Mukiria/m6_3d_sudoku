import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

/// A drop-in [AppBar] replacement carrying the app-wide header treatment —
/// a [GlassSurface] tinted brand-orange behind it instead of the flat fill
/// a plain [AppBar] would otherwise take from [AppBarTheme]. Colors, text
/// style, and height still come from that same shared [AppBarTheme] (in
/// app_theme.dart); this only swaps in the actual Liquid Glass material —
/// blur, tint, and the specular sheen — that a theme's flat
/// `backgroundColor` can't express.
///
/// Use wherever a screen would otherwise write `Scaffold(appBar:
/// AppBar(...))`. For a scrolling header inside a [CustomScrollView] (see
/// StatisticsScreen), apply the same treatment directly to a [SliverAppBar]
/// instead — `backgroundColor: Colors.transparent` plus a `flexibleSpace`
/// built from [glassHeaderFlexibleSpace] below.
class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      flexibleSpace: glassHeaderFlexibleSpace(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// The glass panel shared by [AppHeaderBar] and Statistics' [SliverAppBar]
/// — factored out so both stay the exact same material rather than two
/// hand-copied constructions drifting apart.
///
/// AppBar/SliverAppBar lay `flexibleSpace` out with loose constraints
/// (`StackFit.passthrough`); a childless decoration — [GlassSurface]
/// included, since it sizes to its own child — shrinks to zero-height
/// under that rather than filling the bar. The outer [SizedBox.expand]
/// forces it to actually claim the available space; the inner one gives
/// [GlassSurface] a child to size itself against in turn.
Widget glassHeaderFlexibleSpace() {
  return SizedBox.expand(
    child: GlassSurface(
      cornerRadius: 0,
      tintColor: AppThemeExtension.brandOrange.withValues(alpha: 0.85),
      child: const SizedBox.expand(),
    ),
  );
}
