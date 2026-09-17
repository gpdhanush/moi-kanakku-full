import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';

/// Tailwind CSS 4–inspired elevation: soft, low-contrast shadows.
class AppShadows {
  static List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xff09090B).withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xff09090B).withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: const Color(0xff09090B).withValues(alpha: 0.03),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> hero = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}
