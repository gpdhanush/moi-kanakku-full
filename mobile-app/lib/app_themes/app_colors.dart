import 'package:flutter/material.dart';

/// Moi Kanakku brand color system.
///
/// Lime is an accent only — never a full-screen background.
/// Use [of] / [forBrightness] for light/dark semantic surfaces and text.
class AppColors {
  AppColors._();

  // ── Brand (shared) ──────────────────────────────────────────────
  static const Color primary = Color(0xFFB7E600);
  static const Color primaryDark = Color(0xFF8EBA00);
  static const Color primaryLight = Color(0xFFD0FF22);
  static const Color charcoal = Color(0xFF171717);
  static const Color warmCream = Color(0xFFFAF7F0);

  /// Locked brand seed — replaces the former multi-accent picker.
  static const Color brandSeed = primary;

  // Legacy aliases kept so call sites compile without a redesign.
  static const Color logoGreen = primary;
  static const Color logoGreenDeep = primaryDark;
  static const Color logoMint = primaryLight;
  static const Color logoGold = Color(0xFFF4B400);
  static const Color brandBlue = Color(0xFF4285F4);
  static const Color brandGreen = primary;

  // ── Light palette ───────────────────────────────────────────────
  static const Color lightBackground = warmCream;
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1EEE6);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = charcoal;
  static const Color lightTextSecondary = Color(0xFF686868);
  static const Color lightTextMuted = Color(0xFF929292);
  static const Color lightBorder = Color(0xFFE4E1D9);
  static const Color lightSuccess = Color(0xFF43A047);
  static const Color lightWarning = Color(0xFFF4B400);
  static const Color lightError = Color(0xFFD93025);
  static const Color lightInfo = Color(0xFF4285F4);
  static const Color lightMoiGiven = charcoal;
  static const Color lightMoiReceivedSoft = Color(0xFFF3FCE0);
  static const Color lightMoiGivenSoft = Color(0xFFF1EEE6);

  // ── Dark palette ────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1E1D2A);
  static const Color darkSurface = Color(0xFF1A1A23);
  static const Color darkSurfaceVariant = Color(0xFF272635);
  static const Color darkSurfaceElevated = Color(0xFF2E2D3D);
  static const Color darkTextPrimary = Color(0xFFF7F7FA);
  static const Color darkTextSecondary = Color(0xFFB8B7C4);
  static const Color darkTextMuted = Color(0xFF858493);
  static const Color darkBorder = Color(0xFF353443);
  static const Color darkSuccess = Color(0xFF66BB6A);
  static const Color darkWarning = Color(0xFFFFC107);
  static const Color darkError = Color(0xFFFF6B61);
  static const Color darkInfo = Color(0xFF64B5F6);
  static const Color darkIcon = Color(0xFFB8B7C4);
  static const Color darkMoiGiven = Color(0xFFF7F7FA);
  static const Color darkMoiReceivedSoft = Color(0xFF2A3220);
  static const Color darkMoiGivenSoft = Color(0xFF272635);

  /// Financial: Moi Received always uses brand lime.
  static const Color moiReceived = primary;
  static const Color moiReceivedMid = primaryLight;

  static const Color accentAmber = lightWarning;
  static const Color accentAmberSoft = Color(0xFFFFF7ED);
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentVioletSoft = Color(0xFFF5F3FF);
  static const Color primarySoft = lightMoiReceivedSoft;
  static const Color primaryMid = primaryDark;

  /// Default light neutrals (const aliases for legacy const contexts).
  static const Color backgroundNeutral = warmCream;
  static const Color authTitle = charcoal;
  static const Color authSubtitle = lightTextSecondary;

  static const Color white = Color(0xFFFFFFFF);
  static const Color white50 = Color(0x88FFFFFF);
  static const Color grayDark = Color(0xFFEAEAEA);
  static const Color gray = Color(0xFFF3F3F3);
  static const Color text = charcoal;
  static const Color text50 = Color(0x88171717);
  static const Color black = charcoal;
  static const Color black50 = Color(0x88171717);
  static const Color blackLight = Color(0xFF2A2A2A);
  static const Color transactionRevert = Color(0xFFE8F0FE);
  static const Color customGrey = lightSurfaceVariant;
  static const Color fontGrey = lightTextSecondary;
  static const Color chipText = lightTextMuted;
  static const Color commentColor = lightTextMuted;
  static const Color referColor = lightTextSecondary;
  static const Color walletColor = lightSurfaceVariant;
  static const Color centerAlign = lightBorder;
  static const Color transColor = charcoal;

  /// Active theme seed — kept for [bindTheme] compatibility; always brand lime.
  static Color _themeSeed = brandSeed;
  static bool _isDark = false;

  static Color get themeSeed => _themeSeed;
  static bool get isDarkBound => _isDark;

  /// Scaffold / page canvas — follows [bindBrightness].
  static Color get background =>
      _isDark ? darkBackground : lightBackground;

  static Color get surface => _isDark ? darkSurface : lightSurface;

  static Color get surfaceVariant =>
      _isDark ? darkSurfaceVariant : lightSurfaceVariant;

  static Color get surfaceElevated =>
      _isDark ? darkSurfaceElevated : lightSurfaceElevated;

  static Color get surfaceBlue => surfaceVariant;

  static Color get borderSubtle => _isDark ? darkBorder : lightBorder;

  static Color get textPrimary =>
      _isDark ? darkTextPrimary : lightTextPrimary;

  static Color get textSecondary =>
      _isDark ? darkTextSecondary : lightTextSecondary;

  static Color get textMuted => _isDark ? darkTextMuted : lightTextMuted;

  static Color get moiGiven => _isDark ? darkMoiGiven : lightMoiGiven;

  static Color get moiGivenMid => moiGiven;

  static Color get moiGivenSoft =>
      _isDark ? darkMoiGivenSoft : lightMoiGivenSoft;

  static Color get moiReceivedSoft =>
      _isDark ? darkMoiReceivedSoft : lightMoiReceivedSoft;

  static Color get themeSoft => _isDark
      ? Color.lerp(darkSurfaceVariant, primary, 0.18)!
      : Color.lerp(white, primary, 0.12)!;

  static Color get themeSurface => surface;

  static void bindTheme(Color seed) {
    _themeSeed = brandSeed;
  }

  /// Sync static semantic getters with the active brightness.
  static void bindBrightness(bool isDark) {
    _isDark = isDark;
  }

  static Color moiGivenFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkMoiGiven : lightMoiGiven;

  static Color moiReceivedSoftFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? darkMoiReceivedSoft
          : lightMoiReceivedSoft;

  static Color moiGivenSoftFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkMoiGivenSoft : lightMoiGivenSoft;

  static MoiKanakkuColors of(BuildContext context) {
    return forBrightness(Theme.of(context).brightness);
  }

  static MoiKanakkuColors forBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? MoiKanakkuColors.dark
        : MoiKanakkuColors.light;
  }

  /// Darken accent toward charcoal (headers / hero edges).
  static Color deepenAccent(Color accent, {double amount = 0.35}) {
    return Color.lerp(accent, charcoal, amount)!;
  }
}

/// Semantic colors resolved for a single brightness.
class MoiKanakkuColors {
  const MoiKanakkuColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.moiReceived,
    required this.moiGiven,
    required this.moiReceivedSoft,
    required this.moiGivenSoft,
    required this.iconDefault,
    required this.iconActive,
    required this.onPrimary,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color moiReceived;
  final Color moiGiven;
  final Color moiReceivedSoft;
  final Color moiGivenSoft;
  final Color iconDefault;
  final Color iconActive;
  final Color onPrimary;

  static const MoiKanakkuColors light = MoiKanakkuColors(
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    surfaceElevated: AppColors.lightSurfaceElevated,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    border: AppColors.lightBorder,
    success: AppColors.lightSuccess,
    warning: AppColors.lightWarning,
    error: AppColors.lightError,
    info: AppColors.lightInfo,
    moiReceived: AppColors.moiReceived,
    moiGiven: AppColors.lightMoiGiven,
    moiReceivedSoft: AppColors.lightMoiReceivedSoft,
    moiGivenSoft: AppColors.lightMoiGivenSoft,
    iconDefault: AppColors.lightTextSecondary,
    iconActive: AppColors.primary,
    onPrimary: AppColors.charcoal,
  );

  static const MoiKanakkuColors dark = MoiKanakkuColors(
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    surfaceElevated: AppColors.darkSurfaceElevated,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    border: AppColors.darkBorder,
    success: AppColors.darkSuccess,
    warning: AppColors.darkWarning,
    error: AppColors.darkError,
    info: AppColors.darkInfo,
    moiReceived: AppColors.moiReceived,
    moiGiven: AppColors.darkMoiGiven,
    moiReceivedSoft: AppColors.darkMoiReceivedSoft,
    moiGivenSoft: AppColors.darkMoiGivenSoft,
    iconDefault: AppColors.darkIcon,
    iconActive: AppColors.primary,
    onPrimary: AppColors.charcoal,
  );
}
