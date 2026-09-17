import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';

/// Central typography tokens — local Arimo (bundled) across the app.
/// Uses asset fonts so UI works offline (no Google Fonts runtime fetch).
class AppTypography {
  static const String fontFamily = 'Arimo';

  static TextStyle _style({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static TextStyle greeting = _style(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Login / signup page title — matches auth hero copy style.
  static TextStyle authTitle = _style(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.authTitle,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Login / signup page subtitle under [authTitle].
  static TextStyle authSubtitle = _style(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.authSubtitle,
    height: 1.4,
  );

  /// Hero image overlay headline (e.g. Every Function Matters).
  static TextStyle heroHeadline = _style(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// Hero image overlay support line under [heroHeadline].
  static TextStyle heroSupport = _style(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.35,
    letterSpacing: 0.1,
  );

  static TextStyle sectionTitle = _style(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle body = _style(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle label = _style(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static TextStyle amountLarge = _style(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.1,
    letterSpacing: -0.4,
  );

  static TextStyle amountMedium = _style(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle chip = _style(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
