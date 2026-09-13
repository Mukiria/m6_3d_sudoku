import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/core/theme/glass_tokens.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_button_surface.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconPosition = IconPosition.start,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.glassTint,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final IconPosition iconPosition;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// A solid fill, ignoring glass entirely — for a button that must read
  /// as fully opaque regardless of what's behind it.
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// An accent-tinted glass fill (its own alpha included) — for a primary
  /// CTA that should still read as "the brand-colored button" while
  /// remaining glass. Ignored if [backgroundColor] is also set.
  final Color? glassTint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extension = theme.extension<AppThemeExtension>()!;

    final effectiveOnPressed = (isDisabled || isLoading) ? null : onPressed;

    final buttonHeight = height ?? _getButtonHeight(size);
    final buttonPadding = padding ?? _getButtonPadding(size);
    final buttonBorderRadius = borderRadius ?? 10.0;
    // SquircleBorder (used by GlassButtonSurface, below) pushes its curve's
    // tangent points outward by its own `smoothing` fraction, so a plain
    // BorderRadius.circular(10) elsewhere in the app (a card, a chip) reads
    // noticeably tighter than a same-numbered SquircleBorder corner would —
    // dividing back out by (1 + smoothing) is what makes a glass button's
    // curve actually look like 10, not ~16.
    final glassCornerRadius =
        buttonBorderRadius / (1 + GlassTokens.of(context).squircleSmoothing);
    final textStyle = _getTextStyle(theme, size);

    Widget buttonChild =
        isLoading
            ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  variant == AppButtonVariant.filled
                      ? colorScheme.onPrimary
                      : colorScheme.primary,
                ),
              ),
            )
            : _buildChildWithIcon(
              context,
              foregroundColor != null
                  ? textStyle.copyWith(color: foregroundColor)
                  : textStyle,
            );

    switch (variant) {
      case AppButtonVariant.filled:
        final filledButton = FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonBorderRadius),
            ),
            textStyle: textStyle,
            minimumSize: Size(width ?? 0, buttonHeight),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurface.withValues(alpha: 0.12);
              }
              // backgroundColor forces a fully solid fill. Otherwise,
              // transparent lets the GlassSurface wrapping this button
              // (below) show through — tinted if glassTint was given,
              // neutral glass otherwise.
              return backgroundColor ?? Colors.transparent;
            }),
            foregroundColor:
                foregroundColor != null
                    ? WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.disabled)) return null;
                      return foregroundColor;
                    })
                    : null,
          ),
          child: buttonChild,
        );

        return SizedBox(
          width: width,
          height: buttonHeight,
          child:
              backgroundColor != null
                  ? _withButtonShadow(
                    filledButton,
                    tint: backgroundColor!,
                    radius: buttonBorderRadius,
                    enabled: effectiveOnPressed != null,
                  )
                  : GlassButtonSurface(
                    enabled: effectiveOnPressed != null,
                    borderRadius: glassCornerRadius,
                    tintColor: glassTint,
                    child: filledButton,
                  ),
        );
      case AppButtonVariant.outlined:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: _withButtonShadow(
            OutlinedButton(
              onPressed: effectiveOnPressed,
              style: OutlinedButton.styleFrom(
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                textStyle: textStyle,
                minimumSize: Size(width ?? 0, buttonHeight),
                side: BorderSide(
                  color:
                      effectiveOnPressed != null
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                foregroundColor:
                    effectiveOnPressed != null
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
              child: buttonChild,
            ),
            tint: colorScheme.primary,
            radius: buttonBorderRadius,
            enabled: effectiveOnPressed != null,
            ambientAlpha: 0.12,
            contactAlpha: 0.08,
          ),
        );
      case AppButtonVariant.text:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: TextButton(
            onPressed: effectiveOnPressed,
            style: TextButton.styleFrom(
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              textStyle: textStyle,
              minimumSize: Size(width ?? 0, buttonHeight),
            ),
            child: buttonChild,
          ),
        );
      case AppButtonVariant.elevated:
        return SizedBox(
          width: width,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              textStyle: textStyle,
              minimumSize: Size(width ?? 0, buttonHeight),
            ),
            child: buttonChild,
          ),
        );
      case AppButtonVariant.tonal:
        final tonalButton = FilledButton.tonal(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonBorderRadius),
            ),
            textStyle: textStyle,
            minimumSize: Size(width ?? 0, buttonHeight),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurface.withValues(alpha: 0.12);
              }
              return Colors.transparent;
            }),
          ),
          child: buttonChild,
        );

        return SizedBox(
          width: width,
          height: buttonHeight,
          child: GlassButtonSurface(
            enabled: effectiveOnPressed != null,
            borderRadius: glassCornerRadius,
            tintColor: glassTint,
            child: tonalButton,
          ),
        );
    }
  }

  /// The same soft-ambient-plus-tight-contact shadow pairing [GlassSurface]
  /// casts, reused here for the button variants that render as plain
  /// [RoundedRectangleBorder]s rather than going through glass — [tint]
  /// keeps each one's shadow color matched to what it's actually casting a
  /// shadow FOR (a solid button's own fill, an outlined button's accent
  /// border) instead of a flat generic grey underneath everything.
  Widget _withButtonShadow(
    Widget child, {
    required Color tint,
    required double radius,
    required bool enabled,
    double ambientAlpha = 0.22,
    double contactAlpha = 0.14,
  }) {
    if (!enabled) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: ambientAlpha),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: tint.withValues(alpha: contactAlpha),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildChildWithIcon(BuildContext context, TextStyle textStyle) {
    if (icon == null) return DefaultTextStyle(style: textStyle, child: child);

    final iconSize = _getIconSize(size);
    const spacing = 8.0;

    return DefaultTextStyle(
      style: textStyle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconPosition == IconPosition.start) ...[
            IconTheme(
              data: IconThemeData(size: iconSize, color: textStyle.color),
              child: icon!,
            ),
            const SizedBox(width: spacing),
          ],
          Flexible(child: child),
          if (iconPosition == IconPosition.end) ...[
            const SizedBox(width: spacing),
            IconTheme(
              data: IconThemeData(size: iconSize, color: textStyle.color),
              child: icon!,
            ),
          ],
        ],
      ),
    );
  }

  double _getButtonHeight(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsetsGeometry _getButtonPadding(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  TextStyle _getTextStyle(ThemeData theme, AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return theme.textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case AppButtonSize.medium:
        return theme.textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w600,
        );
      case AppButtonSize.large:
        return theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
    }
  }

  double _getIconSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
    }
  }
}

enum AppButtonVariant { filled, outlined, text, elevated, tonal }

enum AppButtonSize { small, medium, large }

enum IconPosition { start, end }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 48,
    this.iconSize = 24,
    this.isDisabled = false,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.splashRadius,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final double size;
  final double iconSize;
  final bool isDisabled;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double? borderRadius;
  final double? splashRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveOnPressed = isDisabled ? null : onPressed;
    final effectiveColor = color ?? colorScheme.onSurface;
    final effectiveBackgroundColor = backgroundColor ?? Colors.transparent;
    final effectiveBorderRadius = borderRadius ?? 10.0;

    Widget button = IconButton(
      onPressed: effectiveOnPressed,
      icon: IconTheme(
        data: IconThemeData(size: iconSize, color: effectiveColor),
        child: icon,
      ),
      style: IconButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveColor,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        disabledBackgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
      ),
      tooltip: tooltip,
      splashRadius: splashRadius,
    );

    return SizedBox(width: size, height: size, child: Center(child: button));
  }
}

class AppFloatingActionButton extends StatelessWidget {
  const AppFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4,
    this.focusElevation = 6,
    this.hoverElevation = 8,
    this.highlightElevation = 10,
    this.shape,
    this.isExtended = false,
    this.extendedPadding,
    this.extendedTextStyle,
    this.extendedIcon,
    this.extendedLabel,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double focusElevation;
  final double hoverElevation;
  final double highlightElevation;
  final ShapeBorder? shape;
  final bool isExtended;
  final EdgeInsetsGeometry? extendedPadding;
  final TextStyle? extendedTextStyle;
  final Widget? extendedIcon;
  final Widget? extendedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isExtended) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? colorScheme.primary,
        foregroundColor: foregroundColor ?? colorScheme.onPrimary,
        elevation: elevation,
        focusElevation: focusElevation,
        hoverElevation: hoverElevation,
        highlightElevation: highlightElevation,
        shape:
            shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        extendedPadding:
            extendedPadding ??
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        extendedTextStyle:
            extendedTextStyle ??
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        icon: extendedIcon,
        label: extendedLabel ?? child,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? colorScheme.primary,
      foregroundColor: foregroundColor ?? colorScheme.onPrimary,
      elevation: elevation,
      focusElevation: focusElevation,
      hoverElevation: hoverElevation,
      highlightElevation: highlightElevation,
      shape:
          shape ??
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }
}
