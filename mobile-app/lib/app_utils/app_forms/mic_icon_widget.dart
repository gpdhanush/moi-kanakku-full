import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

/// A widget that provides a microphone icon for speech-to-text functionality
class MicIconWidget extends StatefulWidget {
  final Function(String) onSubmit;

  const MicIconWidget({super.key, required this.onSubmit});

  @override
  State<MicIconWidget> createState() => _MicIconWidgetState();
}

class _MicIconWidgetState extends State<MicIconWidget> {
  final SpeechToText speech = SpeechToText();
  bool available = false;
  bool isListening = false;
  bool isInitialized = false;
  bool _isDisposed = false;
  bool _initializing = false;
  String _lastWords = '';
  List<LocaleName> _availableLocales = [];

  @override
  void initState() {
    super.initState();
    micInit();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (isListening) {
      speech.stop();
    }
    speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 25,
      width: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isListening ? Icons.mic_outlined : Icons.mic_none_outlined,
            key: ValueKey(isListening),
            size: 22,
            color: isListening ? Colors.redAccent : colorScheme.primary,
          ),
        ),
        onPressed: () {
          FocusScope.of(context).unfocus();
          if (isListening) {
            _stopListening();
          } else {
            _startListening();
          }
        },
      ),
    );
  }

  /// Initializes the microphone for speech recognition
  Future<void> micInit() async {
    if (_isDisposed || _initializing) return;
    _initializing = true;

    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await _requestPermissions();
      }

      available = await speech.initialize(
        onStatus: (status) {
          debugPrint('Speech Status: $status');
          if (mounted && !_isDisposed) {
            final listening = status == 'listening';
            setState(() {
              isListening = listening;
            });
            if (!listening && _lastWords.isNotEmpty) {
              widget.onSubmit(_lastWords);
            }
          }
        },
        onError: (SpeechRecognitionError error) {
          debugPrint('Speech Error: ${error.errorMsg}');
          if (mounted && !_isDisposed) {
            setState(() {
              isListening = false;
            });
            if (_lastWords.isNotEmpty) {
              widget.onSubmit(_lastWords);
            }
          }
        },
      );

      if (available) {
        _availableLocales = await speech.locales();
      }

      if (mounted && !_isDisposed) {
        setState(() {
          isInitialized = available;
        });
      }
    } catch (e) {
      debugPrint('Speech Init Exception: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          isInitialized = false;
          available = false;
        });
      }
    } finally {
      _initializing = false;
    }
  }

  /// Resolves the best supported localeId for speech-to-text
  String? _resolveLocaleId(String desiredLocaleId) {
    if (_availableLocales.isEmpty) return null;

    final hasExact =
        _availableLocales.any((loc) => loc.localeId == desiredLocaleId);
    if (hasExact) return desiredLocaleId;

    final langPrefix = desiredLocaleId.split('_').first;
    for (final loc in _availableLocales) {
      if (loc.localeId.startsWith(langPrefix)) {
        return loc.localeId;
      }
    }

    return _availableLocales.first.localeId;
  }

  /// Starts listening for speech input
  Future<void> _startListening() async {
    _lastWords = '';

    if (!isInitialized || !available) {
      await micInit();
    }

    if (!available) {
      debugPrint('Speech to text is not available on this device');
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final voiceCode = context.read<LanguageProvider>().voiceLanguageCode;
    final localeId = _resolveLocaleId(voiceCode);

    try {
      if (mounted) {
        setState(() {
          isListening = true;
        });
      }

      await speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          partialResults: true,
          autoPunctuation: true,
          enableHapticFeedback: true,
        ),
        onResult: (SpeechRecognitionResult val) {
          if (!mounted || _isDisposed) return;
          _lastWords = val.recognizedWords;
          if (val.recognizedWords.isNotEmpty) {
            widget.onSubmit(val.recognizedWords);
          }
          if (val.finalResult) {
            _stopListening();
          }
        },
      );
    } catch (e) {
      debugPrint('Speech Listen Exception: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          isListening = false;
        });
      }
    }
  }

  /// Stops listening for speech input
  Future<void> _stopListening() async {
    if (_isDisposed) return;
    if (isListening) {
      await speech.stop();
      if (mounted && !_isDisposed) {
        setState(() {
          isListening = false;
        });
      }
    }
  }

  /// Requests necessary permissions for microphone and Bluetooth
  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
  }
}
