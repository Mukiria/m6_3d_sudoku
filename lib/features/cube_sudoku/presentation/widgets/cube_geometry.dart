import 'dart:math' as math;

import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix3, Matrix4, Vector3;

/// Pure 3D geometry for laying six Sudoku boards onto the faces of a
/// cube: each face's fixed orientation, the camera-facing test used to
/// decide which face is nearest the viewer, and the shortest-path angle
/// math a rotate-or-morph animation needs to pick a sane target.
///
/// Shared by [CubeBrowseView] (the rotatable, always-angled cube) and the
/// browse-to-play morph transition in `CubeGameScreen`, so the two can
/// never disagree about where a given face actually sits.
class CubeGeometry {
  const CubeGeometry._();

  /// Perspective strength shared by [CubeBrowseView] and the browse-to-play
  /// morph, tuned for a chunky, toy-like "object on a table" read. The
  /// morph lerps this down to 0 (a perfectly flat board, matching the
  /// existing Play View exactly) as it completes.
  ///
  /// Negative, not positive: each face is pushed out along its own
  /// (rotated) local +Z by [translate], so the front face sits at
  /// z = +radius and an adjacent face's far outer edge sits at
  /// z = -radius — nearer the origin than the shared edge it pivots from.
  /// A positive perspective constant treats larger z as *farther*, which
  /// makes that far edge read as closer than the seam it recedes from —
  /// exactly the "viewed from inside the cube" look. Negative flips the
  /// convention so the face translated furthest along +Z (the one facing
  /// the camera) is nearest, matching a real exterior view.
  static const double perspective = -0.0022;

  /// Faces this far past edge-on are skipped entirely in [CubeBrowseView]
  /// — real cube geometry would self-occlude them, and rendering them
  /// anyway produces a degenerate stretch right at edge-on.
  static const double cullThreshold = -0.05;

  static Matrix3 fixedRotation(CubeFace face) {
    switch (face) {
      case CubeFace.front:
        return Matrix3.identity();
      case CubeFace.back:
        return Matrix3.rotationY(math.pi);
      case CubeFace.right:
        return Matrix3.rotationY(math.pi / 2);
      case CubeFace.left:
        return Matrix3.rotationY(-math.pi / 2);
      case CubeFace.top:
        return Matrix3.rotationX(-math.pi / 2);
      case CubeFace.bottom:
        return Matrix3.rotationX(math.pi / 2);
    }
  }

  /// Same rotation as [fixedRotation], as a [Matrix4] for the actual
  /// per-face widget transform.
  static Matrix4 fixedRotationMatrix4(CubeFace face) {
    switch (face) {
      case CubeFace.front:
        return Matrix4.identity();
      case CubeFace.back:
        return Matrix4.rotationY(math.pi);
      case CubeFace.right:
        return Matrix4.rotationY(math.pi / 2);
      case CubeFace.left:
        return Matrix4.rotationY(-math.pi / 2);
      case CubeFace.top:
        return Matrix4.rotationX(-math.pi / 2);
      case CubeFace.bottom:
        return Matrix4.rotationX(math.pi / 2);
    }
  }

  /// The (yaw, pitch) that brings [face] to sit exactly flat toward the
  /// viewer and upright — the inverse of its fixed rotation, decomposed
  /// back into the same yaw/pitch parametrization the drag gesture and
  /// the morph transition both use.
  static ({double yaw, double pitch}) canonicalOrientation(CubeFace face) {
    switch (face) {
      case CubeFace.front:
        return (yaw: 0.0, pitch: 0.0);
      case CubeFace.back:
        return (yaw: math.pi, pitch: 0.0);
      case CubeFace.right:
        return (yaw: -math.pi / 2, pitch: 0.0);
      case CubeFace.left:
        return (yaw: math.pi / 2, pitch: 0.0);
      case CubeFace.top:
        return (yaw: 0.0, pitch: math.pi / 2);
      case CubeFace.bottom:
        return (yaw: 0.0, pitch: -math.pi / 2);
    }
  }

  static Matrix3 overallRotation(double yaw, double pitch) {
    return Matrix3.rotationY(yaw).multiplied(Matrix3.rotationX(pitch));
  }

  static Vector3 worldNormal(CubeFace face, double yaw, double pitch) {
    final r = overallRotation(yaw, pitch).multiplied(fixedRotation(face));
    return Vector3(0, 0, 1)..applyMatrix3(r);
  }

  /// Whichever face's outward normal currently points most toward the
  /// viewer at this (yaw, pitch) — the face a pinch-out or tap would
  /// select.
  static CubeFace mostFacingCamera(double yaw, double pitch) {
    var best = CubeFace.front;
    var bestZ = double.negativeInfinity;
    for (final face in CubeFace.values) {
      final z = worldNormal(face, yaw, pitch).z;
      if (z > bestZ) {
        bestZ = z;
        best = face;
      }
    }
    return best;
  }

  /// The shortest signed distance from [from] to [to] around the circle —
  /// e.g. from 170° to -170° is +20°, not -340°, so an animation toward
  /// [to] always takes the short way around.
  static double angleDelta(double from, double to) {
    var delta = (to - from) % (2 * math.pi);
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    return delta;
  }

  /// A value reachable from [from] by the shortest path that is
  /// numerically equal (mod 2π) to [to] — feed this as a `Tween`'s `end`
  /// so the tween itself sweeps the short way around instead of the long
  /// way whenever [to] happens to be numerically smaller/larger than
  /// [from] on the wrong side of a wrap.
  static double unwrappedTarget(double from, double to) {
    return from + angleDelta(from, to);
  }
}
