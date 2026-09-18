import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:moi/app_models/device_info_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceService {
  static Future<DeviceInfoModel> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    String deviceToken = "";
    try {
      deviceToken = await FirebaseMessaging.instance.getToken() ?? "";
    } catch (_) {
      deviceToken = "";
    }

    String appVersion = "";
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {
      appVersion = "";
    }

    return DeviceInfoModel(
      device_id: androidInfo.id,
      device_name: androidInfo.name,
      brand: androidInfo.brand,
      model: androidInfo.model,
      manufacturer: androidInfo.manufacturer,
      android_version: androidInfo.version.release,
      ram_size: (androidInfo.physicalRamSize / 1024).toStringAsFixed(2),
      token: deviceToken,
      platform: 'android',
      app_version: appVersion,
    );
  }
}
