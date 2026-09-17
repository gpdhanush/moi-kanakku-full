import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

const _sensitiveKeys = {
  'password',
  'oldpassword',
  'newpassword',
  'confirmpassword',
  'otp',
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'x-api-key',
  'apisecretkey',
  'secret',
  'fcm_token',
  'fcmtoken',
};

/// PRINT ONLY PAGE TITLES
void pageTitleLogs(String title) {
  if (!kReleaseMode) {
    debugPrint("===> Page Title: $title <===");
  }
}

bool _isSensitiveKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return _sensitiveKeys.contains(normalized);
}

/// Redacts passwords, tokens, OTP, and API keys from log payloads.
dynamic redactSensitive(dynamic data) {
  if (data == null) return null;
  if (data is FormData) {
    final fields = data.fields
        .map(
          (e) => MapEntry(
            e.key,
            _isSensitiveKey(e.key) ? '***' : e.value,
          ),
        )
        .toList();
    final files = data.files.map((e) => '${e.key}: [File]').join(', ');
    final fieldStr =
        fields.map((e) => '${e.key}: ${e.value}').join(', ');
    return 'FormData: {fields: [$fieldStr], files: [$files]}';
  }
  if (data is Map) {
    return data.map((key, value) {
      final keyStr = key.toString();
      if (_isSensitiveKey(keyStr)) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, redactSensitive(value));
    });
  }
  if (data is List) {
    return data.map(redactSensitive).toList();
  }
  if (data is String) {
    // Avoid dumping long JWTs / secrets accidentally.
    if (data.length > 40 &&
        (data.startsWith('eyJ') || data.toLowerCase().contains('bearer '))) {
      return '***';
    }
  }
  return data;
}

/// Safely encode data for logging, handling FormData and other non-encodable objects
String _safeEncode(dynamic data) {
  try {
    if (data == null) {
      return 'null';
    }
    final redacted = redactSensitive(data);
    if (redacted is String) {
      return redacted;
    }
    return jsonEncode(redacted);
  } catch (e) {
    return '[unencodable]';
  }
}

/// PRINT ONLY SERVICE CLASS
void serviceLogs(
  String url, {
  String? method = 'POST',
  dynamic request,
  dynamic response,
}) {
  if (!kReleaseMode) {
    debugPrint("-----------------------------------");
    debugPrint("METHOD NAME : [$method]");
    debugPrint("API URL     : ${Uri.parse(url)}");
    debugPrint("REQUEST     : ${_safeEncode(request)}");
    debugPrint("RESPONSE    : ${_safeEncode(response)}");
    debugPrint("-----------------------------------");
  }
}

/// PRINT RESPONSE
void printContent(String content) {
  if (!kReleaseMode) {
    debugPrint("-----------------------------------");
    debugPrint(content);
    debugPrint("-----------------------------------");
  }
}

/// PRINT RESPONSE
void printDirect(String content) {
  if (!kReleaseMode) {
    debugPrint(content);
  }
}

/// Log error to Firebase Crashlytics with context
void logErrorToCrashlytics(
  Object error,
  StackTrace stack, {
  String context = 'Unknown',
  Map<String, String>? additionalInfo,
}) {
  try {
    // Print to console (debug only)
    printContent('[$context] ERROR: ${error.toString()}');

    // Record to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: context,
      printDetails: !kReleaseMode,
    );

    // Set custom crash info for context
    FirebaseCrashlytics.instance.setCustomKey('error_context', context);

    // Add additional info if provided (already expect callers to redact)
    if (additionalInfo != null) {
      additionalInfo.forEach((key, value) {
        if (_isSensitiveKey(key)) return;
        FirebaseCrashlytics.instance.setCustomKey(key, value);
      });
    }
  } catch (e) {
    debugPrint('Failed to log error to Crashlytics: $e');
  }
}

/// Log API error with request/response details (no request bodies / secrets).
void logApiErrorToCrashlytics(
  DioException error, {
  String endpoint = 'Unknown',
  dynamic requestData,
  int? statusCode,
}) {
  try {
    final additionalInfo = {
      'endpoint': endpoint,
      'status_code': statusCode?.toString() ?? 'N/A',
      'error_type': error.type.toString(),
      'error_message': error.message ?? 'No message',
      // Never attach raw request bodies — only note whether a body existed.
      'had_request_body': (requestData != null).toString(),
    };

    logErrorToCrashlytics(
      error,
      error.stackTrace ?? StackTrace.current,
      context: 'API_ERROR: $endpoint',
      additionalInfo: additionalInfo,
    );
  } catch (e) {
    debugPrint('Failed to log API error to Crashlytics: $e');
  }
}

/// Returns header map with sensitive values redacted for logging.
Map<String, String> redactHeaders(Map<String, dynamic> headers) {
  return headers.map((key, value) {
    if (_isSensitiveKey(key) ||
        key.toLowerCase() == 'authorization' ||
        key.toLowerCase() == 'x-api-key') {
      return MapEntry(key, '***');
    }
    return MapEntry(key, value?.toString() ?? '');
  });
}
