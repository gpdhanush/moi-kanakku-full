import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_storages/secure_storages.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _voiceLanguageKey = 'voice_language';
  static const String _englishCode = 'en';
  static const String _tamilCode = 'ta';
  static const String defaultVoiceLanguageCode = 'en_US';

  static const Map<String, String> supportedVoiceLanguages = {
    'en_US': 'English',
    'ta_IN': 'Tamil',
    'ml_IN': 'Malayalam',
    'kn_IN': 'Kannada',
  };

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ta': 'தமிழ்',
    'ml': 'മലയാളം',
    'kn': 'ಕನ್ನಡ',
  };

  String _currentLanguage = _englishCode;
  String _voiceLanguageCode = defaultVoiceLanguageCode;
  Map<String, dynamic> _translations = {};

  final SecureStorageService _storage = SecureStorageService();

  String get currentLanguage => _currentLanguage;
  String get voiceLanguageCode => _voiceLanguageCode;
  List<String> get voiceLanguageCodes => supportedVoiceLanguages.keys.toList();
  bool get isTamil => _currentLanguage == _tamilCode;
  bool get isEnglish => _currentLanguage == _englishCode;
  List<String> get languageCodes => supportedLanguages.keys.toList();

  LanguageProvider() {
    _initialize();
  }

  /// Initialize language from storage or use default
  Future<void> _initialize() async {
    try {
      final savedLanguage = await _storage.get(_languageKey);
      if (savedLanguage != null &&
          supportedLanguages.containsKey(savedLanguage)) {
        _currentLanguage = savedLanguage;
      } else {
        _currentLanguage = _englishCode;
      }
      final savedVoiceLanguage = await _storage.get(_voiceLanguageKey);
      if (savedVoiceLanguage != null &&
          supportedVoiceLanguages.containsKey(savedVoiceLanguage)) {
        _voiceLanguageCode = savedVoiceLanguage;
      } else {
        _voiceLanguageCode = defaultVoiceLanguageCode;
      }
      await _loadTranslations();
    } catch (e) {
      _currentLanguage = _englishCode;
      _voiceLanguageCode = defaultVoiceLanguageCode;
      await _loadTranslations();
    }
  }

  /// Load translations for current language
  Future<void> _loadTranslations() async {
    try {
      final String filePath = 'assets/translations/$_currentLanguage.json';
      final String jsonString = await rootBundle.loadString(filePath);
      final loadedTranslations = jsonDecode(jsonString);
      _translations = _mergeMaps(
        jsonDecode(await rootBundle.loadString('assets/translations/en.json')),
        loadedTranslations,
      );
      notifyListeners();
    } catch (e) {
      _translations = {};
    }
  }

  /// Change language
  Future<void> setLanguage(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) return;
    if (languageCode == _currentLanguage) return;

    _currentLanguage = languageCode;
    await _storage.save(_languageKey, languageCode);
    await _loadTranslations();
    notifyListeners();
  }

  Future<void> setVoiceLanguage(String languageCode) async {
    if (!supportedVoiceLanguages.containsKey(languageCode)) return;
    if (languageCode == _voiceLanguageCode) return;

    _voiceLanguageCode = languageCode;
    await _storage.save(_voiceLanguageKey, languageCode);
    notifyListeners();
  }

  /// Get translated text
  String translate(String key) {
    final parts = key.split('.');
    dynamic current = _translations;

    for (String part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return key; // Return the key if translation not found
      }
    }

    return current.toString();
  }

  /// Get translated text with fallback (used as tr() method)
  String tr(String key) => translate(key);

  /// Toggle language between Tamil and English
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == _englishCode
        ? _tamilCode
        : _englishCode;
    await setLanguage(newLanguage);
  }

  Map<String, dynamic> _mergeMaps(
    Map<String, dynamic> fallback,
    dynamic overrides,
  ) {
    if (overrides is! Map) return fallback;
    final merged = Map<String, dynamic>.from(fallback);
    for (final entry in overrides.entries) {
      final fallbackValue = merged[entry.key];
      if (fallbackValue is Map && entry.value is Map) {
        merged[entry.key] = _mergeMaps(
          Map<String, dynamic>.from(fallbackValue),
          entry.value,
        );
      } else {
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }
}
