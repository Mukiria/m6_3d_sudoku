import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:m6_sudoku/core/constants/app_constants.dart';
import 'package:m6_sudoku/core/theme/app_theme_extension.dart';
import 'package:m6_sudoku/core/theme/glass_tokens.dart';
import 'package:m6_sudoku/shared/widgets/glass/squircle_border.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = AppConstants.fontFamily;

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1976D2),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFBBDEFB),
      onPrimaryContainer: Color(0xFF0D47A1),
      secondary: Color(0xFF0288D1),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFB3E5FC),
      onSecondaryContainer: Color(0xFF01579B),
      tertiary: Color(0xFF009688),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFB2DFDB),
      onTertiaryContainer: Color(0xFF004D40),
      error: Color(0xFFD32F2F),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFCDD2),
      onErrorContainer: Color(0xFFB71C1C),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A2E),
      surfaceContainerHighest: Color(0xFFF5F5F5),
      onSurfaceVariant: Color(0xFF757575),
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFE0E0E0),
      shadow: Color(0x1A000000),
      scrim: Color(0x1A000000),
      inverseSurface: Color(0xFF1A1A2E),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF90CAF9),
    );

    final TextTheme textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.12),
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      // Every screen header — light or dark, regular or 3D — shares this one
      // definition: brand-orange fill, white text/icons, the same height
      // and title size throughout. Screens that build their own header
      // (Statistics' SliverAppBar) pull straight from this theme rather
      // than hardcoding their own colors/sizes, so there's exactly one
      // place this ever needs to change.
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppThemeExtension.brandOrange,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(
            AppConstants.buttonMinWidth.toDouble(),
            AppConstants.buttonHeight.toDouble(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadius.toDouble(),
            ),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(
            AppConstants.buttonMinWidth.toDouble(),
            AppConstants.buttonHeight.toDouble(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadius.toDouble(),
            ),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: Size(
            AppConstants.buttonMinWidth.toDouble(),
            AppConstants.buttonHeight.toDouble(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadius.toDouble(),
            ),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: Size(
            AppConstants.buttonMinWidth.toDouble(),
            AppConstants.buttonHeight.toDouble(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.borderRadius.toDouble(),
            ),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          hoverColor: colorScheme.primary.withValues(alpha: 0.08),
          focusColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.12),
          padding: const EdgeInsets.all(8),
          iconSize: 24,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.smallBorderRadius.toDouble(),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 8,
        highlightElevation: 10,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.largeBorderRadius.toDouble(),
          ),
        ),
        extendedPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        extendedTextStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        counterStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        iconColor: colorScheme.onSurfaceVariant,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        alignLabelWithHint: true,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return colorScheme.surface;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
        side: BorderSide(color: colorScheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onSurfaceVariant;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return colorScheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.5);
          }
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return colorScheme.outlineVariant;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        trackOutlineColor: WidgetStateProperty.all(colorScheme.outline),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.3),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onPrimary,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        dividerColor: colorScheme.outlineVariant,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 8,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),
      dialogTheme: DialogThemeData(
        elevation: 8,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        // A dialog rounds all four corners uniformly, so it can take the
        // squircle shape directly. A bottom sheet can't yet (it needs
        // top-only rounding, which SquircleBorder doesn't support) — its
        // glass treatment lands in a later phase alongside that shape
        // support and the sheet content itself.
        shape: const SquircleBorder(
          cornerRadius: AppConstants.largeBorderRadius,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        actionsPadding: const EdgeInsets.all(16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 8,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.largeBorderRadius.toDouble()),
          ),
        ),
        modalBackgroundColor: colorScheme.surface,
        modalElevation: 8,
        modalBarrierColor: colorScheme.scrim,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant,
        dragHandleSize: const Size(36, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 6,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
        ),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: colorScheme.onInverseSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        dense: true,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.smallBorderRadius.toDouble(),
          ),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        disabledColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        selectedColor: colorScheme.primaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        brightness: Brightness.light,
        elevation: 0,
        pressElevation: 0,
        shadowColor: Colors.transparent,
        selectedShadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.largeBorderRadius.toDouble(),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 8,
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.borderRadius.toDouble(),
          ),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(
            AppConstants.smallBorderRadius.toDouble(),
          ),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        preferBelow: true,
        excludeFromSemantics: false,
        verticalOffset: 24,
        triggerMode: TooltipTriggerMode.tap,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
        refreshBackgroundColor: colorScheme.surfaceContainerHighest,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        trackColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        minThumbLength: 48,
        crossAxisMargin: 4,
        mainAxisMargin: 4,
        interactive: true,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.largeBorderRadius.toDouble(),
          ),
        ),
        hourMinuteTextStyle: textTheme.displayMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w300,
        ),
        dayPeriodTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        dialHandColor: colorScheme.primary,
        dialBackgroundColor: colorScheme.primaryContainer,
        entryModeIconColor: colorScheme.primary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppConstants.largeBorderRadius.toDouble(),
          ),
        ),
        headerBackgroundColor: colorScheme.primaryContainer,
        headerForegroundColor: colorScheme.onPrimaryContainer,
        headerHeadlineStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        headerHelpStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
        ),
        weekdayStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        dayStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        todayBackgroundColor: WidgetStateProperty.all(
          colorScheme.primaryContainer,
        ),
        todayForegroundColor: WidgetStateProperty.all(
          colorScheme.onPrimaryContainer,
        ),
        yearBackgroundColor: WidgetStateProperty.all(colorScheme.surface),
        yearForegroundColor: WidgetStateProperty.all(colorScheme.onSurface),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AppThemeExtension.light,
        GlassTokens.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF90CAF9),
      onPrimary: Color(0xFF0D47A1),
      primaryContainer: Color(0xFF1565C0),
      onPrimaryContainer: Color(0xFFBBDEFB),
      secondary: Color(0xFF4FC3F7),
      onSecondary: Color(0xFF01579B),
      secondaryContainer: Color(0xFF0277BD),
      onSecondaryContainer: Color(0xFFB3E5FC),
      tertiary: Color(0xFF4DB6AC),
      onTertiary: Color(0xFF004D40),
      tertiaryContainer: Color(0xFF00796B),
      onTertiaryContainer: Color(0xFFB2DFDB),
      error: Color(0xFFEF5350),
      onError: Color(0xFFB71C1C),
      errorContainer: Color(0xFFC62828),
      onErrorContainer: Color(0xFFFFCDD2),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE0E0E0),
      surfaceContainerHighest: Color(0xFF1A1A1A),
      onSurfaceVariant: Color(0xFFB0B0B0),
      outline: Color(0xFF333333),
      outlineVariant: Color(0xFF333333),
      shadow: Color(0x33000000),
      scrim: Color(0x33000000),
      inverseSurface: Color(0xFFE0E0E0),
      onInverseSurface: Color(0xFF000000),
      inversePrimary: Color(0xFF1976D2),
    );

    final TextTheme textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      // Same brand-orange/white header as light mode — headers deliberately
      // don't follow brightness, so this is identical to lightTheme's.
      appBarTheme: lightTheme.appBarTheme,
      focusColor: colorScheme.primary.withValues(alpha: 0.12),
      hoverColor: colorScheme.primary.withValues(alpha: 0.08),
      highlightColor: colorScheme.primary.withValues(alpha: 0.12),
      splashColor: colorScheme.primary.withValues(alpha: 0.12),
      extensions: <ThemeExtension<dynamic>>[
        AppThemeExtension.dark,
        GlassTokens.dark,
      ],
    );
  }
}
