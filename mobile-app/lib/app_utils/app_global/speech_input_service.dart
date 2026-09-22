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
        await _refreshLocales();
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

  Future<void> _refreshLocales() async {
    try {
      _availableLocales = await _speech.locales();
      if (kDebugMode) {
        final ids = _availableLocales.map((e) => e.localeId).join(', ');
        debugPrint('SpeechInputService locales: $ids');
      }
    } catch (e) {
      debugPrint('SpeechInputService locales error: $e');
    }
  }

  /// Starts a listen session owned by [sessionId].
  ///
  /// Partial results are reported with [isFinal] = false.
  /// The final transcript is reported once with [isFinal] = true.
  ///
  /// [desiredLocaleId] comes from Settings → Voice language (e.g. `ta_IN`),
  /// independent of the in-app UI language.
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

    // Locales can change after the user installs a language pack.
    await _refreshLocales();

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
    debugPrint(
      'SpeechInputService listening locale=$localeId '
      '(requested=$desiredLocaleId)',
    );

    try {
      onListeningChanged?.call(true);
      // Pass localeId both on options and the deprecated top-level arg so
      // Android/iOS always receive the voice-language setting.
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
    final normalizedError = error.errorMsg.toLowerCase();
    final ignorable =
        normalizedError.contains('error_no_match') ||
        normalizedError.contains('error_speech_timeout') ||
        normalizedError.contains('no match') ||
        normalizedError.contains('no speech');
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

  /// Picks the best installed locale for [desiredLocaleId].
  ///
  /// Never silently falls back to the device default (often English) — that
  /// ignored the Settings voice language. Always returns a concrete id.
  ///
  /// Avoids Latin-script packs (e.g. `ta_Latn_IN`) which return English
  /// letters for Tamil speech.
  String _resolveLocaleId(String desiredLocaleId) {
    final desired = _normalize(desiredLocaleId);
    final lang = desired.split('_').first;

    if (_availableLocales.isEmpty) {
      return desiredLocaleId;
    }

    // 1) Exact match (ta_IN == ta-IN == ta_in).
    for (final loc in _availableLocales) {
      if (_normalize(loc.localeId) == desired) {
        return loc.localeId;
      }
    }

    // 2) Same language + native script only (skip Latn / Latin / Romaji).
    final nativeMatches = _availableLocales.where((loc) {
      final id = _normalize(loc.localeId);
      final name = loc.name.toLowerCase();
      if (_isLatinScriptLocale(id, name)) return false;
      return id == lang || id.startsWith('${lang}_') || id.startsWith('$lang-');
    }).toList();

    if (nativeMatches.isNotEmpty) {
      // Prefer same region when present (e.g. IN).
      final parts = desired.split('_');
      if (parts.length >= 2) {
        final region = parts[1];
        for (final loc in nativeMatches) {
          final id = _normalize(loc.localeId);
          if (id.contains('_$region') || id.endsWith('-$region')) {
            return loc.localeId;
          }
        }
      }
      return nativeMatches.first.localeId;
    }

    // 3) Force the requested id so the OS tries that language online,
    // instead of defaulting to the device UI language (English).
    return desiredLocaleId;
  }

  bool _isLatinScriptLocale(String normalizedId, String name) {
    return normalizedId.contains('_latn') ||
        normalizedId.contains('-latn') ||
        normalizedId.contains('latn_') ||
        name.contains('latin') ||
        name.contains('latn') ||
        name.contains('roman');
  }

  String _normalize(String localeId) =>
      localeId.replaceAll('-', '_').toLowerCase();
}
