import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
          isListening ? _stopListening() : _startListening();
        },
      ),
    );
  }

  /// Starts listening for speech input if the microphone is available
  Future<void> _startListening() async {
    if (!isInitialized) {
      await micInit();
    }

    if (!available || !isInitialized) {
      await _requestPermissions();
      await micInit();
    }

    if (!available) {
      return;
    }

    if (mounted) {
      setState(() {
        isListening = true;
      });
    }

    await speech.listen(
      localeId: context.read<LanguageProvider>().voiceLanguageCode,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
      ),
      onResult: (SpeechRecognitionResult val) async {
        if (!mounted || _isDisposed) return;
        if (val.finalResult) {
          widget.onSubmit(val.recognizedWords);
          _stopListening();
        }
      },
    );
  }

  /// Stops listening for speech input
  Future<void> _stopListening() async {
    if (_isDisposed) return;
    if (isListening) {
      await speech.stop();
      if (mounted) {
        setState(() {
          isListening = false;
        });
      }
    }
  }

  /// Initializes the microphone for speech recognition
  Future<void> micInit() async {
    if (_isDisposed || _initializing || isInitialized) return;
    _initializing = true;
    try {
      available = await speech.initialize(
        onStatus: (status) {
          if (mounted && !_isDisposed) {
            setState(() {
              isListening = status == 'listening';
            });
          }
        },
        onError: (error) {
          debugPrint('Speech Error: $error');
          if (mounted && !_isDisposed) {
            setState(() {
              isListening = false;
            });
          }
        },
      );
      if (mounted && !_isDisposed) {
        setState(() {
          isInitialized = available;
        });
      }
    } finally {
      _initializing = false;
    }
  }

  /// Requests necessary permissions for microphone and Bluetooth
  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
  }
}
