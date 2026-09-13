import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Named spring presets standing in for Liquid Glass's "give" — content
/// that settles into place rather than easing along a fixed timeline.
/// Reused across every glass surface's arrival/dismissal so a single
/// tuning pass (mass/stiffness/damping) reaches every screen at once.
class Springs {
  Springs._();

  /// Sheets, cards, docks settling into place.
  static const SpringDescription gentle = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 20,
  );

  /// Button presses and other short, immediate feedback.
  static const SpringDescription snappy = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 24,
  );

  /// A visible overshoot on arrival — the pause sheet, an achievement pop.
  static const SpringDescription bouncy = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 14,
  );
}

/// Adapts a [SpringDescription] to Flutter's [Curve] API so existing
/// `AnimationController`-driven call sites (`CurvedAnimation`,
/// `AnimatedBuilder` reading `curve.transform(controller.value)`, and the
/// like) can opt into spring motion without restructuring.
///
/// [settleSeconds] is the simulated spring's own timeline, sampled across
/// the controller's `[0, 1]` — it does not need to match the controller's
/// configured `duration`, but should be chosen close to it so the curve
/// isn't stretched or truncated relative to how the spring actually settles.
class SpringCurve extends Curve {
  SpringCurve({required SpringDescription spring, this.settleSeconds = 0.9})
    : _simulation = SpringSimulation(spring, 0, 1, 0);

  final double settleSeconds;
  final SpringSimulation _simulation;

  @override
  double transformInternal(double t) => _simulation.x(t * settleSeconds);
}

/// Convenience for driving an [AnimationController] with a spring directly,
/// rather than via a [SpringCurve] sampled over a fixed-duration curve.
extension SpringAnimationController on AnimationController {
  /// Animates from the controller's current value to [target] under
  /// [spring] physics, ignoring the controller's configured `duration`
  /// (the spring's own physics determines how long this takes).
  TickerFuture animateWithSpring(
    SpringDescription spring, {
    double target = 1,
    double velocity = 0,
  }) {
    return animateWith(SpringSimulation(spring, value, target, velocity));
  }
}
