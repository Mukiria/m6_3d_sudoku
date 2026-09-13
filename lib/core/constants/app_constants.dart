class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'M6 Sudoku';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String bundleId = 'com.m6.sudoku';

  // Storage Keys
  static const String keyCurrentGame = 'current_game';
  static const String keyGameSettings = 'game_settings';
  static const String keyStatistics = 'statistics';
  static const String keyCompletedPuzzles = 'completed_puzzles';
  static const String keySelectedDifficulty = 'selected_difficulty';
  static const String keyThemeMode = 'theme_mode';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticsEnabled = 'haptics_enabled';
  static const String keyAutoNotes = 'auto_notes';
  static const String keyHighlightErrors = 'highlight_errors';
  static const String keyShowTimer = 'show_timer';
  static const String keyShowHints = 'show_hints';
  static const String keyAutoClearNotes = 'auto_clear_notes';
  static const String keyHighlightRegions = 'highlight_regions';
  static const String keyNumberFirstInput = 'number_first_input';
  static const String keyHapticFeedback = 'haptic_feedback';
  static const String keySoundEffects = 'sound_effects';
  static const String keyAutoSave = 'auto_save';
  static const String keyShowMistakes = 'show_mistakes';
  static const String keyHighlightRelated = 'highlight_related';
  static const String keyAutoNotesEnabled = 'auto_notes_enabled';
  static const String keyAutoSaveEnabled = 'auto_save_enabled';
  static const String keySelectedTheme = 'selected_theme';
  static const String keyHapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const String keySoundEffectsEnabled = 'sound_effects_enabled';

  // Difficulty Levels
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';
  static const String difficultyExpert = 'expert';
  static const List<String> difficulties = [
    difficultyEasy,
    difficultyMedium,
    difficultyHard,
    difficultyExpert,
  ];

  // Difficulty Display Names
  static const Map<String, String> difficultyNames = {
    difficultyEasy: 'Easy',
    difficultyMedium: 'Medium',
    difficultyHard: 'Hard',
    difficultyExpert: 'Expert',
  };

  // Difficulty Clue Counts
  static const Map<String, int> difficultyClues = {
    difficultyEasy: 36,
    difficultyMedium: 30,
    difficultyHard: 26,
    difficultyExpert: 22,
  };

  // Grid Constants
  static const int gridSize = 9;
  static const int subGridSize = 3;
  static const int totalCells = 81;
  static const int minClues = 17;
  static const int maxClues = 36;

  // Fonts
  static const String fontFamily = 'Inter';

  // Grid Size (for UI)
  static const double gridSizePx = 360.0;

  // Border Radius
  static const double borderRadius = 10.0;
  static const double smallBorderRadius = 10.0;
  static const double largeBorderRadius = 10.0;

  // Button Dimensions
  static const double buttonHeight = 48.0;
  static const double buttonMinWidth = 88.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 100);
  static const Duration normalAnimation = Duration(milliseconds: 200);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  // Puzzle Generation
  static const int minGivens = 17;
  static const int maxGivens = 36;

  // Statistics Keys
  static const String statGamesPlayed = 'games_played';
  static const String statGamesWon = 'games_won';
  static const String statBestTimeEasy = 'best_time_easy';
  static const String statBestTimeMedium = 'best_time_medium';
  static const String statBestTimeHard = 'best_time_hard';
  static const String statBestTimeExpert = 'best_time_expert';
  static const String statCurrentStreak = 'current_streak';
  static const String statBestStreak = 'best_streak';
  static const String statTotalTime = 'total_time';
  static const String statHintsUsed = 'hints_used';
  static const String statMistakesMade = 'mistakes_made';

  // Deep Links
  static const String deepLinkScheme = 'm6sudoku';
  static const String deepLinkHost = 'game';
  static const String deepLinkPathNewGame = 'new';
  static const String deepLinkPathContinue = 'continue';
  static const String deepLinkPathStats = 'stats';
  static const String deepLinkPathSettings = 'settings';
}
