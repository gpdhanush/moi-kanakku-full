bool shouldSendDeviceHeartbeat({
  required bool force,
  DateTime? lastSentAt,
  DateTime? now,
  Duration interval = const Duration(hours: 6),
}) {
  if (force) return true;
  if (lastSentAt == null) return true;
  return (now ?? DateTime.now()).difference(lastSentAt) >= interval;
}
