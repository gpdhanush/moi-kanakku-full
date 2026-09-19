import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_custom_themes.dart';
import 'app_shadows.dart';

class AppThemes {
  /// Primary UI font — bundled Arimo (offline-safe).
  static const String englishFontFamily = 'Arimo';

  /// Tamil script fallback (Latin UI font does not cover Tamil glyphs).
  static const String tamilFontFamily = 'NotoSansTamil';

  // Responsive breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  /// Tamil glyphs render visually larger than Latin at the same size.
  /// Scale the whole UI text down slightly for a friendlier Tamil layout.
  static const double tamilTextScale = 0.88;

  static double _fontDelta(String languageCode) {
    // Kept for callers; Tamil sizing is handled via [textScaleForLanguage].
    return 0.0;
  }

  /// Public font delta getter for language-specific font sizing
  static double getFontDelta(String languageCode) {
    return _fontDelta(languageCode);
  }

  /// Multiplier applied on top of the system text scaler for a language.
  static double textScaleForLanguage(String languageCode) {
    return languageCode.toLowerCase() == 'ta' ? tamilTextScale : 1.0;
  }

  /// Clamp font sizes to ensure readability
  static double clampFontSize(double size) {
    const double minFontSize = 10.0;
    const double maxFontSize = 34.0;
    return size.clamp(minFontSize, maxFontSize);
  }

  static double getResponsiveScale(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return 0.85;
    } else if (screenWidth < tabletBreakpoint) {
      return 0.95;
    } else if (screenWidth < desktopBreakpoint) {
      return 1.0;
    } else {
      return 1.1;
    }
  }

  static double getResponsiveFontSize(double baseSizeEn, double screenWidth) {
    return baseSizeEn * getResponsiveScale(screenWidth);
  }

  static String getDeviceType(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return 'mobile_small';
    } else if (screenWidth < tabletBreakpoint) {
      return 'mobile';
    } else if (screenWidth < desktopBreakpoint) {
      return 'tablet';
    } else {
      return 'desktop';
    }
  }

  static String fontFamilyForLanguage(String languageCode) {
    return languageCode.toLowerCase() == 'ta'
        ? tamilFontFamily
        : englishFontFamily;
  }

  static TextStyle makeResponsive(
    TextStyle style,
    double screenWidth, {
    String languageCode = 'en',
  }) {
    if (style.fontSize == null) return style;

    final delta = _fontDelta(languageCode);
    final responsiveSize =
        getResponsiveFontSize(style.fontSize!, screenWidth) + delta;

    return style.copyWith(
      fontSize: responsiveSize,
      fontFamily: fontFamilyForLanguage(languageCode),
    );
  }

  static TextStyle _arimo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: englishFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
    );
  }

  static TextTheme _textThemeWithLanguage(
    TextTheme base,
    String languageCode,
    bool isDark,
  ) {
    final colors = AppColors.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    );
    final family = fontFamilyForLanguage(languageCode);
    final isTamil = languageCode.toLowerCase() == 'ta';

    TextStyle? mapStyle(TextStyle? style) {
      if (style == null) return null;

      final fontSize = clampFontSize(
        (style.fontSize ?? 14) + _fontDelta(languageCode),
      );

      return style.copyWith(
        fontFamily: family,
        fontSize: fontSize,
        height: isTamil
            ? ((style.height ?? 1.35) * 0.95).clamp(1.15, 1.4)
            : style.height,
        fontWeight: style.fontWeight,
        color: style.color ?? colors.textPrimary,
      );
    }

    return base.copyWith(
      displayLarge: mapStyle(base.displayLarge),
      displayMedium: mapStyle(base.displayMedium),
      displaySmall: mapStyle(base.displaySmall),
      headlineLarge: mapStyle(base.headlineLarge),
      headlineMedium: mapStyle(base.headlineMedium),
      headlineSmall: mapStyle(base.headlineSmall),
      titleLarge: mapStyle(base.titleLarge),
      titleMedium: mapStyle(base.titleMedium),
      titleSmall: mapStyle(base.titleSmall),
      bodyLarge: mapStyle(base.bodyLarge),
      bodyMedium: mapStyle(base.bodyMedium),
      bodySmall: mapStyle(base.bodySmall),
      labelLarge: mapStyle(base.labelLarge),
      labelMedium: mapStyle(base.labelMedium),
      labelSmall: mapStyle(base.labelSmall),
    );
  }

  static TextTheme _baseTextTheme(bool isDark) {
    final base = isDark
        ? ThemeData(brightness: Brightness.dark, useMaterial3: true).textTheme
        : ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
    return base.apply(fontFamily: englishFontFamily);
  }

  static ColorScheme _colorScheme(bool isDark) {
    final c = AppColors.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    );
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.surfaceVariant,
      onPrimaryContainer: c.textPrimary,
      secondary: c.surfaceVariant,
      onSecondary: c.textPrimary,
      secondaryContainer: c.surfaceVariant,
      onSecondaryContainer: c.textPrimary,
      tertiary: c.info,
      onTertiary: c.onPrimary,
      error: c.error,
      onError: AppColors.white,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceVariant,
      surfaceContainerHigh: c.surfaceElevated,
      surfaceContainer: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainerLowest: c.background,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.border,
      shadow: c.textPrimary.withValues(alpha: 0.18),
      scrim: Colors.black54,
      inverseSurface: isDark ? c.surfaceElevated : AppColors.charcoal,
      onInverseSurface: isDark ? c.textPrimary : AppColors.white,
      inversePrimary: c.primaryDark,
    );
  }

  static ThemeData buildTheme({
    required Color seedColor,
    required bool isDark,
    required String languageCode,
  }) {
    AppColors.bindTheme(AppColors.brandSeed);
    AppColors.bindBrightness(isDark);
    AppShadows.bindTheme(AppColors.brandSeed);

    final colors = AppColors.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    );
    final base = isDark ? _buildDarkTheme() : _buildLightTheme();
    final themedText = _textThemeWithLanguage(
      _baseTextTheme(isDark),
      languageCode,
      isDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.background,
      colorScheme: _colorScheme(isDark),
      textTheme: themedText,
      primaryTextTheme: themedText,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        titleTextStyle: _arimo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      shadowColor: AppColors.charcoal.withValues(alpha: 0.12),
    );
  }

  static ThemeData getThemeByColor(
    Color color,
    bool isDark, {
    String languageCode = 'en',
  }) {
    return buildTheme(
      seedColor: AppColors.brandSeed,
      isDark: isDark,
      languageCode: languageCode,
    );
  }

  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get darkTheme => _buildDarkTheme();

  static ButtonStyle _primaryButtonStyle(MoiKanakkuColors c) {
    return ElevatedButton.styleFrom(
      textStyle: AppTextStyles.buttonStyle,
      elevation: 0,
      foregroundColor: AppColors.charcoal,
      backgroundColor: AppColors.primary,
      disabledForegroundColor: c.textMuted,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static ThemeData _buildLightTheme() {
    const c = MoiKanakkuColors.light;
    final textTheme = ThemeData.light(useMaterial3: true).textTheme.apply(
      fontFamily: englishFontFamily,
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: c.background,
      shadowColor: AppColors.charcoal.withValues(alpha: 0.12),
      colorScheme: _colorScheme(false),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        foregroundColor: c.textPrimary,
        titleTextStyle: _arimo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border.withValues(alpha: 0.6)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerColor: c.border,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withAlpha(200),
        selectionHandleColor: c.primaryDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(c),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          backgroundColor: AppColors.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          foregroundColor: c.textPrimary,
          textStyle: AppTextStyles.textButtonStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surfaceVariant,
          side: BorderSide(color: c.border),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.charcoal,
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primary.withValues(alpha: 0.45);
          }
          return c.border;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceVariant,
        selectedColor: c.primary.withValues(alpha: 0.25),
        labelStyle: _arimo(color: c.textPrimary, fontSize: 13),
        side: BorderSide(color: c.border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: _arimo(color: c.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: AppColors.lightMoiReceivedSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _arimo(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? c.primary : c.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? c.primary : c.iconDefault);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: c.primary,
        headerForegroundColor: c.onPrimary,
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 5,
        dayStyle: _arimo(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        todayBorder: const BorderSide(color: AppColors.primary),
        confirmButtonStyle: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor: const WidgetStatePropertyAll(AppColors.charcoal),
          textStyle: WidgetStatePropertyAll(
            _arimo(decoration: TextDecoration.none),
          ),
        ),
        cancelButtonStyle: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceVariant),
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          textStyle: WidgetStatePropertyAll(
            _arimo(decoration: TextDecoration.none),
          ),
        ),
        dayOverlayColor: WidgetStatePropertyAll(
          c.primary.withValues(alpha: 0.12),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.onPrimary;
          }
          return c.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primary;
          }
          return Colors.transparent;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return c.primary;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return c.textPrimary;
          }
          return c.onPrimary;
        }),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    const c = MoiKanakkuColors.dark;
    final textTheme = ThemeData.dark(useMaterial3: true).textTheme.apply(
      fontFamily: englishFontFamily,
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: c.background,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      colorScheme: _colorScheme(true),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
        foregroundColor: c.textPrimary,
        titleTextStyle: _arimo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerColor: c.border,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primary,
        selectionColor: c.primary.withAlpha(160),
        selectionHandleColor: c.primaryLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(c),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.charcoal,
          backgroundColor: AppColors.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          elevation: 0,
          foregroundColor: c.textSecondary,
          textStyle: AppTextStyles.textButtonStyle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surfaceVariant,
          side: BorderSide(color: c.border),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.charcoal,
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.primary;
          return c.surfaceElevated;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primary.withValues(alpha: 0.45);
          }
          return c.border;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceVariant,
        selectedColor: c.primary.withValues(alpha: 0.25),
        labelStyle: _arimo(color: c.textPrimary, fontSize: 13),
        side: BorderSide(color: c.border),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: _arimo(color: c.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: AppColors.darkMoiReceivedSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return _arimo(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? c.primary : c.iconDefault,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? c.primary : c.iconDefault);
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.iconDefault,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      datePickerTheme: DatePickerThemeData(
        headerBackgroundColor: c.primary,
        headerForegroundColor: c.onPrimary,
        backgroundColor: c.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 5,
        dayStyle: _arimo(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        todayBorder: const BorderSide(color: AppColors.primary),
        confirmButtonStyle: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor: const WidgetStatePropertyAll(AppColors.charcoal),
          textStyle: WidgetStatePropertyAll(
            _arimo(decoration: TextDecoration.none),
          ),
        ),
        cancelButtonStyle: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceVariant),
          foregroundColor: WidgetStatePropertyAll(c.textPrimary),
          textStyle: WidgetStatePropertyAll(
            _arimo(decoration: TextDecoration.none),
          ),
        ),
        dayOverlayColor: WidgetStatePropertyAll(
          c.primary.withValues(alpha: 0.12),
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.onPrimary;
          }
          return c.textPrimary;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return c.primary;
          }
          return Colors.transparent;
        }),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return c.primary;
        }),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.selected)) {
            return c.textPrimary;
          }
          return c.onPrimary;
        }),
      ),
    );
  }
}
