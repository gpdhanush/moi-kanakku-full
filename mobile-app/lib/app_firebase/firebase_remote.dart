import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:moi/app_configs/api_endpoint_allowlist.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_firebase/app_remote_config.dart';

Future<AppRemoteConfig?> getFirebaseRemoteConfig({
  bool forceRefresh = true,
}) async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;

    await remoteConfig.setDefaults({
      'moiAppVersionConfig':
          '{"versionConfig":[{"liveURL":"","imageUrl":"",'
          '"maintenanceMode":false,"min_app_version":""}]}',
    });

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: forceRefresh
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );

    try {
      final activated = await remoteConfig.fetchAndActivate();
      printDirect('Remote Config fetchAndActivate: activated=$activated');
    } catch (e) {
      printDirect('Remote Config fetch FAILED: $e');
    }

    final configString = remoteConfig.getString('moiAppVersionConfig');
    printDirect('Remote Config raw: $configString');

    if (configString.isEmpty) return AppRemoteConfig.current;

    final Map<String, dynamic> decoded =
        jsonDecode(configString) as Map<String, dynamic>;

    final versionConfig = decoded['versionConfig'];
    final Map<String, dynamic> first;
    if (versionConfig is List && versionConfig.isNotEmpty) {
      first = Map<String, dynamic>.from(versionConfig.first as Map);
    } else if (decoded.containsKey('liveURL') ||
        decoded.containsKey('imageUrl')) {
      first = decoded;
    } else {
      return AppRemoteConfig.current;
    }

    final config = AppRemoteConfig.fromJson(
      first,
      fallbackLiveUrl: appBaseUri,
      fallbackImageUrl: appImageUrl,
      fallbackApiSecretKey: apiSecretKey,
    );

    printDirect(
      'Remote Config parsed: maintenanceMode=${config.maintenanceMode}, '
      'minAppVersion=${config.minAppVersion}',
    );

    if (isAllowedApiEndpoint(config.liveURL)) {
      appBaseUri = config.liveURL;
    } else if (config.liveURL.trim().isNotEmpty) {
      printDirect(
        'Remote Config liveURL rejected: URL is not an approved HTTPS API endpoint',
      );
    }

    appImageUrl = config.imageUrl;
    if (config.apiSecretKey.isNotEmpty) {
      updateApiSecretKey(config.apiSecretKey);
    }
    AppRemoteConfig.updateCurrent(config);

    return config;
  } catch (e, stackTrace) {
    printDirect('Error in getFirebaseRemoteConfig: $e');
    printDirect('Stack trace: $stackTrace');
    return AppRemoteConfig.current;
  }
}
