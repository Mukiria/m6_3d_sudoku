import 'package:flutter/material.dart';
import 'package:m6_sudoku/features/cube_sudoku/domain/entities/cube_face.dart';
import 'package:m6_sudoku/features/sudoku/domain/entities/game_state.dart';

/// Six small tappable markers, one per cube face, showing at a glance which
/// faces are still playing, completed, or failed — and which one is
/// currently open. Tapping a marker jumps straight to that face.
class CubeProgressIndicator extends StatelessWidget {
  const CubeProgressIndicator({
    super.key,
    required this.faceStatuses,
    required this.activeFace,
    required this.onFaceTap,
  });

  final Map<CubeFace, GameStatus> faceStatuses;
  final CubeFace activeFace;
  final void Function(CubeFace face) onFaceTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final face in CubeFace.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _FaceMarker(
              face: face,
              status: faceStatuses[face] ?? GameStatus.playing,
              isActive: face == activeFace,
              onTap: () => onFaceTap(face),
            ),
          ),
      ],
    );
  }
}

class _FaceMarker extends StatelessWidget {
  const _FaceMarker({
    required this.face,
    required this.status,
    required this.isActive,
    required this.onTap,
  });

  final CubeFace face;
  final GameStatus status;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color color;
    final IconData? icon;
    switch (status) {
      case GameStatus.completed:
        color = Colors.green;
        icon = Icons.check_rounded;
        break;
      case GameStatus.failed:
        color = colorScheme.error;
        icon = Icons.close_rounded;
        break;
      case GameStatus.playing:
      case GameStatus.paused:
        color = isActive ? colorScheme.primary : colorScheme.outlineVariant;
        icon = null;
        break;
    }

    return Semantics(
      button: true,
      label:
          '${face.displayName} face, ${_statusLabel(status)}'
          '${isActive ? ', currently open' : ''}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: icon != null ? color : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: isActive && icon == null ? 2.5 : 1.5,
                ),
              ),
              child:
                  icon != null
                      ? Icon(icon, size: 12, color: Colors.white)
                      : null,
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(GameStatus status) {
    switch (status) {
      case GameStatus.completed:
        return 'solved';
      case GameStatus.failed:
        return 'failed';
      case GameStatus.playing:
      case GameStatus.paused:
        return 'in progress';
    }
  }
}
