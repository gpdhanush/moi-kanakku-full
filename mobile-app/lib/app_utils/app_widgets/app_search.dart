import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';

/// A search widget with optional speech-to-text functionality
class SearchWidget extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final Iterable<Widget>? trailing;

  const SearchWidget({
    super.key,
    this.hintText,
    this.controller,
    this.trailing,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  bool _initializing = false;
  List<LocaleName> _availableLocales = [];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Initialize speech recognition
  Future<void> _initializeSpeech() async {
    if (_initializing) return;
    _initializing = true;

    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Search Speech Status: $status');
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
          }
        },
        onError: (SpeechRecognitionError error) {
          debugPrint('Search Speech Error: ${error.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );

      if (available) {
        _availableLocales = await _speech.locales();
      }

      if (mounted) {
        setState(() {
          _isInitialized = available;
        });
      }
    } catch (e) {
      debugPrint('Search Speech Init Exception: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
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

  /// Starts listening for speech input and updates the controller with recognized words
  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }

    if (!_isInitialized || widget.controller == null) {
      return;
    }

    final voiceCode = context.read<LanguageProvider>().voiceLanguageCode;
    final localeId = _resolveLocaleId(voiceCode);

    try {
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }

      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          cancelOnError: true,
          partialResults: true,
          autoPunctuation: true,
          enableHapticFeedback: true,
        ),
        onResult: (result) {
          if (mounted && widget.controller != null) {
            widget.controller!.text = result.recognizedWords;
          }
        },
      );
    } catch (e) {
      debugPrint('Search Speech Listen Exception: $e');
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  /// Stops listening for speech input
  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  /// Toggle speech listening
  void _toggleListening() {
    FocusScope.of(context).unfocus();
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = widget.controller?.text.isNotEmpty ?? false;

    return SearchBar(
      controller: widget.controller,
      shadowColor: WidgetStateProperty.all(
        colorScheme.primary.withValues(alpha: 0.1),
      ),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      side: WidgetStateProperty.all(
        BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      hintText: widget.hintText ?? "Search...",
      hintStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      autoFocus: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(
          Icons.search_outlined,
          color: colorScheme.primary,
          size: 22,
        ),
      ),
      trailing: [
        if (hasText)
          IconButton(
            onPressed: () {
              // Stop listening if still active
              if (_isListening) {
                _stopListening();
              }
              widget.controller?.clear();
              FocusScope.of(context).unfocus();
            },
            icon: Icon(
              Icons.close_outlined,
              color: Colors.grey.shade600,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          )
        else if (_isInitialized)
          IconButton(
            onPressed: _toggleListening,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isListening ? Icons.mic_outlined : Icons.mic_none_outlined,
                key: ValueKey(_isListening),
                color: _isListening ? Colors.redAccent : colorScheme.primary,
                size: 20,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
      ],
    );
  }
}
