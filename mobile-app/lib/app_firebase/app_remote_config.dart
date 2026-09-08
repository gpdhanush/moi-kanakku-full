class AppRemoteConfig {
  final String liveURL;
  final String imageUrl;
  final String apiSecretKey;
  final bool maintenanceMode;
  final String minAppVersion;

  static AppRemoteConfig? _current;

  static AppRemoteConfig? get current => _current;

  const AppRemoteConfig({
    required this.liveURL,
    required this.imageUrl,
    required this.apiSecretKey,
    this.maintenanceMode = false,
    this.minAppVersion = '',
  });

  factory AppRemoteConfig.fromJson(
    Map<String, dynamic> json, {
    required String fallbackLiveUrl,
    required String fallbackImageUrl,
    required String fallbackApiSecretKey,
  }) {
    return AppRemoteConfig(
      liveURL: json['liveURL']?.toString() ?? fallbackLiveUrl,
      imageUrl: json['imageUrl']?.toString() ?? fallbackImageUrl,
      apiSecretKey:
          json['apiSecretKey']?.toString() ?? fallbackApiSecretKey,
      maintenanceMode: _parseBool(
        json['maintenanceMode'] ??
            json['maintenance_mode'] ??
            json['maintaincemode'],
      ),
      minAppVersion: json['min_app_version']?.toString().trim() ?? '',
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  static void updateCurrent(AppRemoteConfig config) {
    _current = config;
  }
}
