List<int> _parseVersionSegments(String version) {
  return version
      .trim()
      .split('.')
      .where((part) => part.isNotEmpty)
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

bool isVersionBelowMinimum(String currentVersion, String minVersion) {
  final minimum = minVersion.trim();
  if (minimum.isEmpty) return false;

  final current = _parseVersionSegments(currentVersion);
  final required = _parseVersionSegments(minimum);
  final length = current.length > required.length
      ? current.length
      : required.length;

  for (var i = 0; i < length; i++) {
    final currentPart = i < current.length ? current[i] : 0;
    final requiredPart = i < required.length ? required[i] : 0;

    if (currentPart < requiredPart) return true;
    if (currentPart > requiredPart) return false;
  }

  return false;
}
