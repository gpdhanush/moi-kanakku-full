import 'package:intl/intl.dart';

/// Output format for function date: DD-MMM-YYYY (e.g. 26-Feb-2025).
const String functionDateDisplayFormat = 'dd-MMM-yyyy';

/// Tries to parse common date strings and returns DD-MMM-YYYY.
/// Returns original string if parsing fails.
String formatFunctionDate(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return dateStr ?? '';
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
      final d = format.parse(s);
      return DateFormat(functionDateDisplayFormat).format(d);
    } catch (_) {}
  }
  return s;
}
