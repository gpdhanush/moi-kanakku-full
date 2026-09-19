import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_global/speech_input_service.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
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
  final Object _sessionId = Object();
  final SpeechInputService _speech = SpeechInputService.instance;

  bool _isListening = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    widget.controller?.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _speech.release(_sessionId);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.ensureInitialized();
    if (!mounted) return;
    setState(() => _isInitialized = available);
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeech();
    }
    if (!_isInitialized || widget.controller == null) return;

    final languageProvider = context.read<LanguageProvider>();
    await languageProvider.ensureReady();
    if (!mounted) return;

    final voiceCode = languageProvider.voiceLanguageCode;
    debugPrint('SearchWidget voice language=$voiceCode');

    await _speech.startListening(
      sessionId: _sessionId,
      desiredLocaleId: voiceCode,
      listenMode: ListenMode.search,
      onListeningChanged: (listening) {
        if (!mounted) return;
        setState(() => _isListening = listening);
      },
      onResult: (words, isFinal) {
        if (!mounted || widget.controller == null) return;
        widget.controller!.value = TextEditingValue(
          text: words,
          selection: TextSelection.collapsed(offset: words.length),
        );
        if (isFinal && _isListening) {
          setState(() => _isListening = false);
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() => _isListening = false);
        debugPrint('Search speech error: $message');
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop(_sessionId);
    if (mounted) {
      setState(() => _isListening = false);
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
    final colors = AppColors.of(context);
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    final extraTrailing = widget.trailing?.toList() ?? const <Widget>[];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
        boxShadow: AppShadows.soft,
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: widget.controller,
        style: AppTypography.body.copyWith(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: primary,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search...',
          hintStyle: AppTypography.body.copyWith(
            color: colors.textMuted,
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
              color: colors.textSecondary,
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
              if (hasText && !_isListening)
                IconButton(
                  onPressed: _clearText,
                  tooltip: 'Clear',
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    color: colors.textMuted,
                    size: 16,
                    strokeWidth: 1.9,
                  ),
                ),
              if (_isInitialized)
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
