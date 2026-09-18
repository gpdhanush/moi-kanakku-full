import 'package:flutter/foundation.dart';

/// Temporary cold-start timing helper for startup performance work.
/// Logs only in debug/profile; no-op in release.
class StartupTiming {
  StartupTiming._();

  static final Stopwatch _app = Stopwatch();
  static bool _started = false;

  static void markAppStart() {
    if (_started) return;
    _started = true;
    _app
      ..reset()
      ..start();
    log('APP_START');
  }

  static void log(String label) {
    if (kReleaseMode) return;
    final ms = _started ? _app.elapsedMilliseconds : 0;
    debugPrint('[STARTUP +${ms}ms] $label');
  }

  static Future<T> timeAsync<T>(String label, Future<T> Function() action) async {
    final sw = Stopwatch()..start();
    log('START: $label');
    try {
      return await action();
    } finally {
      log('END: $label ${sw.elapsedMilliseconds}ms');
    }
  }

  static T timeSync<T>(String label, T Function() action) {
    final sw = Stopwatch()..start();
    log('START: $label');
    try {
      return action();
    } finally {
      log('END: $label ${sw.elapsedMilliseconds}ms');
    }
  }
}
