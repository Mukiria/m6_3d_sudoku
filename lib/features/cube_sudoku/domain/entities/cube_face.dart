/// One of the six faces of a 3D Sudoku cube, each holding its own
/// independent puzzle session (see [CubeGameState]).
enum CubeFace { top, bottom, front, back, left, right }

extension CubeFaceDisplay on CubeFace {
  String get displayName {
    switch (this) {
      case CubeFace.top:
        return 'Top';
      case CubeFace.bottom:
        return 'Bottom';
      case CubeFace.front:
        return 'Front';
      case CubeFace.back:
        return 'Back';
      case CubeFace.left:
        return 'Left';
      case CubeFace.right:
        return 'Right';
    }
  }
}
