import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_themes/app_shadows.dart';
import 'package:moi/app_themes/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  static const String _colorKey = 'theme_color';
  static const String _darkModeKey = 'dark_mode';

  /// Locked brand primary — accent picker removed from Settings.
  static const Color primary = AppColors.brandSeed;

  /// Kept for compatibility; UI no longer offers a color picker.
  static const List<Color> availableColors = [primary];

  final _storage = const FlutterSecureStorage();

  /// Isolated from session storage so logout `deleteAll` cannot wipe the accent.
  final AndroidOptions _androidOptions = const AndroidOptions(
    enforceBiometrics: false,
    resetOnError: false,
    storageNamespace: "_Theme_",
    preferencesKeyPrefix: "MOI_THEME_",
  );

  /// Previous shared namespace (wiped on logout). Used only to migrate.
  final AndroidOptions _legacyAndroidOptions = const AndroidOptions(
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

  /// True when [color] is the saved accent, even after a storage round-trip.
  bool isSeedColor(Color color) => _seedColor.toARGB32() == color.toARGB32();

  ThemeProvider() {
    AppColors.bindTheme(_seedColor);
    AppColors.bindBrightness(_isDarkMode);
    AppShadows.bindTheme(_seedColor);
  }

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
    final colors = AppColors.forBrightness(
      _isDarkMode ? Brightness.dark : Brightness.light,
    );
    final SystemUiOverlayStyle overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          _isDarkMode ? Brightness.light : Brightness.dark,
      statusBarBrightness: _isDarkMode ? Brightness.dark : Brightness.light,
    );

    final baseTheme = AppThemes.buildTheme(
      seedColor: _seedColor,
      isDark: _isDarkMode,
      languageCode: languageCode,
    );

    return baseTheme.copyWith(
      appBarTheme: baseTheme.appBarTheme.copyWith(
        foregroundColor: colors.textPrimary,
        systemOverlayStyle: overlay,
        elevation: 0,
      ),
    );
  }

  /// Loads saved theme settings from secure storage
  Future<void> _loadThemeSettings() async {
    try {
      String? colorValue = await _readKey(_colorKey);
      String? darkModeValue = await _readKey(_darkModeKey);

      var migrated = false;
      if (colorValue == null) {
        colorValue = await _readLegacyKey(_colorKey);
        migrated = colorValue != null;
      }
      if (darkModeValue == null) {
        final legacyDark = await _readLegacyKey(_darkModeKey);
        if (legacyDark != null) {
          darkModeValue = legacyDark;
          migrated = true;
        }
      }

      // Lock brand to lime — migrate any previously saved custom accent.
      final parsedColor = _colorFromStorage(colorValue);
      if (parsedColor == null ||
          parsedColor.toARGB32() != primary.toARGB32()) {
        _seedColor = primary;
        migrated = true;
      } else {
        _seedColor = primary;
      }

      if (darkModeValue != null) {
        _isDarkMode = darkModeValue == 'true';
      }

      AppColors.bindTheme(_seedColor);
      AppColors.bindBrightness(_isDarkMode);
      AppShadows.bindTheme(_seedColor);

      if (migrated) {
        await _persistTheme();
      }
      notifyListeners();
    } catch (e) {
      // Swallow errors to avoid blocking app startup; fall back to defaults
    }
  }

  Future<String?> _readKey(String key) {
    return _storage.read(
      key: key,
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  Future<String?> _readLegacyKey(String key) async {
    final shared = await _storage.read(
      key: key,
      aOptions: _legacyAndroidOptions,
      iOptions: _iosOptions,
    );
    if (shared != null) return shared;
    return _storage.read(key: key);
  }

  Future<void> _persistTheme() async {
    await _storage.write(
      key: _colorKey,
      value: _colorToStorage(_seedColor),
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
    await _storage.write(
      key: _darkModeKey,
      value: _isDarkMode.toString(),
      aOptions: _androidOptions,
      iOptions: _iosOptions,
    );
  }

  static String _colorToStorage(Color color) =>
      color.toARGB32().toRadixString(16).padLeft(8, '0');

  static Color? _colorFromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      var raw = value.startsWith('#') ? value.substring(1) : value;
      if (raw.startsWith('0x') || raw.startsWith('0X')) {
        return Color(int.parse(raw));
      }
      if (RegExp(r'^[0-9a-fA-F]{6,8}$').hasMatch(raw)) {
        if (raw.length == 6) raw = 'ff$raw';
        return Color(int.parse(raw, radix: 16));
      }
      return Color(int.parse(raw));
    } catch (_) {
      return null;
    }
  }

  /// Toggles between light and dark mode
  Future<void> toggleThemeMode() async {
    _isDarkMode = !_isDarkMode;
    AppColors.bindBrightness(_isDarkMode);
    notifyListeners();
    try {
      await _persistTheme();
    } catch (e) {
      // ignore
    }
  }

  /// Sets dark mode explicitly (used by Settings switch).
  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) return;
    _isDarkMode = enabled;
    AppColors.bindBrightness(_isDarkMode);
    notifyListeners();
    try {
      await _persistTheme();
    } catch (e) {
      // ignore
    }
  }

  /// Sets a new seed color for the theme (kept for API compatibility).
  /// Brand is locked to lime — custom accents are ignored.
  Future<void> setSeedColor(Color color) async {
    if (isSeedColor(primary)) return;
    _seedColor = primary;
    AppColors.bindTheme(_seedColor);
    AppShadows.bindTheme(_seedColor);
    notifyListeners();
    try {
      await _persistTheme();
    } catch (e) {
      // ignore
    }
  }

  /// Resets the theme to default settings
  Future<void> resetTheme() async {
    _isDarkMode = false;
    _seedColor = primary;
    AppColors.bindTheme(_seedColor);
    AppColors.bindBrightness(_isDarkMode);
    AppShadows.bindTheme(_seedColor);
    notifyListeners();
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
      await _storage.delete(
        key: _colorKey,
        aOptions: _legacyAndroidOptions,
        iOptions: _iosOptions,
      );
      await _storage.delete(
        key: _darkModeKey,
        aOptions: _legacyAndroidOptions,
        iOptions: _iosOptions,
      );
    } catch (e) {
      // ignore
    }
  }
}
