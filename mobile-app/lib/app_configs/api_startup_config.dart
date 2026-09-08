import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:moi/app_configs/api_endpoint_allowlist.dart';

/// Non-sensitive codes logged when startup configuration is invalid.
enum ApiStartupConfigIssue {
  missingBaseUrl('missing_base_url'),
  invalidBaseUrl('invalid_base_url'),
  notHttps('not_https'),
  missingApiKey('missing_api_key');

  const ApiStartupConfigIssue(this.diagnosticCode);

  final String diagnosticCode;
}

class ApiStartupConfigResult {
  const ApiStartupConfigResult.valid()
      : isValid = true,
        issue = null;

  const ApiStartupConfigResult.invalid(this.issue) : isValid = false;

  final bool isValid;
  final ApiStartupConfigIssue? issue;
}

/// Startup-time API configuration gate.
///
/// [applyStartupValidation] must run during splash before routing so invalid
/// configs block all [Connection] requests.
class ApiStartupConfig {
  ApiStartupConfig._();

  static bool _apiRequestsAllowed = false;
  static ApiStartupConfigResult? _lastResult;

  static const String userErrorTitle = 'Configuration Error';
  static const String userErrorMessage =
      'பயன்பாட்டு அமைப்பில் சிக்கல் உள்ளது. சரியான API முகவரி மற்றும் API விசை '
      'அமைக்கப்படவில்லை. Try Again என்பதை அழுத்தி மீண்டும் முயற்சிக்கவும்.';

  /// Used by [Connection] to reject outbound API calls when config is invalid.
  static const String blockedRequestMessage =
      'API request blocked: startup configuration invalid';

  static bool get apiRequestsAllowed => _apiRequestsAllowed;
  static ApiStartupConfigResult? get lastResult => _lastResult;

  /// Validates [baseUrl] and [apiKey], updates the request gate, and logs a
  /// non-sensitive diagnostic when validation fails.
  static ApiStartupConfigResult applyStartupValidation({
    required String baseUrl,
    required String apiKey,
  }) {
    final result = validate(baseUrl: baseUrl, apiKey: apiKey);
    _lastResult = result;
    _apiRequestsAllowed = result.isValid;

    if (!result.isValid) {
      _logDiagnostic(result.issue!.diagnosticCode);
    }

    return result;
  }

  /// Resets the gate so API requests stay blocked until validation runs again.
  static void reset() {
    _apiRequestsAllowed = false;
    _lastResult = null;
  }

  static ApiStartupConfigResult validate({
    required String baseUrl,
    required String apiKey,
  }) {
    final trimmedBaseUrl = baseUrl.trim();
    if (trimmedBaseUrl.isEmpty) {
      return const ApiStartupConfigResult.invalid(
        ApiStartupConfigIssue.missingBaseUrl,
      );
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmedBaseUrl);
    } catch (_) {
      return const ApiStartupConfigResult.invalid(
        ApiStartupConfigIssue.invalidBaseUrl,
      );
    }

    if (uri.scheme != 'https') {
      return const ApiStartupConfigResult.invalid(
        ApiStartupConfigIssue.notHttps,
      );
    }

    if (!isAllowedApiEndpoint(trimmedBaseUrl)) {
      return const ApiStartupConfigResult.invalid(
        ApiStartupConfigIssue.invalidBaseUrl,
      );
    }

    if (apiKey.trim().isEmpty) {
      return const ApiStartupConfigResult.invalid(
        ApiStartupConfigIssue.missingApiKey,
      );
    }

    return const ApiStartupConfigResult.valid();
  }

  static void _logDiagnostic(String diagnosticCode) {
    debugPrint('API startup config invalid: $diagnosticCode');
    if (kReleaseMode) {
      FirebaseCrashlytics.instance.log(
        'API startup config invalid: $diagnosticCode',
      );
    }
  }
}
