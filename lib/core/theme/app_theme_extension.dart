import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.cellBackground,
    required this.cellBorder,
    required this.cellSelectedBackground,
    required this.cellSelectedBorder,
    required this.cellErrorBackground,
    required this.cellErrorBorder,
    required this.cellFixedBackground,
    required this.cellFixedBorder,
    required this.cellNoteBackground,
    required this.cellHighlightBackground,
    required this.cellRelatedBackground,
    required this.gridBackgroundColor,
    required this.subGridLineColor,
    required this.numberButtonBackground,
    required this.numberButtonSelectedBackground,
    required this.numberButtonDisabledBackground,
    required this.numberButtonText,
    required this.numberButtonSelectedText,
    required this.numberButtonDisabledText,
    required this.noteButtonBackground,
    required this.noteButtonSelectedBackground,
    required this.noteButtonText,
    required this.noteButtonSelectedText,
    required this.hintButtonBackground,
    required this.hintButtonText,
    required this.undoButtonBackground,
    required this.undoButtonText,
    required this.eraseButtonBackground,
    required this.eraseButtonText,
    required this.timerBackground,
    required this.timerText,
    required this.mistakeIndicatorColor,
    required this.hintIndicatorColor,
    required this.completionBackground,
    required this.completionText,
    required this.progressBackground,
    required this.progressForeground,
    required this.difficultyEasyColor,
    required this.difficultyMediumColor,
    required this.difficultyHardColor,
    required this.difficultyExpertColor,
    required this.difficultyEvilColor,
  });

  /// Fixed brand colors that stay constant across light and dark themes.
  static const Color brandOrange = Color(0xFFF1592B);
  static const Color brandOrangeLight = Color(0xFFFFB74D);
  static const Color brandBlue = Color(0xFF1976D2);

  final Color cellBackground;
  final Color cellBorder;
  final Color cellSelectedBackground;
  final Color cellSelectedBorder;
  final Color cellErrorBackground;
  final Color cellErrorBorder;
  final Color cellFixedBackground;
  final Color cellFixedBorder;
  final Color cellNoteBackground;
  final Color cellHighlightBackground;
  final Color cellRelatedBackground;
  final Color gridBackgroundColor;
  final Color subGridLineColor;
  final Color numberButtonBackground;
  final Color numberButtonSelectedBackground;
  final Color numberButtonDisabledBackground;
  final Color numberButtonText;
  final Color numberButtonSelectedText;
  final Color numberButtonDisabledText;
  final Color noteButtonBackground;
  final Color noteButtonSelectedBackground;
  final Color noteButtonText;
  final Color noteButtonSelectedText;
  final Color hintButtonBackground;
  final Color hintButtonText;
  final Color undoButtonBackground;
  final Color undoButtonText;
  final Color eraseButtonBackground;
  final Color eraseButtonText;
  final Color timerBackground;
  final Color timerText;
  final Color mistakeIndicatorColor;
  final Color hintIndicatorColor;
  final Color completionBackground;
  final Color completionText;
  final Color progressBackground;
  final Color progressForeground;
  final Color difficultyEasyColor;
  final Color difficultyMediumColor;
  final Color difficultyHardColor;
  final Color difficultyExpertColor;
  final Color difficultyEvilColor;

  static const AppThemeExtension light = AppThemeExtension(
    cellBackground: Color(0xFFFFFFFF),
    cellBorder: brandOrangeLight,
    cellSelectedBackground: Color(0xFFE3F2FD),
    cellSelectedBorder: Color(0xFF1976D2),
    cellErrorBackground: Color(0xFFFFCDD2),
    cellErrorBorder: Color(0xFFD32F2F),
    cellFixedBackground: Color(0xFFFFFFFF),
    cellFixedBorder: brandOrangeLight,
    cellNoteBackground: Color(0xFFF5F5F5),
    cellHighlightBackground: Color(0xFFE3F2FD),
    cellRelatedBackground: Color(0xFFBBDEFB),
    gridBackgroundColor: Color(0xFFFFFFFF),
    subGridLineColor: brandOrange,
    numberButtonBackground: Color(0xFFE3F2FD),
    numberButtonSelectedBackground: Color(0xFF1976D2),
    numberButtonDisabledBackground: Color(0xFFE0E0E0),
    numberButtonText: Color(0xFF1976D2),
    numberButtonSelectedText: Color(0xFFFFFFFF),
    numberButtonDisabledText: Color(0xFF9E9E9E),
    noteButtonBackground: Color(0xFFF5F5F5),
    noteButtonSelectedBackground: Color(0xFF1976D2),
    noteButtonText: Color(0xFF757575),
    noteButtonSelectedText: Color(0xFFFFFFFF),
    hintButtonBackground: Color(0xFFE8F5E9),
    hintButtonText: Color(0xFF4CAF50),
    undoButtonBackground: Color(0xFFFFF3E0),
    undoButtonText: Color(0xFFFF9800),
    eraseButtonBackground: Color(0xFFF5F5F5),
    eraseButtonText: Color(0xFF757575),
    timerBackground: Color(0xFFE3F2FD),
    timerText: Color(0xFF1976D2),
    mistakeIndicatorColor: Color(0xFFD32F2F),
    hintIndicatorColor: Color(0xFF4CAF50),
    completionBackground: Color(0xCC000000),
    completionText: Color(0xFFFFFFFF),
    progressBackground: Color(0xFFE0E0E0),
    progressForeground: Color(0xFF1976D2),
    difficultyEasyColor: Color(0xFF4CAF50),
    difficultyMediumColor: Color(0xFFFF9800),
    difficultyHardColor: Color(0xFF1976D2),
    difficultyExpertColor: Color(0xFF9C27B0),
    difficultyEvilColor: Color(0xFFD32F2F),
  );

  static const AppThemeExtension dark = AppThemeExtension(
    cellBackground: Color(0xFF2C2C2C),
    cellBorder: Colors.white,
    cellSelectedBackground: Color(0xFF1565C0),
    cellSelectedBorder: Color(0xFF90CAF9),
    cellErrorBackground: Color(0xFFC62828),
    cellErrorBorder: Color(0xFFEF5350),
    cellFixedBackground: Color(0xFF2C2C2C),
    cellFixedBorder: brandOrangeLight,
    cellNoteBackground: Color(0xFF1E1E1E),
    cellHighlightBackground: Color(0xFF1565C0),
    cellRelatedBackground: Color(0xFF0D47A1),
    gridBackgroundColor: Color(0xFF2C2C2C),
    subGridLineColor: Colors.white,
    numberButtonBackground: Color(0xFF1565C0),
    numberButtonSelectedBackground: Color(0xFF90CAF9),
    numberButtonDisabledBackground: Color(0xFF444444),
    numberButtonText: Color(0xFF90CAF9),
    numberButtonSelectedText: Color(0xFF0D47A1),
    numberButtonDisabledText: Color(0xFF757575),
    noteButtonBackground: Color(0xFF1E1E1E),
    noteButtonSelectedBackground: Color(0xFF90CAF9),
    noteButtonText: Color(0xFFB0B0B0),
    noteButtonSelectedText: Color(0xFF0D47A1),
    hintButtonBackground: Color(0xFF1B5E20),
    hintButtonText: Color(0xFF81C784),
    undoButtonBackground: Color(0xFFE65100),
    undoButtonText: Color(0xFFFFB74D),
    eraseButtonBackground: Color(0xFF1E1E1E),
    eraseButtonText: Color(0xFFB0B0B0),
    timerBackground: Color(0xFF1565C0),
    timerText: Color(0xFF90CAF9),
    mistakeIndicatorColor: Color(0xFFEF5350),
    hintIndicatorColor: Color(0xFF81C784),
    completionBackground: Color(0xCC000000),
    completionText: Color(0xFFFFFFFF),
    progressBackground: Color(0xFF444444),
    progressForeground: Color(0xFF90CAF9),
    difficultyEasyColor: Color(0xFF81C784),
    difficultyMediumColor: Color(0xFFFFB74D),
    difficultyHardColor: Color(0xFF64B5F6),
    difficultyExpertColor: Color(0xFFCE93D8),
    difficultyEvilColor: Color(0xFFEF5350),
  );

  @override
  AppThemeExtension copyWith({
    Color? cellBackground,
    Color? cellBorder,
    Color? cellSelectedBackground,
    Color? cellSelectedBorder,
    Color? cellErrorBackground,
    Color? cellErrorBorder,
    Color? cellFixedBackground,
    Color? cellFixedBorder,
    Color? cellNoteBackground,
    Color? cellHighlightBackground,
    Color? cellRelatedBackground,
    Color? gridBackgroundColor,
    Color? subGridLineColor,
    Color? numberButtonBackground,
    Color? numberButtonSelectedBackground,
    Color? numberButtonDisabledBackground,
    Color? numberButtonText,
    Color? numberButtonSelectedText,
    Color? numberButtonDisabledText,
    Color? noteButtonBackground,
    Color? noteButtonSelectedBackground,
    Color? noteButtonText,
    Color? noteButtonSelectedText,
    Color? hintButtonBackground,
    Color? hintButtonText,
    Color? undoButtonBackground,
    Color? undoButtonText,
    Color? eraseButtonBackground,
    Color? eraseButtonText,
    Color? timerBackground,
    Color? timerText,
    Color? mistakeIndicatorColor,
    Color? hintIndicatorColor,
    Color? completionBackground,
    Color? completionText,
    Color? progressBackground,
    Color? progressForeground,
    Color? difficultyEasyColor,
    Color? difficultyMediumColor,
    Color? difficultyHardColor,
    Color? difficultyExpertColor,
    Color? difficultyEvilColor,
  }) {
    return AppThemeExtension(
      cellBackground: cellBackground ?? this.cellBackground,
      cellBorder: cellBorder ?? this.cellBorder,
      cellSelectedBackground:
          cellSelectedBackground ?? this.cellSelectedBackground,
      cellSelectedBorder: cellSelectedBorder ?? this.cellSelectedBorder,
      cellErrorBackground: cellErrorBackground ?? this.cellErrorBackground,
      cellErrorBorder: cellErrorBorder ?? this.cellErrorBorder,
      cellFixedBackground: cellFixedBackground ?? this.cellFixedBackground,
      cellFixedBorder: cellFixedBorder ?? this.cellFixedBorder,
      cellNoteBackground: cellNoteBackground ?? this.cellNoteBackground,
      cellHighlightBackground:
          cellHighlightBackground ?? this.cellHighlightBackground,
      cellRelatedBackground:
          cellRelatedBackground ?? this.cellRelatedBackground,
      gridBackgroundColor: gridBackgroundColor ?? this.gridBackgroundColor,
      subGridLineColor: subGridLineColor ?? this.subGridLineColor,
      numberButtonBackground:
          numberButtonBackground ?? this.numberButtonBackground,
      numberButtonSelectedBackground:
          numberButtonSelectedBackground ?? this.numberButtonSelectedBackground,
      numberButtonDisabledBackground:
          numberButtonDisabledBackground ?? this.numberButtonDisabledBackground,
      numberButtonText: numberButtonText ?? this.numberButtonText,
      numberButtonSelectedText:
          numberButtonSelectedText ?? this.numberButtonSelectedText,
      numberButtonDisabledText:
          numberButtonDisabledText ?? this.numberButtonDisabledText,
      noteButtonBackground: noteButtonBackground ?? this.noteButtonBackground,
      noteButtonSelectedBackground:
          noteButtonSelectedBackground ?? this.noteButtonSelectedBackground,
      noteButtonText: noteButtonText ?? this.noteButtonText,
      noteButtonSelectedText:
          noteButtonSelectedText ?? this.noteButtonSelectedText,
      hintButtonBackground: hintButtonBackground ?? this.hintButtonBackground,
      hintButtonText: hintButtonText ?? this.hintButtonText,
      undoButtonBackground: undoButtonBackground ?? this.undoButtonBackground,
      undoButtonText: undoButtonText ?? this.undoButtonText,
      eraseButtonBackground:
          eraseButtonBackground ?? this.eraseButtonBackground,
      eraseButtonText: eraseButtonText ?? this.eraseButtonText,
      timerBackground: timerBackground ?? this.timerBackground,
      timerText: timerText ?? this.timerText,
      mistakeIndicatorColor:
          mistakeIndicatorColor ?? this.mistakeIndicatorColor,
      hintIndicatorColor: hintIndicatorColor ?? this.hintIndicatorColor,
      completionBackground: completionBackground ?? this.completionBackground,
      completionText: completionText ?? this.completionText,
      progressBackground: progressBackground ?? this.progressBackground,
      progressForeground: progressForeground ?? this.progressForeground,
      difficultyEasyColor: difficultyEasyColor ?? this.difficultyEasyColor,
      difficultyMediumColor:
          difficultyMediumColor ?? this.difficultyMediumColor,
      difficultyHardColor: difficultyHardColor ?? this.difficultyHardColor,
      difficultyExpertColor:
          difficultyExpertColor ?? this.difficultyExpertColor,
      difficultyEvilColor: difficultyEvilColor ?? this.difficultyEvilColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      cellBackground: Color.lerp(cellBackground, other.cellBackground, t)!,
      cellBorder: Color.lerp(cellBorder, other.cellBorder, t)!,
      cellSelectedBackground:
          Color.lerp(cellSelectedBackground, other.cellSelectedBackground, t)!,
      cellSelectedBorder:
          Color.lerp(cellSelectedBorder, other.cellSelectedBorder, t)!,
      cellErrorBackground:
          Color.lerp(cellErrorBackground, other.cellErrorBackground, t)!,
      cellErrorBorder: Color.lerp(cellErrorBorder, other.cellErrorBorder, t)!,
      cellFixedBackground:
          Color.lerp(cellFixedBackground, other.cellFixedBackground, t)!,
      cellFixedBorder: Color.lerp(cellFixedBorder, other.cellFixedBorder, t)!,
      cellNoteBackground:
          Color.lerp(cellNoteBackground, other.cellNoteBackground, t)!,
      cellHighlightBackground:
          Color.lerp(
            cellHighlightBackground,
            other.cellHighlightBackground,
            t,
          )!,
      cellRelatedBackground:
          Color.lerp(cellRelatedBackground, other.cellRelatedBackground, t)!,
      gridBackgroundColor:
          Color.lerp(gridBackgroundColor, other.gridBackgroundColor, t)!,
      subGridLineColor:
          Color.lerp(subGridLineColor, other.subGridLineColor, t)!,
      numberButtonBackground:
          Color.lerp(numberButtonBackground, other.numberButtonBackground, t)!,
      numberButtonSelectedBackground:
          Color.lerp(
            numberButtonSelectedBackground,
            other.numberButtonSelectedBackground,
            t,
          )!,
      numberButtonDisabledBackground:
          Color.lerp(
            numberButtonDisabledBackground,
            other.numberButtonDisabledBackground,
            t,
          )!,
      numberButtonText:
          Color.lerp(numberButtonText, other.numberButtonText, t)!,
      numberButtonSelectedText:
          Color.lerp(
            numberButtonSelectedText,
            other.numberButtonSelectedText,
            t,
          )!,
      numberButtonDisabledText:
          Color.lerp(
            numberButtonDisabledText,
            other.numberButtonDisabledText,
            t,
          )!,
      noteButtonBackground:
          Color.lerp(noteButtonBackground, other.noteButtonBackground, t)!,
      noteButtonSelectedBackground:
          Color.lerp(
            noteButtonSelectedBackground,
            other.noteButtonSelectedBackground,
            t,
          )!,
      noteButtonText: Color.lerp(noteButtonText, other.noteButtonText, t)!,
      noteButtonSelectedText:
          Color.lerp(noteButtonSelectedText, other.noteButtonSelectedText, t)!,
      hintButtonBackground:
          Color.lerp(hintButtonBackground, other.hintButtonBackground, t)!,
      hintButtonText: Color.lerp(hintButtonText, other.hintButtonText, t)!,
      undoButtonBackground:
          Color.lerp(undoButtonBackground, other.undoButtonBackground, t)!,
      undoButtonText: Color.lerp(undoButtonText, other.undoButtonText, t)!,
      eraseButtonBackground:
          Color.lerp(eraseButtonBackground, other.eraseButtonBackground, t)!,
      eraseButtonText: Color.lerp(eraseButtonText, other.eraseButtonText, t)!,
      timerBackground: Color.lerp(timerBackground, other.timerBackground, t)!,
      timerText: Color.lerp(timerText, other.timerText, t)!,
      mistakeIndicatorColor:
          Color.lerp(mistakeIndicatorColor, other.mistakeIndicatorColor, t)!,
      hintIndicatorColor:
          Color.lerp(hintIndicatorColor, other.hintIndicatorColor, t)!,
      completionBackground:
          Color.lerp(completionBackground, other.completionBackground, t)!,
      completionText: Color.lerp(completionText, other.completionText, t)!,
      progressBackground:
          Color.lerp(progressBackground, other.progressBackground, t)!,
      progressForeground:
          Color.lerp(progressForeground, other.progressForeground, t)!,
      difficultyEasyColor:
          Color.lerp(difficultyEasyColor, other.difficultyEasyColor, t)!,
      difficultyMediumColor:
          Color.lerp(difficultyMediumColor, other.difficultyMediumColor, t)!,
      difficultyHardColor:
          Color.lerp(difficultyHardColor, other.difficultyHardColor, t)!,
      difficultyExpertColor:
          Color.lerp(difficultyExpertColor, other.difficultyExpertColor, t)!,
      difficultyEvilColor:
          Color.lerp(difficultyEvilColor, other.difficultyEvilColor, t)!,
    );
  }
}
