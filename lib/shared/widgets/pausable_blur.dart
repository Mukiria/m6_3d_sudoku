import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/motion/springs.dart';
import 'package:m6_sudoku/core/theme/glass_tokens.dart';
import 'package:m6_sudoku/shared/widgets/glass/squircle_border.dart';

/// Shrinks and blurs [child] while [paused] is true, animating both in
/// tandem under spring physics — used to hide a puzzle board behind a
/// pause sheet without simply removing it from the tree (an abrupt
/// disappearance reads as a glitch; shrinking into a blur reads as "this
/// paused"). Only [child] itself is affected — anything outside it (a top
/// bar, status readout, number pad) stays exactly as it was, since the
/// point is to hide the puzzle specifically, not dim the whole screen (the
/// pause sheet's own modal barrier already does that).
class PausableBlur extends StatefulWidget {
  const PausableBlur({
    super.key,
    required this.paused,
    required this.child,
    this.minScale = 0.82,
    this.maxBlur = 16,
  });

  final bool paused;
  final Widget child;

  /// How far [child] shrinks at full pause — 1.0 is unscaled.
  final double minScale;

  /// Gaussian blur sigma at full pause — 0 is unblurred.
  final double maxBlur;

  @override
  State<PausableBlur> createState() => _PausableBlurState();
}

class _PausableBlurState extends State<PausableBlur>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.paused ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant PausableBlur oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused != oldWidget.paused) {
      _controller.animateWithSpring(
        Springs.bouncy,
        target: widget.paused ? 1 : 0,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // The spring can overshoot past [0, 1] briefly — a deliberate part
        // of its "settle" motion — so anything with no sensible value
        // outside that range (blur sigma, corner radius, shadow/tint alpha)
        // clamps, while the scale itself is left free to overshoot for a
        // slight, springy pop on both shrink and restore.
        final t = _controller.value.clamp(0.0, 1.0);
        final blur = widget.maxBlur * t;
        // A puzzle's own background is usually near-identical to the
        // screen behind it (a white board on an off-white scaffold, say),
        // so shrinking it in place reads as basically nothing — blur alone
        // dominates what little contrast there was. A glass card frame
        // (tint, specular highlight, edge line, shadow) that fades in as
        // it shrinks turns it into an unmistakable "card receding" instead,
        // independent of whatever colors happen to surround it.
        final radius = tokens.cornerRadius * t;
        final shape = SquircleBorder(
          cornerRadius: radius,
          smoothing: tokens.squircleSmoothing,
          side: BorderSide(
            color: Color.lerp(Colors.transparent, tokens.borderHighlight, t)!,
            width: 1,
          ),
        );

        return Transform.scale(
          scale: lerpDouble(1.0, widget.minScale, _controller.value),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: shape,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35 * t),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: Stack(
                children: [
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: child,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.6],
                            colors: [
                              Color.lerp(
                                Colors.transparent,
                                tokens.specularHighlight,
                                t * 0.6,
                              )!,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
