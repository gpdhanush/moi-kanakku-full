import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moi/app_themes/app_colors.dart';

class AppTextStyles {
  static String get _fontFamily => GoogleFonts.inter().fontFamily ?? 'Inter';

  static TextStyle get headline1 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static TextStyle get headline2 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static TextStyle get bodyText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// BUTTON TEXT STYLES
  static TextStyle get buttonStyle => GoogleFonts.inter(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  static TextStyle get textButtonStyle => GoogleFonts.inter(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    decoration: TextDecoration.underline,
  );

  /// NO DATA FOUND STYLES
  static TextStyle get noDataPrimary => GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );

  static TextStyle get noDataSecondary => GoogleFonts.inter(
    fontWeight: FontWeight.bold,
    fontSize: 14,
    color: Colors.black54,
  );

  /// NO INTERNET STYLES
  static TextStyle get noInternetTitle => GoogleFonts.inter(
    fontSize: 30,
    decoration: TextDecoration.underline,
    decorationColor: Colors.redAccent,
    fontWeight: FontWeight.bold,
    color: Colors.redAccent,
  );

  static TextStyle get noInternetMessage => GoogleFonts.inter(
    fontSize: 20,
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get customHintStyle => GoogleFonts.inter(
    fontWeight: FontWeight.normal,
    fontSize: 14,
    color: AppColors.fontGrey,
  );

  /// Kept for callers that still reference the old private name pattern.
  static String get fontFamily => _fontFamily;
}
