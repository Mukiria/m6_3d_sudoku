import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Design tokens for the Liquid-Glass-style material used by [GlassSurface]
/// and its retrofitted widgets. Kept separate from [AppThemeExtension]
/// deliberately: this extension governs container material only (blur,
/// tint, corner treatment) — every semantic color (cell states, difficulty
/// tiers, mistakes/hints) stays exactly where it already lives.
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.blurSigma,
    required this.cornerRadius,
    required this.squircleSmoothing,
    required this.tint,
    required this.tintStrong,
    required this.specularHighlight,
    required this.borderHighlight,
    required this.shadowColor,
  });

  /// Gaussian blur sigma applied to whatever sits behind a glass surface.
  final double blurSigma;

  /// Default corner radius for a glass surface's squircle shape.
  final double cornerRadius;

  /// 0 = ordinary rounded-rect corner, 1 = maximally flattened/squircled.
  final double squircleSmoothing;

  /// Base translucent fill — used by [GlassVariant.regular] surfaces
  /// (bars, docks, cards).
  final Color tint;

  /// A more opaque fill for surfaces that need to read clearly over
  /// busy content — sheets and modals ([GlassVariant.strong]).
  final Color tintStrong;

  /// Top-left gradient stop standing in for a specular light source,
  /// since Flutter has no real-time refraction to catch actual light.
  final Color specularHighlight;

  /// 1px edge color that gives a glass surface a defined boundary once
  /// blur has softened whatever's behind it.
  final Color borderHighlight;

  /// Drop shadow lifting a glass surface off the layer beneath it.
  final Color shadowColor;

  static const GlassTokens light = GlassTokens(
    blurSigma: 22,
    cornerRadius: 10,
    squircleSmoothing: 0.6,
    tint: Color(0x8CFFFFFF),
    tintStrong: Color(0xC7FFFFFF),
    specularHighlight: Color(0xE6FFFFFF),
    borderHighlight: Color(0xF2FFFFFF),
    shadowColor: Color(0x24182142),
  );

  static const GlassTokens dark = GlassTokens(
    blurSigma: 22,
    cornerRadius: 10,
    squircleSmoothing: 0.6,
    tint: Color(0x0EFFFFFF),
    tintStrong: Color(0x1AFFFFFF),
    specularHighlight: Color(0x38FFFFFF),
    borderHighlight: Color(0x29FFFFFF),
    shadowColor: Color(0x73000000),
  );

  /// Convenience accessor — falls back to [light] if the current theme
  /// never registered this extension (keeps early-adoption call sites
  /// from crashing while the retrofit is still in progress).
  static GlassTokens of(BuildContext context) {
    return Theme.of(context).extension<GlassTokens>() ?? light;
  }

  @override
  GlassTokens copyWith({
    double? blurSigma,
    double? cornerRadius,
    double? squircleSmoothing,
    Color? tint,
    Color? tintStrong,
    Color? specularHighlight,
    Color? borderHighlight,
    Color? shadowColor,
  }) {
    return GlassTokens(
      blurSigma: blurSigma ?? this.blurSigma,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      squircleSmoothing: squircleSmoothing ?? this.squircleSmoothing,
      tint: tint ?? this.tint,
      tintStrong: tintStrong ?? this.tintStrong,
      specularHighlight: specularHighlight ?? this.specularHighlight,
      borderHighlight: borderHighlight ?? this.borderHighlight,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t)!,
      squircleSmoothing:
          lerpDouble(squircleSmoothing, other.squircleSmoothing, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      tintStrong: Color.lerp(tintStrong, other.tintStrong, t)!,
      specularHighlight:
          Color.lerp(specularHighlight, other.specularHighlight, t)!,
      borderHighlight: Color.lerp(borderHighlight, other.borderHighlight, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}
