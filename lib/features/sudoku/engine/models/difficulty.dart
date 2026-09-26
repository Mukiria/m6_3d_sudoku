enum Difficulty {
  easy,
  medium,
  hard,
  expert,
  evil;

  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
      case Difficulty.expert:
        return 'Expert';
      case Difficulty.evil:
        return 'Evil';
    }
  }

  int get cluesCount {
    switch (this) {
      case Difficulty.easy:
        return 36;
      case Difficulty.medium:
        return 30;
      case Difficulty.hard:
        return 26;
      case Difficulty.expert:
        return 22;
      case Difficulty.evil:
        return 21;
    }
  }
}
