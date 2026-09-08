import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';

class AppTextStyles {
  static const String _fontFamily = 'appFontFamily';

  static const TextStyle headline1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// BUTTON TEXT STYLES
  static const TextStyle buttonStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );

  static const TextStyle textButtonStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    decoration: TextDecoration.underline,
  );

  /// NO DATA FOUND STYLES
  static const TextStyle noDataPrimary = TextStyle(
    fontWeight: FontWeight.bold,

    fontSize: 16,
  );

  static const TextStyle noDataSecondary = TextStyle(
    fontWeight: FontWeight.bold,

    fontSize: 14,
    color: Colors.black54,
  );

  /// NO INTERNET STYLES
  static const TextStyle noInternetTitle = TextStyle(
    fontSize: 30,
    decoration: TextDecoration.underline,
    decorationColor: Colors.redAccent,
    fontWeight: FontWeight.bold,
    color: Colors.redAccent,
    fontFamily: 'RobotoBold',
  );

  static const TextStyle noInternetMessage = TextStyle(
    fontSize: 20,
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  static TextStyle customHintStyle = TextStyle(
    fontWeight: FontWeight.normal,
    overflow: TextOverflow.clip,
    color: Colors.grey.shade600,
  );
}
