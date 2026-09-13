import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';

/// A drop-in [AppBar] replacement carrying the app-wide header treatment —
/// [AppThemeExtension.headerGradient] painted behind it instead of the
/// flat fill a plain [AppBar] would otherwise take from [AppBarTheme].
/// Colors, text style, and height still come from that same shared
/// [AppBarTheme] (in app_theme.dart); this only adds the gradient a
/// theme's flat `backgroundColor` can't express.
///
/// Use wherever a screen would otherwise write `Scaffold(appBar:
/// AppBar(...))`. For a scrolling header inside a [CustomScrollView] (see
/// StatisticsScreen), apply the same treatment directly to a [SliverAppBar]
/// instead — `backgroundColor: Colors.transparent` plus a `flexibleSpace`
/// painted with [AppThemeExtension.headerGradient].
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
      // AppBar lays flexibleSpace out with StackFit.passthrough — under the
      // loose height constraints that gives a childless decoration, it
      // shrinks to zero-height (invisible) rather than filling the bar.
      // SizedBox.expand forces it to actually claim the available space.
      flexibleSpace: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: AppThemeExtension.headerGradient),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
