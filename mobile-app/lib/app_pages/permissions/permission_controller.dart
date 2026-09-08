import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:moi/app_storages/secure_storages.dart';

class PermissionInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Permission permission;

  PermissionInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.permission,
  });
}

class PermissionController extends ChangeNotifier {
  SecureStorageService secureStorage = SecureStorageService();
  BuildContext? _context;
  bool isRequesting = false;
  bool isLoadingPermissions = true;
  Set<String> grantedPermissions = {};
  bool _disposed = false;
  List<PermissionInfo> _permissions = [];

  List<PermissionInfo> get permissions => _permissions;

  Future<void> initializePermissions() async {
    final perms = <PermissionInfo>[
      PermissionInfo(
        id: 'notifications',
        name: 'அறிவிப்புகள்',
        description: 'முக்கியமான அறிவிப்புகள் மற்றும் புதுப்பித்தல்களைப் பெற',
        icon: Icons.notifications_outlined,
        permission: Permission.notification,
      ),
      PermissionInfo(
        id: 'camera',
        name: 'கேமரா',
        description: 'புகைப்படங்கள் எடுக்கவும் பயன்பாட்டில் பயன்படுத்தவும்',
        icon: Icons.camera_alt_outlined,
        permission: Permission.camera,
      ),
      PermissionInfo(
        id: 'microphone',
        name: 'மைக்ரோஃபோன்',
        description: 'ஒலி பதிவு மற்றும் பேச்சு-உரை மாற்றத்திற்கு',
        icon: Icons.mic_outlined,
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
            name: 'புகைப்படங்கள்',
            description: 'புகைப்படங்களை அணுகவும் பகிரவும்',
            icon: Icons.photo_library_outlined,
            permission: Permission.storage,
          ),
        );
      }
    } else if (Platform.isIOS) {
      perms.add(
        PermissionInfo(
          id: 'photos',
          name: 'புகைப்படங்கள்',
          description: 'புகைப்படங்களை அணுகவும் பகிரவும்',
          icon: Icons.photo_library_outlined,
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
    for (var permInfo in _permissions) {
      final status = await permInfo.permission.status;
      if (status.isGranted) {
        grantedPermissions.add(permInfo.id);
      }
    }
    if (!_disposed) {
      notifyListeners();
    }
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
