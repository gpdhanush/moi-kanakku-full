import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// PRINT ONLY PAGE TITLES
void pageTitleLogs(String title) {
  if (!kReleaseMode) {
    debugPrint("===> Page Title: $title <===");
  }
}

/// Safely encode data for logging, handling FormData and other non-encodable objects
String _safeEncode(dynamic data) {
  try {
    if (data == null) {
      return 'null';
    }
    // Handle FormData objects
    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}: ${e.value}').join(', ');
      final files = data.files.map((e) => '${e.key}: [File]').join(', ');
      return 'FormData: {fields: [$fields], files: [$files]}';
    }
    // Try to encode as JSON
    return jsonEncode(data);
  } catch (e) {
    // If encoding fails, return string representation
    return data.toString();
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
    // debugPrint("STATUS-CODE : ${_safeEncode(response?.statusCode ?? 'N/A')}");
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
    // Print to console
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

    // Add additional info if provided
    if (additionalInfo != null) {
      additionalInfo.forEach((key, value) {
        FirebaseCrashlytics.instance.setCustomKey(key, value);
      });
    }
  } catch (e) {
    debugPrint('Failed to log error to Crashlytics: $e');
  }
}

/// Log API error with request/response details
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
