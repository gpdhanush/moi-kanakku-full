import 'package:flutter/material.dart';
import 'package:moi/app_utils/app_global/speech_input_service.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/voice_listening_indicator.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A widget that provides a microphone icon for speech-to-text functionality.
class MicIconWidget extends StatefulWidget {
  final Function(String) onSubmit;

  const MicIconWidget({super.key, required this.onSubmit});

  @override
  State<MicIconWidget> createState() => _MicIconWidgetState();
}

class _MicIconWidgetState extends State<MicIconWidget> {
  final Object _sessionId = Object();
  final SpeechInputService _speech = SpeechInputService.instance;

  bool _isListening = false;
  bool _isAvailable = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech.release(_sessionId);
    super.dispose();
  }

  Future<void> _prepare() async {
    final available = await _speech.ensureInitialized();
    if (!mounted || _isDisposed) return;
    setState(() => _isAvailable = available);
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
          duration: const Duration(milliseconds: 220),
          child: VoiceListeningIndicator(
            key: ValueKey(_isListening),
            active: _isListening,
            color: colorScheme.primary,
            size: 14,
          ),
        ),
        onPressed: () {
          FocusScope.of(context).unfocus();
          if (_isListening) {
            _stopListening();
          } else {
            _startListening();
          }
        },
      ),
    );
  }

  Future<void> _startListening() async {
    if (!_isAvailable) {
      final available = await _speech.ensureInitialized();
      if (!mounted || _isDisposed) return;
      setState(() => _isAvailable = available);
      if (!available) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available on this device.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final languageProvider = context.read<LanguageProvider>();
    await languageProvider.ensureReady();
    if (!mounted || _isDisposed) return;

    final voiceCode = languageProvider.voiceLanguageCode;
    debugPrint('MicIconWidget voice language=$voiceCode');

    await _speech.startListening(
      sessionId: _sessionId,
      desiredLocaleId: voiceCode,
      listenMode: ListenMode.dictation,
      onListeningChanged: (listening) {
        if (!mounted || _isDisposed) return;
        setState(() => _isListening = listening);
      },
      onResult: (words, isFinal) {
        if (!mounted || _isDisposed) return;
        // Live preview while speaking; commit once on final.
        widget.onSubmit(words);
        if (isFinal && _isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (message) {
        if (!mounted || _isDisposed) return;
        setState(() => _isListening = false);
        debugPrint('Mic speech error: $message');
        final normalizedMessage = message.toLowerCase();
        if (normalizedMessage.contains('error_no_match') ||
            normalizedMessage.contains('error_speech_timeout') ||
            normalizedMessage.contains('no match') ||
            normalizedMessage.contains('no speech')) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop(_sessionId);
    if (!mounted || _isDisposed) return;
    setState(() => _isListening = false);
  }
}
