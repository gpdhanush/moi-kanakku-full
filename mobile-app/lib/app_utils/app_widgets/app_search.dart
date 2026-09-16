import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Modern search field with speech-to-text mic support.
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
    if (mounted) setState(() {});
  }

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

  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }

    if (!_isInitialized || widget.controller == null) return;

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

  void _toggleListening() {
    FocusScope.of(context).unfocus();
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _clearText() {
    if (_isListening) _stopListening();
    widget.controller?.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    final extraTrailing = widget.trailing?.toList() ?? const <Widget>[];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadows.soft,
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.controller,
        style: AppTypography.body.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: primary,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search...',
          hintStyle: AppTypography.body.copyWith(
            color: const Color(0xffA1A1AA),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 12,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              color: const Color(0xff71717A),
              size: 18,
              strokeWidth: 1.9,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 24,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...extraTrailing,
              if (hasText)
                IconButton(
                  onPressed: _clearText,
                  tooltip: 'Clear',
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: const Color(0xffA1A1AA),
                    size: 16,
                    strokeWidth: 1.9,
                  ),
                )
              else if (_isInitialized)
                IconButton(
                  onPressed: _toggleListening,
                  tooltip: _isListening ? 'Stop' : 'Voice search',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: HugeIcon(
                      key: ValueKey(_isListening),
                      icon: _isListening
                          ? HugeIcons.strokeRoundedMic02
                          : HugeIcons.strokeRoundedMic01,
                      color: _isListening ? AppColors.moiGiven : primary,
                      size: 18,
                      strokeWidth: 1.9,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
            ],
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 40,
          ),
        ),
      ),
    );
  }
}
