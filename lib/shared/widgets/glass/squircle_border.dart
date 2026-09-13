import 'package:flutter/material.dart';

/// A rounded-rect-like [OutlinedBorder] whose corners read closer to iOS's
/// continuous "squircle" curvature than [RoundedRectangleBorder]'s plain
/// circular arcs — flatter along the edges, tighter through the turn.
///
/// This is a practical approximation (each corner is one cubic Bezier whose
/// tangent points are pushed outward from the corner by [smoothing]), not a
/// true superellipse — Flutter has no built-in continuous-corner primitive,
/// and fitting a real superellipse needs iterative numerical solving that
/// isn't worth its cost for a container shape. At `smoothing: 0` this
/// reduces to an ordinary circular-corner rounded rect.
///
/// All four corners share [cornerRadius] unless overridden individually
/// (e.g. `bottomLeftRadius: 0, bottomRightRadius: 0` for a bottom sheet that
/// should round only its top edge) — a plain [cornerRadius] is the common
/// case and reduces to the original single-radius geometry exactly.
class SquircleBorder extends OutlinedBorder {
  const SquircleBorder({
    super.side = BorderSide.none,
    this.cornerRadius = 10,
    this.smoothing = 0.6,
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomLeftRadius,
    this.bottomRightRadius,
  });

  final double cornerRadius;
  final double smoothing;
  final double? topLeftRadius;
  final double? topRightRadius;
  final double? bottomLeftRadius;
  final double? bottomRightRadius;

  double get _tl => topLeftRadius ?? cornerRadius;
  double get _tr => topRightRadius ?? cornerRadius;
  double get _bl => bottomLeftRadius ?? cornerRadius;
  double get _br => bottomRightRadius ?? cornerRadius;

  /// Standard cubic-Bezier approximation constant for a circular arc.
  static const double _kappa = 0.5522847498;

  @override
  SquircleBorder copyWith({
    BorderSide? side,
    double? cornerRadius,
    double? smoothing,
    double? topLeftRadius,
    double? topRightRadius,
    double? bottomLeftRadius,
    double? bottomRightRadius,
  }) {
    return SquircleBorder(
      side: side ?? this.side,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      smoothing: smoothing ?? this.smoothing,
      topLeftRadius: topLeftRadius ?? this.topLeftRadius,
      topRightRadius: topRightRadius ?? this.topRightRadius,
      bottomLeftRadius: bottomLeftRadius ?? this.bottomLeftRadius,
      bottomRightRadius: bottomRightRadius ?? this.bottomRightRadius,
    );
  }

  @override
  ShapeBorder scale(double t) => SquircleBorder(
    side: side.scale(t),
    cornerRadius: cornerRadius * t,
    smoothing: smoothing,
    topLeftRadius: topLeftRadius == null ? null : topLeftRadius! * t,
    topRightRadius: topRightRadius == null ? null : topRightRadius! * t,
    bottomLeftRadius: bottomLeftRadius == null ? null : bottomLeftRadius! * t,
    bottomRightRadius:
        bottomRightRadius == null ? null : bottomRightRadius! * t,
  );

  Path _pathFor(Rect rect) {
    final maxRadius = rect.shortestSide / 2;
    double dFor(double r) => (r * (1 + smoothing)).clamp(0.0, maxRadius);
    double pullbackFor(double r) => r.clamp(0.0, maxRadius) * _kappa;

    final tl = _tl.clamp(0.0, maxRadius);
    final tr = _tr.clamp(0.0, maxRadius);
    final br = _br.clamp(0.0, maxRadius);
    final bl = _bl.clamp(0.0, maxRadius);

    final dTl = dFor(tl);
    final dTr = dFor(tr);
    final dBr = dFor(br);
    final dBl = dFor(bl);
    final pTl = pullbackFor(tl);
    final pTr = pullbackFor(tr);
    final pBr = pullbackFor(br);
    final pBl = pullbackFor(bl);

    return Path()
      ..moveTo(rect.left + dTl, rect.top)
      ..lineTo(rect.right - dTr, rect.top)
      ..cubicTo(
        rect.right - dTr + pTr,
        rect.top,
        rect.right,
        rect.top + dTr - pTr,
        rect.right,
        rect.top + dTr,
      )
      ..lineTo(rect.right, rect.bottom - dBr)
      ..cubicTo(
        rect.right,
        rect.bottom - dBr + pBr,
        rect.right - dBr + pBr,
        rect.bottom,
        rect.right - dBr,
        rect.bottom,
      )
      ..lineTo(rect.left + dBl, rect.bottom)
      ..cubicTo(
        rect.left + dBl - pBl,
        rect.bottom,
        rect.left,
        rect.bottom - dBl + pBl,
        rect.left,
        rect.bottom - dBl,
      )
      ..lineTo(rect.left, rect.top + dTl)
      ..cubicTo(
        rect.left,
        rect.top + dTl - pTl,
        rect.left + dTl - pTl,
        rect.top,
        rect.left + dTl,
        rect.top,
      )
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _pathFor(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _pathFor(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_pathFor(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SquircleBorder &&
        other.side == side &&
        other.cornerRadius == cornerRadius &&
        other.smoothing == smoothing &&
        other.topLeftRadius == topLeftRadius &&
        other.topRightRadius == topRightRadius &&
        other.bottomLeftRadius == bottomLeftRadius &&
        other.bottomRightRadius == bottomRightRadius;
  }

  @override
  int get hashCode => Object.hash(
    side,
    cornerRadius,
    smoothing,
    topLeftRadius,
    topRightRadius,
    bottomLeftRadius,
    bottomRightRadius,
  );
}
