import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:moi/app_configs/api_startup_config.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_firebase/firebase_remote.dart';
import 'package:moi/app_pages/force_update/force_update_dialog.dart';
import 'package:moi/app_services/connection.dart';
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
  bool _isDisposed = false;

  String get version => _version;
  double get progress => _progress;
  int get progressPercent => (_progress * 100).clamp(0, 100).round();
  String get statusLabel => _statusLabel;

  bool get _isActive => !_isDisposed;

  void setContext(BuildContext context) {
    if (_isDisposed) return;
    _context = context;
  }

  Future<void> _setProgress(double value, String label) async {
    if (!_isActive) return;
    _progress = value.clamp(0.0, 1.0);
    _statusLabel = label;
    notifyListeners();
    // Allow the UI one frame to paint the update.
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }

  Future<void> init() async {
    if (!_isActive) return;

    await _setProgress(0.08, 'Preparing app…');
    if (!_isActive) return;

    await _fetchAppVersion();
    if (!_isActive || _context == null) return;

    await _setProgress(0.28, 'Checking configuration…');
    if (!_isActive) return;

    final remoteConfig = await getFirebaseRemoteConfig(forceRefresh: true);
    if (!_isActive || _context == null) return;

    await _setProgress(0.48, 'Validating services…');
    if (!_isActive) return;

    final startupConfig = ApiStartupConfig.applyStartupValidation(
      baseUrl: appBaseUri,
      apiKey: apiSecretKey,
    );
    if (!startupConfig.isValid) {
      await navigation('configuration_error');
      return;
    }

    await _setProgress(0.62, 'Checking updates…');
    if (!_isActive) return;

    if (remoteConfig?.maintenanceMode == true) {
      await navigation('maintenance');
      return;
    }

    final minAppVersion = remoteConfig?.minAppVersion ?? '';
    if (isVersionBelowMinimum(_version, minAppVersion)) {
      await _setProgress(1.0, 'Update required');
      if (!_isActive || _context == null || !_context!.mounted) return;
      await ForceUpdateDialog.show(
        _context!,
        currentVersion: _version,
        minVersion: minAppVersion,
      );
      return;
    }

    await _setProgress(0.82, 'Finishing up…');
    if (!_isActive) return;

    await getRoute();
  }

  Future<void> _fetchAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!_isActive) return;
    _version = "${packageInfo.version}.${packageInfo.buildNumber}";
    appVersion = _version;
    notifyListeners();
  }

  Future<void> navigation(String route) async {
    await _setProgress(1.0, 'Ready');
    if (!_isActive || _context == null || !_context!.mounted) return;
    await Navigator.pushNamedAndRemoveUntil(_context!, route, (route) => false);
  }

  Future<void> _handleBiometricFlow() async {
    final check = await AppBioMetric().checkBioMetric();
    if (!_isActive) return;
    if (check == true) {
      await navigation("home");
    } else {
      FlutterExitApp.exitApp();
    }
  }

  Future<void> getRoute() async {
    if (!_isActive || _context == null) return;

    isLoggedIn = await secureStorage.get(AppVariables.isLogin) ?? false;
    if (!_isActive) return;

    final token = await secureStorage.getToken();
    final hasValidSession = isLoggedIn && token.isNotEmpty;

    if (hasValidSession) {
      isBioLock = await secureStorage.get(AppVariables.appLock) ?? false;
      if (!_isActive) return;
      if (isBioLock) {
        await _handleBiometricFlow();
      } else {
        await navigation("home");
      }
      return;
    }

    // Flag without token (or token without flag) → clear and force re-auth.
    if (isLoggedIn || token.isNotEmpty) {
      Connection.instance.clearCachedToken();
      await secureStorage.clearSessionData();
    }

    final permissionsRequested =
        await secureStorage.hasPermissionsBeenRequested();
    if (!_isActive) return;

    if (!permissionsRequested) {
      await navigation("permissions");
    } else {
      await navigation("login");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _context = null;
    super.dispose();
  }
}
