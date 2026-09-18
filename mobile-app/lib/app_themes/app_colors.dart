import 'package:flutter/material.dart';

class AppColors {
  /// Primary brand from app logo (`assets/logo/moi_kanakku.png` / adaptive icon).
  static const Color logoGreen = Color(0xff087F5B);
  static const Color logoGreenDeep = Color(0xff065F46);
  static const Color logoMint = Color(0xff34D399);
  static const Color logoGold = Color(0xffE8B923);

  static const Color primary = logoGreen;
  static const Color brandBlue = Color(0xff075BCB);
  static const Color brandGreen = logoGreen;
  static const Color primaryOption2 = brandBlue;
  static const Color primaryOption3 = Color(0xffd23156);
  static const Color primaryOption4 = Color(0xff13d0c1);
  static const Color primaryOption5 = Color(0xffe5672f);
  static const Color primaryOption6 = Color(0xffb73d99);
  static const Color primaryOption7 = Color(0xff16b9fd);
  static const Color primaryOption8 = Color(0xff5c2292);
  static const Color primaryOption9 = Color(0xff6374db);

  /// Moi Kanakku semantic financial colors
  static const Color moiReceived = Color(0xff1B8A4A);
  static const Color moiGiven = Color(0xffD64550);
  static const Color moiReceivedSoft = Color(0xffECFDF3);
  static const Color moiGivenSoft = Color(0xffFEF2F2);
  static const Color moiReceivedMid = Color(0xff34C759);
  static const Color moiGivenMid = Color(0xffFF6B6B);
  static const Color accentAmber = Color(0xffF59E0B);
  static const Color accentAmberSoft = Color(0xffFFF7ED);
  static const Color accentViolet = Color(0xff7C3AED);
  static const Color accentVioletSoft = Color(0xffF5F3FF);
  static const Color primarySoft = Color(0xffD1FAE5);
  static const Color primaryMid = Color(0xff10B981);

  /// Neutral base used when blending the live scaffold canvas.
  static const Color backgroundNeutral = Color(0xffF7F8FA);
  static const Color surface = Color(0xffffffff);
  static const Color surfaceBlue = Color(0xffECFDF5);
  static const Color borderSubtle = Color(0xffE4E4E7);
  static const Color textPrimary = Color(0xff0F172A);
  static const Color textSecondary = Color(0xff64748B);

  /// Active theme seed — updated via [bindTheme] when the user changes accent.
  static Color _themeSeed = primary;

  static Color get themeSeed => _themeSeed;

  /// Soft canvas tinted by the active theme (used for Scaffold backgrounds).
  static Color get background =>
      Color.lerp(backgroundNeutral, _themeSeed, 0.055)!;

  /// Soft primary wash for splash / hero fills.
  static Color get themeSoft => Color.lerp(Colors.white, _themeSeed, 0.14)!;

  /// Very light theme surface tint.
  static Color get themeSurface => Color.lerp(Colors.white, _themeSeed, 0.08)!;

  /// Keep scaffold + shadow colors in sync with ThemeProvider seed.
  static void bindTheme(Color seed) {
    _themeSeed = seed;
    // Deferred import avoided — callers also bind AppShadows; ThemeProvider does both.
  }

  /// Auth page heading colors (Welcome Back / Create account)
  static const Color authTitle = Color(0xff022C22);
  static const Color authSubtitle = Color(0xff758095);

  static const Color white = Color(0xffffffff);
  static const Color white50 = Color(0x88ffffff);
  static const Color grayDark = Color(0xffeaeaea);
  static const Color gray = Color(0xfff3f3f3);
  static const Color text = Color(0xff000000);
  static const Color text50 = Color(0x88000000);
  static const Color black = Color(0xff001424);
  static const Color black50 = Color(0x88001424);
  static const Color blackLight = Color(0xff011f35);
  static const Color transactionRevert = Color(0xffDFF5FF);
  static const Color customGrey = Color(0xfff5f5f5);
  static const Color fontGrey = Color(0xff7E7E7E);
  static const Color chipText = Color(0XffB6B6B6);
  static const Color commentColor = Color(0XffC4C4C4);
  static const Color referColor = Color(0Xff6F6F6F);
  static const Color walletColor = Color(0XffF6F6F6);
  static const Color centerAlign = Color(0XffE1E1E1);
  static const Color transColor = Color(0Xff112C8C);

  // List of primary colors
  static List<Color> primaryColorOptions = const [
    primary,
    primaryOption2,
    primaryOption3,
    primaryOption4,
    primaryOption5,
    primaryOption6,
    primaryOption7,
    primaryOption8,
    primaryOption9,
  ];

  /// Darken any accent for header / hero gradients (works for any seed color).
  static Color deepenAccent(Color accent, {double amount = 0.35}) {
    return Color.lerp(accent, const Color(0xff022C22), amount)!;
  }
}
