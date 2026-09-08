import 'package:local_auth/local_auth.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

import 'alert_services.dart';

/// A class that handles biometric authentication functionality.
///
/// This class provides methods to:
/// - Check if biometric authentication is available on the device
/// - Authenticate users using biometrics (fingerprint/face recognition)
/// - Handle authentication errors and show appropriate messages
class AppBioMetric {
  final LocalAuthentication _auth = LocalAuthentication();
  final AlertServices _alertServices = AlertServices();

  String _tr(String key, String fallback) {
    final context = navigatorKey.currentState?.overlay?.context;
    return context?.read<LanguageProvider>().tr(key) ?? fallback;
  }

  /// Checks if biometric authentication is available and authenticates the user.
  ///
  /// Returns:
  /// - [true] if authentication was successful
  /// - [false] if authentication failed or is not available
  Future<bool> checkBioMetric() async {
    try {
      // Check if device supports biometrics
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        _alertServices.errorToast(
          _tr(
            'biometrics.deviceNotSupported',
            'Device does not support biometrics',
          ),
        );
        return false;
      }

      // Get available biometric types
      final List<BiometricType> availableBiometrics = await _auth
          .getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        _alertServices.errorToast(
          _tr('biometrics.noneAvailable', 'No biometrics available'),
        );
        return false;
      }

      // Check for strong biometrics (fingerprint) or face recognition
      final bool hasStrongBiometrics = availableBiometrics.contains(
        BiometricType.strong,
      );
      final bool hasFaceRecognition = availableBiometrics.contains(
        BiometricType.face,
      );

      if (!hasStrongBiometrics && !hasFaceRecognition) {
        _alertServices.errorToast(
          _tr(
            'biometrics.typesUnavailable',
            'No supported biometric types available',
          ),
        );
        return false;
      }

      // Attempt authentication
      return await _auth.authenticate(
        localizedReason: _tr(
          'biometrics.verifyIdentity',
          'Please verify your identity',
        ),
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: false,
      );
    } catch (e) {
      _alertServices.errorToast(
        '${_tr('biometrics.authenticationFailed', 'Authentication failed')}: ${e.toString()}',
      );
      return false;
    }
  }
}
