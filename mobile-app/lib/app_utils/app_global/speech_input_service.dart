import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Shared speech-to-text helper.
///
/// [SpeechToText] is a process-wide singleton. Multiple mic widgets must not
/// each call [SpeechToText.initialize]/cancel independently or they overwrite
/// callbacks and cancel each other's sessions.
class SpeechInputService {
  SpeechInputService._();
  static final SpeechInputService instance = SpeechInputService._();

  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  bool _initializing = false;
  bool _available = false;
  Object? _activeSession;
  bool _resultCommitted = false;
  String _lastWords = '';
  List<LocaleName> _availableLocales = [];

  void Function(String words, bool isFinal)? _onResult;
  void Function(String message)? _onError;
  void Function(bool listening)? _onListeningChanged;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;
  bool isSessionActive(Object sessionId) =>
      identical(_activeSession, sessionId) && _speech.isListening;

  Future<bool> ensureInitialized() async {
    if (_initialized) return _available;
    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return _available;
    }

    _initializing = true;
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _available = false;
          _initialized = true;
          return false;
        }
      }

      _available = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );

      if (_available) {
        _availableLocales = await _speech.locales();
      }

      _initialized = true;
      return _available;
    } catch (e) {
      debugPrint('SpeechInputService init error: $e');
      _available = false;
      _initialized = true;
      return false;
    } finally {
      _initializing = false;
    }
  }

  /// Starts a listen session owned by [sessionId].
  ///
  /// Partial results are reported with [isFinal] = false.
  /// The final transcript is reported once with [isFinal] = true.
  Future<bool> startListening({
    required Object sessionId,
    required String desiredLocaleId,
    required void Function(String words, bool isFinal) onResult,
    void Function(String message)? onError,
    void Function(bool listening)? onListeningChanged,
    ListenMode listenMode = ListenMode.confirmation,
  }) async {
    final ready = await ensureInitialized();
    if (!ready) {
      onError?.call('Speech recognition is not available on this device.');
      return false;
    }

    if (_speech.isListening) {
      await _speech.stop();
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    _activeSession = sessionId;
    _resultCommitted = false;
    _lastWords = '';
    _onResult = onResult;
    _onError = onError;
    _onListeningChanged = onListeningChanged;

    final localeId = _resolveLocaleId(desiredLocaleId);
    debugPrint('SpeechInputService listening locale=$localeId');

    try {
      onListeningChanged?.call(true);
      await _speech.listen(
        onResult: _handleResult,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          partialResults: true,
          autoPunctuation: true,
          enableHapticFeedback: true,
          listenMode: listenMode,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('SpeechInputService listen error: $e');
      _clearSessionIf(sessionId);
      onListeningChanged?.call(false);
      onError?.call('Could not start voice input. Please try again.');
      return false;
    }
  }

  Future<void> stop(Object sessionId) async {
    if (!identical(_activeSession, sessionId)) return;
    if (_speech.isListening) {
      await _speech.stop();
    }
    _commitFinalIfNeeded();
    _onListeningChanged?.call(false);
  }

  /// Releases ownership without cancelling another widget's active session.
  Future<void> release(Object sessionId) async {
    if (!identical(_activeSession, sessionId)) return;
    if (_speech.isListening) {
      await _speech.stop();
    }
    _clearSessionIf(sessionId);
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (_activeSession == null) return;

    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;

    _lastWords = words;
    _onResult?.call(words, false);

    if (result.finalResult) {
      _commitFinalIfNeeded();
    }
  }

  void _handleStatus(String status) {
    debugPrint('SpeechInputService status: $status');
    final listening = status == SpeechToText.listeningStatus;
    _onListeningChanged?.call(listening);

    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _commitFinalIfNeeded();
      _onListeningChanged?.call(false);
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('SpeechInputService error: ${error.errorMsg}');
    // Permanent no-match / timeout should not force stale text into the field.
    final ignorable = error.errorMsg.contains('error_no_match') ||
        error.errorMsg.contains('error_speech_timeout');
    if (!ignorable && _lastWords.isNotEmpty) {
      _commitFinalIfNeeded();
    } else {
      _resultCommitted = true;
    }
    _onListeningChanged?.call(false);
    if (!ignorable) {
      _onError?.call(error.errorMsg);
    }
  }

  void _commitFinalIfNeeded() {
    if (_resultCommitted) return;
    _resultCommitted = true;
    final words = _lastWords.trim();
    if (words.isNotEmpty) {
      _onResult?.call(words, true);
    }
  }

  void _clearSessionIf(Object sessionId) {
    if (!identical(_activeSession, sessionId)) return;
    _activeSession = null;
    _onResult = null;
    _onError = null;
    _onListeningChanged = null;
    _lastWords = '';
    _resultCommitted = false;
  }

  /// Picks the closest installed locale, or null for the system default.
  /// Never falls back to an unrelated first locale (that caused wrong language).
  String? _resolveLocaleId(String desiredLocaleId) {
    if (_availableLocales.isEmpty) return desiredLocaleId;

    final desired = _normalize(desiredLocaleId);
    for (final loc in _availableLocales) {
      if (_normalize(loc.localeId) == desired) return loc.localeId;
    }

    final lang = desired.split('_').first;
    for (final loc in _availableLocales) {
      if (_normalize(loc.localeId).startsWith('${lang}_') ||
          _normalize(loc.localeId) == lang) {
        return loc.localeId;
      }
    }

    return null;
  }

  String _normalize(String localeId) =>
      localeId.replaceAll('-', '_').toLowerCase();
}
