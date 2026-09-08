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

  String get version => _version;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> init() async {
    await _fetchAppVersion();
    if (_context == null) return;

    final remoteConfig = await getFirebaseRemoteConfig(forceRefresh: true);
    if (_context == null) return;

    final startupConfig = ApiStartupConfig.applyStartupValidation(
      baseUrl: appBaseUri,
      apiKey: apiSecretKey,
    );
    if (!startupConfig.isValid) {
      await navigation('configuration_error');
      return;
    }

    if (remoteConfig?.maintenanceMode == true) {
      await navigation('maintenance');
      return;
    }

    final minAppVersion = remoteConfig?.minAppVersion ?? '';
    if (isVersionBelowMinimum(_version, minAppVersion)) {
      if (_context == null || !_context!.mounted) return;
      await ForceUpdateDialog.show(
        _context!,
        currentVersion: _version,
        minVersion: minAppVersion,
      );
      return;
    }

    await getRoute();
  }

  // Fetches the app version from the platform
  Future<void> _fetchAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _version = "${packageInfo.version}.${packageInfo.buildNumber}";
    appVersion = _version;
    notifyListeners();
  }

  // Navigates to the specified route
  Future<void> navigation(String route) async {
    if (_context == null) return;
    if (!(_context!.mounted)) return;
    await Navigator.pushNamedAndRemoveUntil(_context!, route, (route) => false);
  }

  // Handles biometric verification
  Future<void> _handleBiometricFlow() async {
    final check = await AppBioMetric().checkBioMetric();
    if (check.toString() == "true") {
      // Biometrics passed
      await navigation("home");
    } else {
      // Biometrics failed, exit app
      FlutterExitApp.exitApp();
    }
  }

  // Determines the route based on login and biometric status
  Future<void> getRoute() async {
    if (_context == null) return;

    // First check if user is already logged in
    isLoggedIn = await secureStorage.get(AppVariables.isLogin) ?? false;

    if (isLoggedIn) {
      // If logged in, skip permissions check and go directly to home
      isBioLock = await secureStorage.get(AppVariables.appLock) ?? false;
      if (isBioLock) {
        await _handleBiometricFlow();
      } else {
        await navigation("home");
      }
      return;
    }

    // Check if onboarding has been completed
    final onboardingCompleted =
        await secureStorage.get("onboardingCompleted") ?? false;

    if (!onboardingCompleted) {
      await navigation("onboarding");
      return;
    }

    // User is not logged in, check permissions
    final permissionsRequested = await secureStorage
        .hasPermissionsBeenRequested();

    if (!permissionsRequested) {
      // Navigate to permission page only if permissions haven't been requested yet
      await navigation("permissions");
    } else {
      // Permissions already handled, go to login
      await navigation("login");
    }
  }

  @override
  void dispose() {
    _context = null;
    super.dispose();
  }
}
