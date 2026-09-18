import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_utils/device_heartbeat.dart';

void main() {
  final now = DateTime(2026, 9, 18, 12);

  test('sends on first run', () {
    expect(
      shouldSendDeviceHeartbeat(force: false, lastSentAt: null, now: now),
      isTrue,
    );
  });

  test('skips resume within throttle window', () {
    expect(
      shouldSendDeviceHeartbeat(
        force: false,
        lastSentAt: now.subtract(const Duration(hours: 1)),
        now: now,
      ),
      isFalse,
    );
  });

  test('sends after throttle window', () {
    expect(
      shouldSendDeviceHeartbeat(
        force: false,
        lastSentAt: now.subtract(const Duration(hours: 7)),
        now: now,
      ),
      isTrue,
    );
  });

  test('force bypasses throttle', () {
    expect(
      shouldSendDeviceHeartbeat(
        force: true,
        lastSentAt: now,
        now: now,
      ),
      isTrue,
    );
  });
}
