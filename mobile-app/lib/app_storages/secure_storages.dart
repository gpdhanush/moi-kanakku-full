import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_storages/auth_credential_sanitizer.dart';

/// Platform-backed secure persistence for session credentials and prefs.
///
/// Auth JWTs are stored only via [saveToken] / [getToken] / [deleteToken].
/// Never log token values. Prefer [clearSessionData] over [clearAll] on logout
/// so device-level preferences survive.
class SecureStorageService {
  /// Storage key for the API Bearer JWT. Do not reuse for other data.
  static const String authTokenKey = 'token';

  /// FCM / push registration token (not an API credential).
  static const String notificationTokenKey = 'notificationToken';

  /// Invoked after session credentials are wiped so in-memory caches can clear.
  /// Registered by [Connection] to avoid a circular import.
  static void Function()? onSessionCleared;

  final _storage = const FlutterSecureStorage();

  final AndroidOptions aOptions = const AndroidOptions(
    // Don't enforce biometrics by default for generic key storage access.
    // Enforcing biometrics causes reads to fail or return null on devices
    // without enrolled biometrics which made `permissionsRequested` look
    // unset and re-show the permissions page repeatedly.
    enforceBiometrics: false,
    resetOnError: true,
    storageNamespace: '_Pref_',
    preferencesKeyPrefix: 'MOI_',
  );

  /// Keychain: available after first unlock; does not sync via iCloud.
  /// Keep default accountName so existing installs still find stored keys.
  final IOSOptions iOptions = const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  /// Device-level keys that should survive logout/session clear.
  static const List<String> _sessionPreserveKeys = [
    AppVariables.permissionsRequested,
    AppVariables.permissionsGranted,
    'app_language',
    'voice_language',
  ];

  /// ThemeProvider writes these as raw strings (not JSON).
  static const List<String> _rawSessionPreserveKeys = [
    'theme_color',
    'dark_mode',
  ];

  /// Save dynamic value as JSON string. Strips auth secrets from user blobs.
  Future<void> save(String key, dynamic value) async {
    var toStore = value;
    if (key == AppVariables.userInformation && value is Map) {
      toStore = AuthCredentialSanitizer.stripSecretsFromMap(
        Map<String, dynamic>.from(value),
      );
    }
    final jsonString = jsonEncode({'value': toStore});
    await _storage.write(
      key: key,
      value: jsonString,
      aOptions: aOptions,
      iOptions: iOptions,
    );
  }

  /// Read value and decode it
  Future<dynamic> get(String key) async {
    final jsonString = await _storage.read(
      key: key,
      aOptions: aOptions,
      iOptions: iOptions,
    );
    if (jsonString == null) return null;

    final decoded = jsonDecode(jsonString);
    return decoded['value'];
  }

  /// Whether the onboarding permission screen was already shown/handled.
  Future<bool> hasPermissionsBeenRequested() async {
    final value = await get(AppVariables.permissionsRequested);
    if (value == true) return true;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) return value != 0;
    return false;
  }

  /// Delete a specific key
  Future<void> delete(String key) async {
    await _storage.delete(key: key, aOptions: aOptions, iOptions: iOptions);
  }

  /// Delete all keys in the session namespace.
  Future<void> clearAll() async {
    printContent('Clearing all secure storage');
    await _storage.deleteAll(aOptions: aOptions, iOptions: iOptions);
    _notifySessionCleared();
  }

  /// Clears login/session data but keeps device-level preferences.
  Future<void> clearSessionData() async {
    final preserved = <String, dynamic>{};
    for (final key in _sessionPreserveKeys) {
      final value = await get(key);
      if (value != null) {
        preserved[key] = value;
      }
    }

    final rawPreserved = <String, String>{};
    for (final key in _rawSessionPreserveKeys) {
      final value = await _storage.read(
        key: key,
        aOptions: aOptions,
        iOptions: iOptions,
      );
      if (value != null) {
        rawPreserved[key] = value;
      }
    }

    await _storage.deleteAll(aOptions: aOptions, iOptions: iOptions);

    for (final entry in preserved.entries) {
      await save(entry.key, entry.value);
    }
    for (final entry in rawPreserved.entries) {
      await _storage.write(
        key: entry.key,
        value: entry.value,
        aOptions: aOptions,
        iOptions: iOptions,
      );
    }

    // Clear deprecated process-wide JWT mirror if still present.
    jwtToken = null;
    _notifySessionCleared();
  }

  Future<void> saveToken(String value) async {
    if (value.isEmpty) {
      await deleteToken();
      return;
    }
    await _storage.write(
      key: authTokenKey,
      value: value,
      aOptions: aOptions,
      iOptions: iOptions,
    );
  }

  Future<String> getToken() async {
    return await _storage.read(
          key: authTokenKey,
          aOptions: aOptions,
          iOptions: iOptions,
        ) ??
        '';
  }

  Future<void> deleteToken() async {
    await _storage.delete(
      key: authTokenKey,
      aOptions: aOptions,
      iOptions: iOptions,
    );
    jwtToken = null;
    _notifySessionCleared();
  }

  Future<bool> hasAuthToken() async {
    final token = await getToken();
    return token.isNotEmpty;
  }

  Future<void> saveNotificationToken(String value) async {
    await _storage.write(
      key: notificationTokenKey,
      value: value,
      aOptions: aOptions,
      iOptions: iOptions,
    );
  }

  Future<String> getNotificationToken() async {
    return await _storage.read(
          key: notificationTokenKey,
          aOptions: aOptions,
          iOptions: iOptions,
        ) ??
        '';
  }

  void _notifySessionCleared() {
    try {
      onSessionCleared?.call();
    } catch (_) {
      // Listeners must not break logout.
    }
  }
}
