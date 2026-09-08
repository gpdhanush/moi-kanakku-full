import 'package:flutter/material.dart';

import 'index.dart';

class AppThemes {
  static const String englishFontFamily = 'Arimo';
  static const String tamilFontFamily = 'Arimo';

  // Responsive breakpoints
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  static double _fontDelta(String languageCode) {
    return languageCode.toLowerCase() == 'ta' ? 2.0 : 0.0;
  }

  /// Public font delta getter for language-specific font sizing
  static double getFontDelta(String languageCode) {
    return _fontDelta(languageCode);
  }

  /// Clamp font sizes to ensure readability
  /// Prevents text from becoming too small or too large
  static double clampFontSize(double size) {
    const double minFontSize = 10.0; // Minimum readable size
    const double maxFontSize = 34.0; // Maximum practical size
    return size.clamp(minFontSize, maxFontSize);
  }

  /// Get responsive scale factor based on screen width
  static double getResponsiveScale(double screenWidth) {
    if (screenWidth < mobileBreakpoint) {
      return 0.85; // Mobile small
    } else if (screenWidth < tabletBreakpoint) {
      return 0.95; // Mobile/Tablet
    } else if (screenWidth < desktopBreakpoint) {
      return 1.0; // Tablet/Desktop
    } else {
      return 1.1; // Large desktop
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(double baseSizeEn, double screenWidth) {
    return baseSizeEn * getResponsiveScale(screenWidth);
  }

  /// Get device type based on screen width
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

  /// Apply responsive sizing to any TextStyle
  static TextStyle makeResponsive(
    TextStyle style,
    double screenWidth, {
    String languageCode = 'en',
  }) {
    if (style.fontSize == null) return style;

    final delta = _fontDelta(languageCode);
    final responsiveSize =
        getResponsiveFontSize(style.fontSize!, screenWidth) + delta;

    final isTamil = languageCode.toLowerCase() != 'en';
    return style.copyWith(
      fontSize: responsiveSize,
      fontFamily: isTamil ? tamilFontFamily : englishFontFamily,
    );
  }

  static TextTheme _textThemeWithLanguage(
    TextTheme base,
    String languageCode,
    bool isDark,
  ) {
    // final delta = _fontDelta(languageCode);
    final textColor = isDark ? Colors.white : AppColors.text;

    TextStyle? mapStyle(TextStyle? style) {
      if (style == null) return null;

      final isTamil = languageCode.toLowerCase() != 'en';
      final fontSize = clampFontSize((style.fontSize ?? 14) + 0);

      return style.copyWith(
        fontFamily: isTamil ? tamilFontFamily : englishFontFamily,
        fontSize: fontSize,
        fontWeight: isTamil
            ? ((style.fontWeight ?? FontWeight.w500).value >=
                      FontWeight.w600.value
                  ? style.fontWeight
                  : FontWeight.w600)
            : style.fontWeight,
        color: style.color ?? textColor,
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

  static ThemeData buildTheme({
    required Color seedColor,
    required bool isDark,
    required String languageCode,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final base = isDark ? darkTheme : lightTheme;

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: seedColor,
        secondary: AppColors.brandGreen,
        tertiary: AppColors.brandBlue,
      ),
      textTheme: _textThemeWithLanguage(base.textTheme, languageCode, isDark),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: isDark ? Colors.grey[900] : seedColor,
      ),
    );
  }

  static ThemeData getThemeByColor(
    Color color,
    bool isDark, {
    String languageCode = 'en',
  }) {
    return buildTheme(
      seedColor: color,
      isDark: isDark,
      languageCode: languageCode,
    );
  }

  static ThemeData lightTheme = ThemeData.light(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.brandGreen,
      tertiary: AppColors.brandBlue,
    ),
    // colorScheme: ColorScheme.light(
    //   surface: Colors.white,
    //   primary: AppColors.primary,
    //   secondary: Colors.white60,
    // ),
    textTheme: TextTheme(
      // Display styles (largest)
      displayLarge: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 57,
      ),
      displayMedium: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 45,
      ),
      displaySmall: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 36,
      ),
      // Headline styles
      headlineLarge: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 32,
      ),
      headlineMedium: AppTextStyles.headline2.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: AppTextStyles.headline2.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      // Title styles
      titleLarge: AppTextStyles.headline2.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      titleSmall: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      // Body styles
      bodyLarge: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      ),
      bodyMedium: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      ),
      bodySmall: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      ),
      // Label styles (smallest)
      labelLarge: AppTextStyles.button.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelMedium: AppTextStyles.button.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelSmall: AppTextStyles.button.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      elevation: 0,
      titleTextStyle: AppTextStyles.headline2,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withAlpha(200),
      selectionHandleColor: AppColors.primary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: AppTextStyles.buttonStyle,
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.gray,
        disabledBackgroundColor: AppColors.primary.withAlpha(130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        foregroundColor: AppColors.primary,
        textStyle: AppTextStyles.textButtonStyle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      headerBackgroundColor: AppColors.primary,
      headerForegroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 5,
      dayStyle: TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      todayBorder: BorderSide(color: AppColors.primary),
      confirmButtonStyle: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.primary),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        textStyle: WidgetStatePropertyAll(
          TextStyle(decoration: TextDecoration.none),
        ),
      ),
      cancelButtonStyle: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.redAccent),
        foregroundColor: WidgetStatePropertyAll(Colors.white),
        textStyle: WidgetStatePropertyAll(
          TextStyle(decoration: TextDecoration.none),
        ),
      ),
      dayOverlayColor: WidgetStatePropertyAll(AppColors.primary),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.black;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary;
        }
        return Colors.transparent;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return AppColors.primary;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (!states.contains(WidgetState.selected)) {
          return Colors.black;
        }
        return Colors.white;
      }),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: Colors.grey[900],
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.dark,
      primary: AppColors.brandBlue,
      secondary: AppColors.brandGreen,
      tertiary: AppColors.brandBlue,
    ),
    textTheme: TextTheme(
      // Display styles (largest)
      displayLarge: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 57,
        color: Colors.white,
      ),
      displayMedium: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 45,
        color: Colors.white,
      ),
      displaySmall: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 36,
        color: Colors.white,
      ),
      // Headline styles
      headlineLarge: AppTextStyles.headline1.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 32,
        color: Colors.white,
      ),
      headlineMedium: AppTextStyles.headline2.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      headlineSmall: AppTextStyles.headline2.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // Title styles
      titleLarge: AppTextStyles.headline2.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleMedium: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleSmall: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      // Body styles
      bodyLarge: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      bodyMedium: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      bodySmall: AppTextStyles.bodyText.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      // Label styles (smallest)
      labelLarge: AppTextStyles.button.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelMedium: AppTextStyles.button.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      labelSmall: AppTextStyles.button.copyWith(
        fontFamily: englishFontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    ),
  );
}
