import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_custom_themes.dart';

class AppThemes {
  /// Primary UI font — Google Inter.
  static String get englishFontFamily =>
      GoogleFonts.inter().fontFamily ?? 'Inter';

  /// Tamil script fallback (Inter does not cover Tamil glyphs).
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

  static TextTheme _textThemeWithLanguage(
    TextTheme base,
    String languageCode,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : AppColors.text;
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
        // Tamil script needs a bit less line height to avoid a bulky look.
        height: isTamil
            ? ((style.height ?? 1.35) * 0.95).clamp(1.15, 1.4)
            : style.height,
        fontWeight: style.fontWeight,
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

  static TextTheme _interBaseTextTheme(bool isDark) {
    final base = isDark
        ? ThemeData(brightness: Brightness.dark, useMaterial3: true).textTheme
        : ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
    return GoogleFonts.interTextTheme(base);
  }

  static ThemeData buildTheme({
    required Color seedColor,
    required bool isDark,
    required String languageCode,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final base = isDark ? _buildDarkTheme() : _buildLightTheme();
    final interTheme = _textThemeWithLanguage(
      _interBaseTextTheme(isDark),
      languageCode,
      isDark,
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: seedColor,
        secondary: AppColors.logoGold,
        tertiary: AppColors.logoMint,
      ),
      textTheme: interTheme,
      primaryTextTheme: interTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: isDark ? Colors.grey[900] : seedColor,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
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

  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final inter = GoogleFonts.interTextTheme(
      ThemeData.light(useMaterial3: true).textTheme,
    );

    return ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.logoGold,
        tertiary: AppColors.logoMint,
      ),
      textTheme: inter,
      primaryTextTheme: inter,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
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
        dayStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        todayBorder: const BorderSide(color: AppColors.primary),
        confirmButtonStyle: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(decoration: TextDecoration.none),
          ),
        ),
        cancelButtonStyle: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.redAccent),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(decoration: TextDecoration.none),
          ),
        ),
        dayOverlayColor: const WidgetStatePropertyAll(AppColors.primary),
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
  }

  static ThemeData _buildDarkTheme() {
    final inter = GoogleFonts.interTextTheme(
      ThemeData.dark(useMaterial3: true).textTheme,
    );

    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.logoGold,
        tertiary: AppColors.logoMint,
      ),
      textTheme: inter.apply(bodyColor: Colors.white, displayColor: Colors.white),
      primaryTextTheme: inter.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
