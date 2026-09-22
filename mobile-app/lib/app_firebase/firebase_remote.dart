import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_firebase/app_remote_config.dart';

const _appVersionConfigKey = 'moiAppVersionConfig';

/// Loads public URLs from Firebase Remote Config and server-controlled
/// maintenance/version values from the backend runtime-config endpoint.
Future<AppRemoteConfig?> getRuntimeConfig() async {
  Map<String, dynamic> remoteUrls = {};
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await remoteConfig.setDefaults({
      _appVersionConfigKey: jsonEncode({
        'versionConfig': [
          {'liveURL': bootstrapApiBaseUri, 'imageUrl': ''},
        ],
      }),
    });
    await remoteConfig.fetchAndActivate();
    remoteUrls = _readRemoteUrls(remoteConfig.getString(_appVersionConfigKey));
  } catch (_) {
    // The backend config remains available when Firebase Remote Config is
    // unavailable during startup or on an offline launch.
  }

  try {
    final response = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (status) => status != null && status < 500,
      ),
    ).get('$bootstrapApiBaseUri/app-config/public');

    final data = response.data;
    Map<String, dynamic> serverValues = {};
    if (data is Map && data['responseType'] == 'S') {
      final value = data['responseValue'];
      if (value is Map) {
        serverValues = Map<String, dynamic>.from(value);
      }
    }

    if (remoteUrls.isEmpty && serverValues.isEmpty) {
      return AppRemoteConfig.current;
    }

    final config = AppRemoteConfig.fromJson(
      {
        'liveURL': remoteUrls['liveURL'] ?? bootstrapApiBaseUri,
        'imageUrl': remoteUrls['imageUrl'] ?? appImageUrl,
        'maintenanceMode':
            serverValues['maintenanceMode'] ??
            serverValues['maintenance_mode'] ??
            false,
        'minAppVersion':
            serverValues['minAppVersion'] ??
            serverValues['min_app_version'] ??
            '',
      },
      fallbackLiveUrl: bootstrapApiBaseUri,
      fallbackImageUrl: appImageUrl,
    );
    appBaseUri = config.liveURL;
    appImageUrl = config.imageUrl;
    AppRemoteConfig.updateCurrent(config);
    return config;
  } catch (_) {
    if (remoteUrls.isEmpty) return AppRemoteConfig.current;
    final config = AppRemoteConfig.fromJson(
      remoteUrls,
      fallbackLiveUrl: bootstrapApiBaseUri,
      fallbackImageUrl: appImageUrl,
    );
    appBaseUri = config.liveURL;
    appImageUrl = config.imageUrl;
    AppRemoteConfig.updateCurrent(config);
    return config;
  }
}

Map<String, dynamic> _readRemoteUrls(String rawValue) {
  if (rawValue.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(rawValue);
    if (decoded is! Map) return {};
    final versionConfig = decoded['versionConfig'];
    if (versionConfig is! List || versionConfig.isEmpty) return {};
    final firstConfig = versionConfig.first;
    if (firstConfig is! Map) return {};
    final value = Map<String, dynamic>.from(firstConfig);
    return {
      if (value['liveURL']?.toString().trim().isNotEmpty == true)
        'liveURL': value['liveURL'].toString().trim(),
      if (value['imageUrl']?.toString().trim().isNotEmpty == true)
        'imageUrl': value['imageUrl'].toString().trim(),
    };
  } catch (_) {
    return {};
  }
}
