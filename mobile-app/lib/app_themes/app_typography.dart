import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moi/app_themes/app_colors.dart';

/// Central typography tokens — Google Inter across the app.
class AppTypography {
  static String get fontFamily =>
      GoogleFonts.inter().fontFamily ?? 'Inter';

  static TextStyle greeting = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Login / signup page title — matches auth hero copy style.
  static TextStyle authTitle = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.authTitle,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// Login / signup page subtitle under [authTitle].
  static TextStyle authSubtitle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.authSubtitle,
    height: 1.4,
  );

  /// Hero image overlay headline (e.g. Every Function Matters).
  static TextStyle heroHeadline = GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.2,
    letterSpacing: -0.3,
  );

  /// Hero image overlay support line under [heroHeadline].
  static TextStyle heroSupport = GoogleFonts.outfit(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    height: 1.35,
    letterSpacing: 0.1,
  );

  static TextStyle sectionTitle = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle label = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static TextStyle amountLarge = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.1,
    letterSpacing: -0.4,
  );

  static TextStyle amountMedium = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle chip = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
