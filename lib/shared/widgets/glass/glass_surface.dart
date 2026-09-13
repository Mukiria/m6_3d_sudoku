import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/theme/glass_tokens.dart';
import 'package:m6_sudoku/shared/widgets/glass/squircle_border.dart';

/// How opaque a [GlassSurface] reads. [regular] suits bars, docks, and
/// cards sitting over other content; [strong] suits sheets and modals that
/// need to stay legible on their own.
enum GlassVariant { regular, strong }

/// The shared material primitive behind every "glass" surface in the app —
/// a squircle-clipped, blurred, tinted panel with a specular highlight and
/// edge line standing in for Liquid Glass's real-time refraction, which
/// Flutter has no equivalent for. Built once so a material change (a blur
/// tune, a tint adjustment) reaches every screen that uses it at once.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.variant = GlassVariant.regular,
    this.cornerRadius,
    this.blurSigma,
    this.tintColor,
    this.padding,
    this.margin,
    this.elevatedShadow = true,
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomLeftRadius,
    this.bottomRightRadius,
  });

  final Widget child;
  final GlassVariant variant;

  /// Overrides [GlassTokens.cornerRadius] for this surface.
  final double? cornerRadius;

  /// Per-corner overrides of [cornerRadius] — for a bottom sheet that
  /// should round only its top edge, say (`bottomLeftRadius: 0,
  /// bottomRightRadius: 0`). Each defaults to [cornerRadius] when null.
  final double? topLeftRadius;
  final double? topRightRadius;
  final double? bottomLeftRadius;
  final double? bottomRightRadius;

  /// Overrides [GlassTokens.blurSigma] for this surface.
  final double? blurSigma;

  /// Overrides the neutral [variant]-based tint with a caller-supplied
  /// color (its own alpha included) — an accent-tinted glass surface
  /// (a primary CTA, say) rather than the neutral default.
  final Color? tintColor;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// Whether this surface casts the standard "floating" drop shadow.
  /// Disable for a glass surface nested inside another (e.g. a chip on a
  /// glass bar), where a second shadow would just muddy the first.
  final bool elevatedShadow;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final radius = cornerRadius ?? tokens.cornerRadius;
    final sigma = blurSigma ?? tokens.blurSigma;
    final tint =
        tintColor ??
        (variant == GlassVariant.strong ? tokens.tintStrong : tokens.tint);
    final shape = SquircleBorder(
      cornerRadius: radius,
      smoothing: tokens.squircleSmoothing,
      side: BorderSide(color: tokens.borderHighlight, width: 1),
      topLeftRadius: topLeftRadius,
      topRightRadius: topRightRadius,
      bottomLeftRadius: bottomLeftRadius,
      bottomRightRadius: bottomRightRadius,
    );

    // Isolated in its own compositing layer so the expensive BackdropFilter
    // blur only re-runs when the material itself changes (theme, size) —
    // not every time this surface's own content repaints (a ticking timer,
    // say), which would otherwise force the whole card to re-blur every
    // frame that content updates. child is a sibling painted after this
    // layer, not blurred by it either way (BackdropFilter only blurs
    // what's already behind it, never its own descendants) — moving it out
    // just keeps its repaints from touching the blur layer at all.
    final blurLayer = RepaintBoundary(
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          // Two separate layers, not one BoxDecoration with both `color`
          // and `gradient` set — Flutter paints the gradient INSTEAD OF
          // the color when both are given, which would silently drop the
          // tint fill and leave only a highlight fading to full
          // transparency.
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: tint),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient:
                        tintColor != null
                            // An accent-tinted surface (an orange CTA, say)
                            // lightens its own tint toward the top instead
                            // of washing out toward white — a top-to-bottom
                            // "light orange to orange" sheen that stays
                            // on-brand, rather than a highlight that reads
                            // as a totally different (white) surface
                            // peeking through.
                            ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.lerp(tintColor, Colors.white, 0.35)!,
                                tintColor!.withValues(alpha: 0),
                              ],
                            )
                            : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.6],
                              colors: [
                                tokens.specularHighlight,
                                tokens.specularHighlight.withValues(alpha: 0),
                              ],
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget content = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: blurLayer),
        Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ],
    );

    content = DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: elevatedShadow ? _shadowsFor(tintColor, tokens) : null,
      ),
      child: content,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }

  /// A soft, wide ambient layer plus a tighter, closer contact layer —
  /// together they read as a single natural shadow rather than a flat
  /// silhouette, the way one big blurred BoxShadow alone tends to.
  /// Colored from [tint] when this surface has one (an accent CTA casting
  /// an orange-tinted shadow rather than a generic grey one underneath it)
  /// so the shadow itself feels like it belongs to that surface, not a
  /// one-size-fits-all default.
  List<BoxShadow> _shadowsFor(Color? tint, GlassTokens tokens) {
    final ambient = tint?.withValues(alpha: 0.22) ?? tokens.shadowColor;
    final contact =
        tint?.withValues(alpha: 0.14) ??
        tokens.shadowColor.withValues(alpha: tokens.shadowColor.a * 0.6);
    return [
      BoxShadow(
        color: ambient,
        blurRadius: 24,
        offset: const Offset(0, 10),
        spreadRadius: -4,
      ),
      BoxShadow(color: contact, blurRadius: 6, offset: const Offset(0, 2)),
    ];
  }
}
