import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              elevation: 8,
            ),
            // Minimal DatePickerThemeData to ensure disabled and selected
            // day styling matches the app theme. Uses the project's
            // WidgetStateProperty helpers so colors render correctly.
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: colorScheme.primary,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey.shade400;
                }
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return colorScheme.primary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.primary;
                }
                return Colors.transparent;
              }),
            ),
            textButtonTheme: TextButtonThemeData(
              // style: TextButton.styleFrom(
              //   foregroundColor: colorScheme.primary,
              //   textStyle: TextStyle(
              //     fontFamily: 'englishFont',
              //     fontSize: 15,
              //     fontWeight: FontWeight.w600,
              //   ),
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 16,
              //     vertical: 12,
              //   ),
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              // ),
            ),
            // elevatedButtonTheme: ElevatedButtonThemeData(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: colorScheme.primary,
            //     foregroundColor: Colors.white,
            //     elevation: 0,
            //     textStyle: TextStyle(
            //       fontFamily: 'englishFont',
            //       fontSize: 15,
            //       fontWeight: FontWeight.w600,
            //     ),
            //     padding: const EdgeInsets.symmetric(
            //       horizontal: 20,
            //       vertical: 12,
            //     ),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //   ),
            // ),
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
