import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:m6_sudoku/core/motion/springs.dart';
import 'package:m6_sudoku/shared/widgets/glass/glass_surface.dart';

/// Wraps a pressable [child] (a [FilledButton], typically) in a
/// [GlassSurface] and adds two microinteractions Liquid Glass buttons are
/// expected to have: a spring-driven press-scale, and a light sheen that
/// sweeps across the surface on release. Purely visual — [child] keeps
/// handling its own taps/semantics/disabled state; this only observes raw
/// pointer events, so it never competes with the child's own gesture
/// recognizer.
class GlassButtonSurface extends StatefulWidget {
  const GlassButtonSurface({
    super.key,
    required this.enabled,
    required this.borderRadius,
    required this.child,
    this.elevatedShadow = true,
    this.tintColor,
  });

  final bool enabled;
  final double borderRadius;
  final Widget child;
  final bool elevatedShadow;

  /// Overrides the neutral glass tint with a caller-supplied accent color
  /// (its own alpha included) — for a primary CTA that should still read
  /// as "the brand-colored button" while remaining glass.
  final Color? tintColor;

  @override
  State<GlassButtonSurface> createState() => _GlassButtonSurfaceState();
}

class _GlassButtonSurfaceState extends State<GlassButtonSurface>
    with TickerProviderStateMixin {
  late final AnimationController _scale = AnimationController(
    vsync: this,
    value: 1,
  );
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void dispose() {
    _scale.dispose();
    _sheen.dispose();
    super.dispose();
  }

  void _press() {
    if (!widget.enabled) return;
    _scale.animateWithSpring(Springs.snappy, target: 0.94);
  }

  void _release() {
    if (!widget.enabled) return;
    _scale.animateWithSpring(Springs.bouncy, target: 1);
    _sheen.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _press(),
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedBuilder(
        animation: _scale,
        builder:
            (context, child) =>
                Transform.scale(scale: _scale.value, child: child),
        child: GlassSurface(
          cornerRadius: widget.borderRadius,
          elevatedShadow: widget.elevatedShadow,
          tintColor: widget.tintColor,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sheen,
                    builder: (context, _) {
                      if (_sheen.isDismissed) return const SizedBox.shrink();
                      return _ButtonSheen(progress: _sheen.value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ButtonSheen extends StatelessWidget {
  const _ButtonSheen({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 200.0;
          final dx = lerpDouble(-width * 0.5, width * 1.3, progress)!;
          final fade = 1 - progress;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: width * 0.3,
                height: constraints.maxHeight * 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.32 * fade),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
