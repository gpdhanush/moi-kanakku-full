import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helpers for image picking that avoid broad media permissions on Android 13+.
///
/// On API 33+, the system photo picker is used and no READ_MEDIA_* permission
/// is required. Older Android versions still use READ_EXTERNAL_STORAGE.
class ImagePickerPermissions {
  static int? _androidSdkInt;

  static Future<int> androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    _androidSdkInt ??= (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    return _androidSdkInt!;
  }

  static Future<bool> usesSystemPhotoPicker() async {
    if (!Platform.isAndroid) return false;
    return await androidSdkInt() >= 33;
  }

  static Future<bool> ensureCameraPermission({bool request = true}) async {
    var status = await Permission.camera.status;
    if (!status.isGranted && request) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  static Future<bool> ensureGalleryPermission({bool request = true}) async {
    if (Platform.isAndroid) {
      if (await usesSystemPhotoPicker()) {
        return true;
      }
      var status = await Permission.storage.status;
      if (!status.isGranted && request) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }

    var status = await Permission.photos.status;
    if (!status.isGranted && request) {
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

  static Future<Map<String, bool>> checkImagePickerPermissions({
    bool request = true,
  }) async {
    final camera = await ensureCameraPermission(request: request);
    final gallery = await ensureGalleryPermission(request: request);
    return {'camera': camera, 'photos': gallery};
  }
}
