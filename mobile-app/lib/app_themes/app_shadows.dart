import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';

/// Soft elevation shadows — charcoal-based, no heavy lime glow.
class AppShadows {
  static Color _tint = AppColors.charcoal;
  static bool _dark = false;

  /// Call whenever the theme seed changes (also from [AppColors.bindTheme] callers).
  static void bindTheme(Color seed) {
    _dark = AppColors.isDarkBound;
    _tint = _dark ? Colors.black : AppColors.charcoal;
  }

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: _tint.withValues(alpha: _dark ? 0.40 : 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: _tint.withValues(alpha: _dark ? 0.50 : 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get hero => [
    BoxShadow(
      color: _tint.withValues(alpha: _dark ? 0.60 : 0.16),
      blurRadius: 32,
      offset: const Offset(0, 14),
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
