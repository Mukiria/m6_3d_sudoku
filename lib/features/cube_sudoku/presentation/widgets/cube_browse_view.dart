import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/cube_sudoku/presentation/widgets/cube_geometry.dart';

/// The cube shown as a real 3D object at a fixed, always-angled "product
/// shot" camera position — two or three faces visible at once, the way a
/// physical cube sitting on a table would look. Purely a browsing/
/// orientation surface: nothing on it is ever tappable at the cell level
/// (see [CubeGameScreen]'s `_buildFaceContent`, always called with
/// `isInteractive: false` here) — a face becomes playable only once the
/// morph transition has carried it to full-screen. That split is what
/// lets this view be as densely detailed and steeply angled as a maze-
/// cube game's — nothing here needs to stay legible or precisely
/// tappable the way a flat, played Sudoku board does.
///
/// Driven entirely by [yaw]/[pitch] props rather than owning its own
/// gesture state, so the parent screen can read the exact same orientation
/// values back out when it needs to know "which face is front-most right
/// now" to start a morph.
class CubeBrowseView extends StatelessWidget {
  const CubeBrowseView({
    super.key,
    required this.yaw,
    required this.pitch,
    required this.cubeSize,
    required this.faceBuilder,
  });

  final double yaw;
  final double pitch;
  final double cubeSize;
  final Widget Function(BuildContext context, CubeFace face) faceBuilder;

  @override
  Widget build(BuildContext context) {
    final visibleFaces =
        CubeFace.values
            .where(
              (face) =>
                  CubeGeometry.worldNormal(face, yaw, pitch).z >
                  CubeGeometry.cullThreshold,
            )
            .toList()
          ..sort(
            (a, b) => CubeGeometry.worldNormal(
              a,
              yaw,
              pitch,
            ).z.compareTo(CubeGeometry.worldNormal(b, yaw, pitch).z),
          );

    // Fills whatever box it's given (the full Browse area, not a tight
    // cubeSize square) so a rotated cube never gets clipped by its own
    // container — only a generous safety net at the very edge of that
    // full area, well clear of the cube itself at every reachable angle.
    return ClipRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _groundShadow(),
          for (final face in visibleFaces) _buildFace(context, face),
        ],
      ),
    );
  }

  /// A soft, blurred ellipse beneath the cube — the same "product shot on
  /// a table" grounding cue a real physical cube would cast, so the object
  /// reads as sitting in front of the camera rather than pasted flat on
  /// the screen.
  ///
  /// Anchored at a fixed offset under the Stack's center (which is also
  /// the cube's own rotation origin, so this stays under it regardless of
  /// yaw) rather than sharing the per-face rotate-and-push-forward
  /// transform: that was tried, since it's what makes a face's own scale
  /// track the cube's rotation correctly, but this app's default camera
  /// tilts to look slightly *up* at the cube (its Bottom face is one of
  /// the three shown by default — see [CubeGameScreen]'s doc on the
  /// default yaw/pitch), and pushing a shadow disc through that same
  /// transform put it *nearer* the camera than the real Bottom face at
  /// exactly that angle: a dark disc rendering in front of the live board
  /// instead of behind it. A fixed offset can't do that; the tradeoff is
  /// tying its strength to pitch instead of true geometry, so it fades
  /// out — rather than track — near a straight-up or straight-down view,
  /// where a real cast shadow would go edge-on or vanish anyway.
  Widget _groundShadow() {
    final levelness = math.cos(pitch).clamp(0.0, 1.0);
    if (levelness <= 0.02) return const SizedBox.shrink();

    return Center(
      child: Transform.translate(
        offset: Offset(0, cubeSize * 0.46 * levelness),
        child: IgnorePointer(
          child: Opacity(
            opacity: levelness,
            child: Container(
              width: cubeSize * 0.9,
              height: cubeSize * 0.26 * levelness,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFace(BuildContext context, CubeFace face) {
    final normalZ = CubeGeometry.worldNormal(face, yaw, pitch).z;
    // How directly this face catches the (overhead, camera-side) light —
    // drives both the soft fade for faces angled away and the per-face
    // gloss overlay below, so the two read as one consistent light source
    // instead of two independent effects.
    final lightness = ((normalZ + 1) / 2).clamp(0.0, 1.0);
    final opacity = (0.55 + lightness * 0.45).clamp(0.0, 1.0);

    final matrix =
        Matrix4.identity()
          ..setEntry(3, 2, CubeGeometry.perspective)
          ..rotateY(yaw)
          ..rotateX(pitch)
          ..multiply(CubeGeometry.fixedRotationMatrix4(face))
          ..translate(0.0, 0.0, cubeSize / 2);

    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: cubeSize,
          height: cubeSize,
          // Deliberately sharp corners, not a per-face ClipRRect: two
          // adjacent faces meet at an exact shared 3D edge (see the
          // geometry doc on CubeGeometry.perspective), so rounding each
          // face's rectangle independently carves a notch out of that
          // shared edge on both sides at once — a visible gap where
          // there should be a seamless cube. A real product's beveled
          // edges are simulated instead by the gloss overlay below,
          // which stays entirely inside each face's own bounds.
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.16 * lightness),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.10 * (1 - lightness)),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: faceBuilder(context, face),
          ),
        ),
      ),
    );
  }
}
