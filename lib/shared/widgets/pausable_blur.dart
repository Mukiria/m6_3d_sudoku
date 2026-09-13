import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/motion/springs.dart';

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
    this.maxBlur = 6,
  });

  final bool paused;
  final Widget child;

  /// How far [child] shrinks at full pause — 1.0 is unscaled.
  final double minScale;

  /// Gaussian blur sigma at full pause — 0 is unblurred. Kept low enough
  /// that the puzzle underneath is still faintly legible, not fully
  /// obscured.
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
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // The spring can overshoot past [0, 1] briefly — a deliberate part
        // of its "settle" motion — so anything with no sensible value
        // outside that range (blur sigma, shadow/border alpha) clamps,
        // while the scale itself is left free to overshoot for a slight,
        // springy pop on both shrink and restore.
        final t = _controller.value.clamp(0.0, 1.0);
        final blur = widget.maxBlur * t;

        return Transform.scale(
          scale: lerpDouble(1.0, widget.minScale, _controller.value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // An opaque fill behind the blurred child so the shadow
              // below can only ever show past the child's own edges, never
              // bleed through it — the board underneath is a centered
              // square that doesn't necessarily reach every edge of this
              // box, and without this fill, the letterboxed gap would let
              // the shadow show through raw and unblurred right where the
              // offset pushes it thickest (reading as a stray inner
              // shadow), while the opposite edge stayed clean.
              color: surfaceColor,
              // A drop shadow to the bottom-right only (a positive offset,
              // no spread) rather than an even glow on every side — reads
              // as a card lifted off the surface behind it, not a halo.
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35 * t),
                  blurRadius: 16,
                  offset: Offset(8 * t, 8 * t),
                ),
              ],
            ),
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
