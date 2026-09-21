import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:hugeicons/hugeicons.dart';

class PermissionInfo {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final List<List<dynamic>> icon;
  final String? imageAsset;
  final Permission permission;

  PermissionInfo({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.icon,
    this.imageAsset,
    required this.permission,
  });
}

class PermissionController extends ChangeNotifier {
  SecureStorageService secureStorage = SecureStorageService();
  BuildContext? _context;
  bool isRequesting = false;
  bool isLoadingPermissions = true;
  Set<String> grantedPermissions = {};
  Set<String> permanentlyDeniedPermissions = {};
  bool _disposed = false;
  List<PermissionInfo> _permissions = [];

  List<PermissionInfo> get permissions => _permissions;

  Future<void> initializePermissions() async {
    final perms = <PermissionInfo>[
      PermissionInfo(
        id: 'notifications',
        nameKey: 'permissions.items.notifications.name',
        descriptionKey: 'permissions.items.notifications.description',
        icon: HugeIcons.strokeRoundedNotification01,
        imageAsset: 'assets/images/permission/notification.png',
        permission: Permission.notification,
      ),
      PermissionInfo(
        id: 'camera',
        nameKey: 'permissions.items.camera.name',
        descriptionKey: 'permissions.items.camera.description',
        icon: HugeIcons.strokeRoundedCamera01,
        imageAsset: 'assets/images/permission/camera.png',
        permission: Permission.camera,
      ),
      PermissionInfo(
        id: 'microphone',
        nameKey: 'permissions.items.microphone.name',
        descriptionKey: 'permissions.items.microphone.description',
        icon: HugeIcons.strokeRoundedMic01,
        imageAsset: 'assets/images/permission/mic.png',
        permission: Permission.microphone,
      ),
    ];

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Android 13+ uses the system photo picker; no broad media permission needed.
      if (androidInfo.version.sdkInt < 33) {
        perms.add(
          PermissionInfo(
            id: 'photos',
            nameKey: 'permissions.items.photos.name',
            descriptionKey: 'permissions.items.photos.description',
            icon: HugeIcons.strokeRoundedAlbum01,
            permission: Permission.storage,
          ),
        );
      }
    } else if (Platform.isIOS) {
      perms.add(
        PermissionInfo(
          id: 'photos',
          nameKey: 'permissions.items.photos.name',
          descriptionKey: 'permissions.items.photos.description',
          icon: HugeIcons.strokeRoundedAlbum01,
          permission: Permission.photos,
        ),
      );
    }

    _permissions = perms;
    isLoadingPermissions = false;
    if (!_disposed) {
      notifyListeners();
    }
  }

  void setContext(BuildContext context) {
    _context = context;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await initializePermissions();
    await checkPermissions();
  }

  Future<void> checkPermissions() async {
    if (_disposed || _permissions.isEmpty) return;
    grantedPermissions.clear();
    permanentlyDeniedPermissions.clear();
    for (var permInfo in _permissions) {
      final status = await permInfo.permission.status;
      if (status.isGranted) {
        grantedPermissions.add(permInfo.id);
      } else if (status.isPermanentlyDenied) {
        permanentlyDeniedPermissions.add(permInfo.id);
      }
    }
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> requestSinglePermission(PermissionInfo permInfo) async {
    if (_disposed) return;
    final status = await permInfo.permission.status;
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    } else if (!status.isGranted) {
      await permInfo.permission.request();
    }
    await checkPermissions();
  }

  Future<void> requestAllPermissions() async {
    if (_context == null || _disposed || _permissions.isEmpty) return;

    isRequesting = true;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      final permissionsToRequest = <Permission>[];

      for (var permInfo in _permissions) {
        if (_disposed) return;
        final status = await permInfo.permission.status;
        if (!status.isGranted) {
          permissionsToRequest.add(permInfo.permission);
        }
      }

      if (permissionsToRequest.isNotEmpty && !_disposed) {
        await permissionsToRequest.request();
      }

      await secureStorage.save(AppVariables.permissionsRequested, true);

      if (!_disposed) {
        await checkPermissions();
      }

      bool allGranted = true;
      if (!_disposed) {
        for (var permInfo in _permissions) {
          final status = await permInfo.permission.status;
          if (!status.isGranted && !status.isPermanentlyDenied) {
            allGranted = false;
          }
        }

        await secureStorage.save(AppVariables.permissionsGranted, allGranted);

        if (_context != null && !_disposed) {
          await Navigator.pushNamedAndRemoveUntil(
            _context!,
            'login',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (_disposed) return;
      await secureStorage.save(AppVariables.permissionsRequested, true);
      await secureStorage.save(AppVariables.permissionsGranted, false);
      if (_context != null && !_disposed) {
        await Navigator.pushNamedAndRemoveUntil(
          _context!,
          'login',
          (route) => false,
        );
      }
    } finally {
      if (!_disposed) {
        isRequesting = false;
        notifyListeners();
      }
    }
  }

  Future<void> skipPermissions() async {
    if (_context == null || _disposed) return;

    await secureStorage.save(AppVariables.permissionsRequested, true);
    await secureStorage.save(AppVariables.permissionsGranted, false);

    if (_context != null && !_disposed) {
      await Navigator.pushNamedAndRemoveUntil(
        _context!,
        'login',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _context = null;
    super.dispose();
  }
}
