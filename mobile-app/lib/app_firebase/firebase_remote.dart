import 'package:dio/dio.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_firebase/app_remote_config.dart';

/// Loads non-sensitive runtime values from the backend-managed public config.
Future<AppRemoteConfig?> getRuntimeConfig() async {
  try {
    final response = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (status) => status != null && status < 500,
      ),
    ).get('$bootstrapApiBaseUri/app-config/public');

    final data = response.data;
    if (data is! Map || data['responseType'] != 'S') {
      return AppRemoteConfig.current;
    }
    final value = data['responseValue'];
    if (value is! Map) return AppRemoteConfig.current;

    final config = AppRemoteConfig.fromJson(
      Map<String, dynamic>.from(value),
      fallbackLiveUrl: bootstrapApiBaseUri,
      fallbackImageUrl: appImageUrl,
    );
    appBaseUri = config.liveURL;
    appImageUrl = config.imageUrl;
    AppRemoteConfig.updateCurrent(config);
    return config;
  } catch (_) {
    return AppRemoteConfig.current;
  }
}
