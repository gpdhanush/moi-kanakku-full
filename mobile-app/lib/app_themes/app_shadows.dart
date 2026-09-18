import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';

/// Soft elevation shadows — charcoal-based, no heavy lime glow.
class AppShadows {
  static Color _tint = AppColors.charcoal;

  /// Call whenever the theme seed changes (also from [AppColors.bindTheme] callers).
  static void bindTheme(Color seed) {
    _tint = AppColors.charcoal;
  }

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.04),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get hero => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  /// Splash / logo mark glow — subtle charcoal, not lime.
  static List<BoxShadow> get splash => [
        BoxShadow(
          color: _tint.withValues(alpha: 0.12),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: _tint.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
}
