import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';

class AppTextStyles {
  static const String _fontFamily = 'Arimo';

  static TextStyle _style({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  static TextStyle get headline1 =>
      _style(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text);

  static TextStyle get headline2 =>
      _style(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text);

  static TextStyle get bodyText => _style(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static TextStyle get button => _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
  );

  /// BUTTON TEXT STYLES
  static TextStyle get buttonStyle => _style(
    color: AppColors.charcoal,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  static TextStyle get textButtonStyle => _style(
    color: AppColors.charcoal,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    decoration: TextDecoration.underline,
  );

  /// NO DATA FOUND STYLES
  static TextStyle get noDataPrimary =>
      _style(fontWeight: FontWeight.bold, fontSize: 16);

  static TextStyle get noDataSecondary =>
      _style(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54);

  /// NO INTERNET STYLES
  static TextStyle get noInternetTitle => _style(
    fontSize: 30,
    decoration: TextDecoration.underline,
    decorationColor: Colors.redAccent,
    fontWeight: FontWeight.bold,
    color: Colors.redAccent,
  );

  static TextStyle get noInternetMessage => _style(
    fontSize: 20,
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get customHintStyle => _style(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.fontGrey,
  );

  /// Kept for callers that still reference the old private name pattern.
  static String get fontFamily => _fontFamily;
}
