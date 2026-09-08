import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_themes/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  static const String _colorKey = 'theme_color';
  static const String _darkModeKey = 'dark_mode';

  // Theme color options - Dark color palette
  static const Color primary = Color(0xff075BCB);
  static const Color primaryOption2 = Color(0xFF1565C0); // Dark Blue
  static const Color primaryOption3 = Color(0xFF2E7D32); // Dark Green
  static const Color primaryOption4 = Color(0xFF6A1B9A); // Dark Purple
  static const Color primaryOption5 = Color(0xFFE65100); // Dark Orange
  static const Color primaryOption6 = Color(0xFFC2185B); // Dark Pink
  static const Color primaryOption7 = Color(0xFFC62828); // Dark Red
  static const Color primaryOption8 = Color(0xFF00695C); // Dark Teal
  static const Color primaryOption9 = Color(0xFF283593); // Dark Indigo
  static const Color primaryOption10 = Color(0xFF004D40); // Very Dark Teal
  static const Color primaryOption11 = Color(0xFFF57F17); // Dark Amber
  static const Color primaryOption12 = Color(0xFF827717); // Dark Lime
  static const Color primaryOption13 = Color(0xFF00695C); // Dark Teal Green
  static const Color primaryOption14 = Color(0xff2c3e50); // Dark Purple Variant
  static const Color primaryOption15 = Color(0xFFC62828); // Dark Red Variant
  static const Color primaryOption16 = Color(0xFF1565C0); // Dark Light Blue

  // List of all available theme colors
  static const List<Color> availableColors = [
    primary,
    AppColors.brandGreen,
    primaryOption2,
    primaryOption3,
    primaryOption4,
    primaryOption5,
    primaryOption6,
    primaryOption7,
    primaryOption8,
    // primaryOption9,
    primaryOption10,
    primaryOption11,
    primaryOption12,
    // primaryOption13,
    primaryOption14,
    // primaryOption15,
    // primaryOption16,
  ];

  final _storage = const FlutterSecureStorage();
  final AndroidOptions _androidOptions = const AndroidOptions(
    enforceBiometrics: false,
    resetOnError: true,
    storageNamespace: "_Pref_",
    preferencesKeyPrefix: "MOI_",
  );
  final IOSOptions _iosOptions = const IOSOptions(accountName: "moi_theme");

  bool _isDarkMode = false;
  Color _seedColor = primary;
  bool _hasLoaded = false;

  /// Returns whether dark mode is enabled
  bool get isDarkMode => _isDarkMode;

  /// Returns the current seed color for the theme
  Color get seedColor => _seedColor;

  ThemeProvider();

  /// Ensure theme settings are loaded (call once at app start)
  Future<void> ensureLoaded() async {
    if (_hasLoaded) return;
    await _loadThemeSettings();
    _hasLoaded = true;
  }

  /// Returns the current theme data based on the selected color and dark mode
  ThemeData get currentTheme {
    return getThemeForLanguage('en');
  }

  ThemeData getThemeForLanguage(String languageCode) {
    final Color statusBarColor = Colors.black;
    final SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
      statusBarColor: statusBarColor,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    final baseTheme = AppThemes.buildTheme(
      seedColor: _seedColor,
      isDark: _isDarkMode,
      languageCode: languageCode,
    );

    return baseTheme.copyWith(
      appBarTheme: baseTheme.appBarTheme.copyWith(
        foregroundColor: Colors.white,
        systemOverlayStyle: overlay,
        elevation: 0,
      ),
    );
  }

  /// Loads saved theme settings from secure storage
  Future<void> _loadThemeSettings() async {
    try {
      // Try reading with configured options first
      String? colorValue = await _storage.read(
        key: _colorKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      String? darkModeValue = await _storage.read(
        key: _darkModeKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );

      // Fallback: read without options (legacy) and migrate to new options
      if (colorValue == null) {
        final legacyColor = await _storage.read(key: _colorKey);
        if (legacyColor != null) {
          colorValue = legacyColor;
          await _storage.write(
            key: _colorKey,
            value: legacyColor,
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );
        }
      }
      if (darkModeValue == null) {
        final legacyDark = await _storage.read(key: _darkModeKey);
        if (legacyDark != null) {
          darkModeValue = legacyDark;
          await _storage.write(
            key: _darkModeKey,
            value: legacyDark,
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );
        }
      }

      if (colorValue != null) {
        try {
          _seedColor = Color(int.parse(colorValue));
        } catch (_) {}
      }
      if (darkModeValue != null) {
        _isDarkMode = darkModeValue == 'true';
      }
      notifyListeners();
    } catch (e) {
      // Swallow errors to avoid blocking app startup; fall back to defaults
    }
  }

  /// Toggles between light and dark mode
  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    try {
      await _storage.write(
        key: _darkModeKey,
        value: _isDarkMode.toString(),
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  /// Sets a new seed color for the theme
  /// [color] - The new color to use as the seed color
  Future<void> setSeedColor(Color color) async {
    if (_seedColor == color) return; // Skip if color hasn't changed

    _seedColor = color;
    try {
      final value = color.toARGB32().toString();
      await _storage.write(
        key: _colorKey,
        value: value,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }

  /// Resets the theme to default settings
  Future<void> resetTheme() async {
    _isDarkMode = false;
    _seedColor = primary;
    try {
      await _storage.delete(
        key: _colorKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _darkModeKey,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      notifyListeners();
    } catch (e) {
      // ignore
    }
  }
}
