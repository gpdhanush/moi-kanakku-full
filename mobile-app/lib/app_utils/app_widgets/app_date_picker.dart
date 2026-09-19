import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_themes/index.dart';

/// Utility for showing a date picker with the app's consistent theming and
/// formatting logic.
class AppDatePicker {
  /// Shows a date picker dialog. If [initialDate] is null it defaults to
  /// [DateTime.now()].
  ///
  /// [firstDate] and [lastDate] default to a wide range around the current
  /// year if not provided. The returned value is the selected date or null if
  /// the dialog was dismissed.
  static Future<DateTime?> pick(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Color? barrierColor,
    Locale? locale,
    // When true allow selecting dates in the past (older dates). Defaults to true.
    bool isOldDateAllowed = true,
    // When true allow selecting dates in the future. Defaults to true.
    bool allowFutureDates = true,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final surfaceElevated = isDark
        ? AppColors.darkSurfaceElevated
        : Colors.white;
    final onSurface = isDark ? AppColors.darkTextPrimary : Colors.black87;
    final muted = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;
    final now = DateTime.now();
    initialDate ??= now;
    firstDate ??= isOldDateAllowed
        ? DateTime(now.year - 50)
        : DateTime(now.year);

    lastDate ??= allowFutureDates
        ? DateTime(now.year + 50)
        : DateTime(now.year);

    final DateTime? picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      barrierColor: barrierColor,
      locale: locale,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary,
              onPrimary: AppColors.charcoal,
              surface: surface,
              onSurface: onSurface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 8,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: colorScheme.primary,
              headerForegroundColor: AppColors.charcoal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return muted;
                }
                if (states.contains(WidgetState.selected)) {
                  return AppColors.charcoal;
                }
                return onSurface;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.charcoal;
                }
                return colorScheme.primary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.primary;
                }
                return Colors.transparent;
              }),
              dayOverlayColor: WidgetStatePropertyAll(
                colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ),
          child: child!,
        );
      },
    );

    return picked;
  }

  /// Formatting helper to convert a [DateTime] to the display format used in
  /// text fields (`dd-MMM-yyyy`).
  static String formatForDisplay(DateTime date) {
    return DateFormat('dd-MMM-yyyy', 'en').format(date);
  }

  /// Tries to parse various incoming date string formats and returns a
  /// `DateTime`. Falls back to `DateTime.now()` on failure.
  static DateTime parseDisplay(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    try {
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          if (parts[1].length == 3) {
            return DateFormat('dd-MMM-yyyy', 'en').parse(dateStr);
          } else if (parts[0].length == 4) {
            return DateTime.parse(dateStr);
          } else {
            return DateFormat('dd-MM-yyyy').parse(dateStr);
          }
        }
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}
    // fallback
    return DateTime.now();
  }
}
