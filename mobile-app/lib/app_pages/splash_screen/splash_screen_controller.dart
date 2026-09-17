import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:moi/app_configs/api_startup_config.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_firebase/firebase_remote.dart';
import 'package:moi/app_pages/force_update/force_update_dialog.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_global/app_bio_metric.dart';
import 'package:moi/app_utils/app_global/app_version_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreenController extends ChangeNotifier {
  SecureStorageService secureStorage = SecureStorageService();
  bool isLoggedIn = false;
  bool isBioLock = false;
  BuildContext? _context;
  String _version = '';
  double _progress = 0;
  String _statusLabel = 'Starting…';

  String get version => _version;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).clamp(0, 100).round();
  String get statusLabel => _statusLabel;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> _setProgress(double value, String label) async {
    _progress = value.clamp(0.0, 1.0);
    _statusLabel = label;
    notifyListeners();
    // Allow the UI one frame to paint the update.
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }

  Future<void> init() async {
    await _setProgress(0.08, 'Preparing app…');
    await _fetchAppVersion();
    if (_context == null) return;

    await _setProgress(0.28, 'Checking configuration…');
    final remoteConfig = await getFirebaseRemoteConfig(forceRefresh: true);
    if (_context == null) return;

    await _setProgress(0.48, 'Validating services…');
    final startupConfig = ApiStartupConfig.applyStartupValidation(
      baseUrl: appBaseUri,
      apiKey: apiSecretKey,
    );
    if (!startupConfig.isValid) {
      await _setProgress(1.0, 'Ready');
      await navigation('configuration_error');
      return;
    }

    await _setProgress(0.62, 'Checking updates…');
    if (remoteConfig?.maintenanceMode == true) {
      await _setProgress(1.0, 'Ready');
      await navigation('maintenance');
      return;
    }

    final minAppVersion = remoteConfig?.minAppVersion ?? '';
    if (isVersionBelowMinimum(_version, minAppVersion)) {
      await _setProgress(1.0, 'Update required');
      if (_context == null || !_context!.mounted) return;
      await ForceUpdateDialog.show(
        _context!,
        currentVersion: _version,
        minVersion: minAppVersion,
      );
      return;
    }

    await _setProgress(0.82, 'Finishing up…');
    await getRoute();
  }

  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _version = "${packageInfo.version}.${packageInfo.buildNumber}";
    appVersion = _version;
    notifyListeners();
  }

  Future<void> navigation(String route) async {
    await _setProgress(1.0, 'Ready');
    if (_context == null) return;
    if (!(_context!.mounted)) return;
    await Navigator.pushNamedAndRemoveUntil(_context!, route, (route) => false);
  }

  Future<void> _handleBiometricFlow() async {
    final check = await AppBioMetric().checkBioMetric();
    if (check.toString() == "true") {
      await navigation("home");
    } else {
      FlutterExitApp.exitApp();
    }
  }

  Future<void> getRoute() async {
    if (_context == null) return;

    isLoggedIn = await secureStorage.get(AppVariables.isLogin) ?? false;

    if (isLoggedIn) {
      isBioLock = await secureStorage.get(AppVariables.appLock) ?? false;
      if (isBioLock) {
        await _handleBiometricFlow();
      } else {
        await navigation("home");
      }
      return;
    }

    final permissionsRequested =
        await secureStorage.hasPermissionsBeenRequested();

    if (!permissionsRequested) {
      await navigation("permissions");
    } else {
      await navigation("login");
    }
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }
}
