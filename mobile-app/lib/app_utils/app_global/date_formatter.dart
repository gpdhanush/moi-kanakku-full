import 'package:intl/intl.dart';

/// Output format for function date: DD-MMM-YYYY (e.g. 26-Feb-2025).
const String functionDateDisplayFormat = 'dd-MMM-yyyy';

DateTime? parseFunctionDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return null;
  final s = dateStr.trim();
  final parsers = [
    DateFormat('dd-MMM-yyyy'),
    DateFormat('yyyy-MM-dd'),
    DateFormat('dd/MM/yyyy'),
    DateFormat('MM/dd/yyyy'),
    DateFormat('dd-MM-yyyy'),
    DateFormat('yyyy/MM/dd'),
  ];
  for (final format in parsers) {
    try {
      return format.parse(s);
    } catch (_) {}
  }
  return null;
}

/// Tries to parse common date strings and returns DD-MMM-YYYY.
/// Returns original string if parsing fails.
String formatFunctionDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return dateStr ?? '';
  final d = parseFunctionDate(dateStr);
  if (d == null) return dateStr.trim();
  return DateFormat(functionDateDisplayFormat).format(d);
}

/// Returns "dd-MMM-yyyy • Weekday" (e.g. 26-Feb-2025 • Wednesday).
String formatFunctionDateWithDay(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return '';
  final d = parseFunctionDate(dateStr);
  if (d == null) return dateStr.trim();
  final date = DateFormat(functionDateDisplayFormat).format(d);
  final day = DateFormat('EEEE').format(d);
  return '$date • $day';
}
