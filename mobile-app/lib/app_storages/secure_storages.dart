import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_variables.dart';

// await storage.write('intKey', 42);
// print(await storage.read('intKey'));

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final aOptions = AndroidOptions(
    // Don't enforce biometrics by default for generic key storage access.
    // Enforcing biometrics causes reads to fail or return null on devices
    // without enrolled biometrics which made `permissionsRequested` look
    // unset and re-show the permissions page repeatedly.
    enforceBiometrics: false,
    resetOnError: true,
    sharedPreferencesName: "_Pref_",
    preferencesKeyPrefix: "MOI_",
  );

  /// Device-level keys that should survive logout/session clear.
  static const List<String> _sessionPreserveKeys = [
    AppVariables.permissionsRequested,
    AppVariables.permissionsGranted,
  ];

  /// Save dynamic value as JSON string
  Future<void> save(String key, dynamic value) async {
    final jsonString = jsonEncode({'value': value});
    await _storage.write(key: key, value: jsonString, aOptions: aOptions);
  }

  /// Read value and decode it
  Future<dynamic> get(String key) async {
    final jsonString = await _storage.read(key: key, aOptions: aOptions);
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
    await _storage.delete(key: key, aOptions: aOptions);
  }

  /// Delete all keys
  Future<void> clearAll() async {
    printContent('Clearing all secure storage');
    await _storage.deleteAll(aOptions: aOptions);
  }

  /// Clears login/session data but keeps device-level onboarding flags.
  Future<void> clearSessionData() async {
    final preserved = <String, dynamic>{};
    for (final key in _sessionPreserveKeys) {
      final value = await get(key);
      if (value != null) {
        preserved[key] = value;
      }
    }

    await clearAll();

    for (final entry in preserved.entries) {
      await save(entry.key, entry.value);
    }
  }

  Future<void> saveToken(String value) async {
    await _storage.write(key: 'token', value: value, aOptions: aOptions);
  }

  Future<String> getToken() async {
    return await _storage.read(key: 'token', aOptions: aOptions) ?? '';
  }

  Future<void> saveNotificationToken(String value) async {
    await _storage.write(
      key: 'notificationToken',
      value: value,
      aOptions: aOptions,
    );
  }

  Future<String> getNotificationToken() async {
    return await _storage.read(key: 'notificationToken', aOptions: aOptions) ??
        '';
  }
}
