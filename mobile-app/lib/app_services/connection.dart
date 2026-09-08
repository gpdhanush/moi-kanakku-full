import 'dart:io';
import 'dart:async' show unawaited;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:moi/app_configs/api_startup_config.dart';
import 'package:moi/app_configs/api_certificate_pinning.dart';
import 'package:moi/app_configs/dio_certificate_pinning.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_global/alert_services.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class Connection {
  final SecureStorageService secureStorage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();

  // Base header without API key (will be added dynamically)
  final Map<String, String> _baseHeader = {'Content-Type': 'application/json'};
  String? _cachedToken;
  late final Dio _dio;

  String _tr(String key, String fallback) {
    final context = navigatorKey.currentState?.overlay?.context;
    return context?.read<LanguageProvider>().tr(key) ?? fallback;
  }

  Connection() {
    _dio = Dio(
      BaseOptions(
        baseUrl: appBaseUri,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: _baseHeader,
        // Treat 404/400/403 as success so we can read API JSON (e.g. responseType "F", message, deleted account)
        validateStatus: (status) =>
            status != null &&
            (status < 300 || status == 400 || status == 403 || status == 404),
      ),
    );

    configureApiCertificatePinning(_dio);

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = appBaseUri;
          if (!ApiStartupConfig.apiRequestsAllowed) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                message: ApiStartupConfig.blockedRequestMessage,
              ),
            );
          }
          // Ensure X-API-Key is always present
          if (options.headers['X-API-Key'] == null) {
            options.headers['X-API-Key'] = apiSecretKey;
          }
          // Add token if needed
          if (options.headers['Authorization'] == null) {
            final token = await _getCachedToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log successful responses
          serviceLogs(
            response.requestOptions.path,
            method: response.requestOptions.method,
            request: response.requestOptions.data,
            response: response.data,
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          // Handle token refresh if needed
          if (e.response?.statusCode == 401) {
            // Clear token and redirect to login
            _cachedToken = null;
            await secureStorage.clearSessionData();
            gotoLogin();
            return handler.reject(e);
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<String?> _getCachedToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    final token = await secureStorage.getToken();
    if (token.isNotEmpty) {
      _cachedToken = token;
      return _cachedToken;
    }
    return null;
  }

  Future<Map<String, String>> _getHeader(bool useToken) async {
    final headers = Map<String, String>.from(_baseHeader);
    // Always include the current API key (may be updated from Remote Config)
    headers['X-API-Key'] = apiSecretKey;
    if (useToken) {
      final token = await _getCachedToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> getData(
    String endpoint, {
    bool useToken = true,
    bool showLoading = true,
  }) async {
    _dio.options.headers = await _getHeader(useToken);
    try {
      if (showLoading) {
        unawaited(_alertServices.showLoading());
      }
      final response = await _dio.get(endpoint);
      if (showLoading) unawaited(_alertServices.hideLoading());

      // Check if response.data is null
      if (response.data == null) {
        printContent(
          "===> URL: $endpoint \n===> STATUS: ${response.statusCode} \n===> ERROR: Server returned null response",
        );
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (showLoading) unawaited(_alertServices.hideLoading());
      if (_isStartupConfigBlocked(e)) {
        printContent('API request blocked: startup configuration invalid');
        return null;
      }

      // Better error logging with response data
      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> STATUS: $statusCode \n===> RESPONSE: $responseData \n===> ERROR: $errorMsg \n===> STACK: ${e.stackTrace}",
      );
      logApiErrorToCrashlytics(
        e,
        endpoint: endpoint,
        statusCode: statusCode is String
            ? int.tryParse(statusCode)
            : (statusCode as int?),
      );
      _handleError(e);
      return null;
    }
  }

  Future<dynamic> postData(
    String endpoint,
    dynamic data, {
    bool useToken = true,
    bool showLoading = true,
  }) async {
    _dio.options.headers = await _getHeader(useToken);
    try {
      if (showLoading) {
        unawaited(_alertServices.showLoading());
      }
      final response = await _dio.post(endpoint, data: data);
      if (showLoading) unawaited(_alertServices.hideLoading());

      // Check if response.data is null
      if (response.data == null) {
        printContent(
          "===> URL: $endpoint \n===> REQUEST: $data \n===> STATUS: ${response.statusCode} \n===> ERROR: Server returned null response",
        );
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (showLoading) unawaited(_alertServices.hideLoading());
      if (_isStartupConfigBlocked(e)) {
        printContent('API request blocked: startup configuration invalid');
        return null;
      }

      // Better error logging with response data
      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> REQUEST: $data \n===> STATUS: $statusCode \n===> RESPONSE: $responseData \n===> ERROR: $errorMsg \n===> STACK: ${e.stackTrace}",
      );
      logApiErrorToCrashlytics(
        e,
        endpoint: endpoint,
        requestData: data,
        statusCode: statusCode is String
            ? int.tryParse(statusCode)
            : (statusCode as int?),
      );
      _handleError(e);
      return null;
    }
  }

  Future<dynamic> putData(
    String endpoint,
    dynamic data, {
    bool useToken = true,
    bool showLoading = true,
  }) async {
    _dio.options.headers = await _getHeader(useToken);
    try {
      if (showLoading) {
        unawaited(_alertServices.showLoading());
      }
      final response = await _dio.put(endpoint, data: data);
      if (showLoading) unawaited(_alertServices.hideLoading());

      // Check if response.data is null
      if (response.data == null) {
        printContent(
          "===> URL: $endpoint \n===> REQUEST: $data \n===> STATUS: ${response.statusCode} \n===> ERROR: Server returned null response",
        );
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (showLoading) unawaited(_alertServices.hideLoading());
      if (_isStartupConfigBlocked(e)) {
        printContent('API request blocked: startup configuration invalid');
        return null;
      }

      // Better error logging with response data
      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> REQUEST: $data \n===> STATUS: $statusCode \n===> RESPONSE: $responseData \n===> ERROR: $errorMsg \n===> STACK: ${e.stackTrace}",
      );
      logApiErrorToCrashlytics(
        e,
        endpoint: endpoint,
        requestData: data,
        statusCode: statusCode is String
            ? int.tryParse(statusCode)
            : (statusCode as int?),
      );
      _handleError(e);
      return null;
    }
  }

  Future<dynamic> deleteData(
    String endpoint, {
    bool useToken = true,
    bool showLoading = true,
  }) async {
    _dio.options.headers = await _getHeader(useToken);
    try {
      if (showLoading) {
        unawaited(_alertServices.showLoading());
      }
      final response = await _dio.delete(endpoint);
      if (showLoading) unawaited(_alertServices.hideLoading());

      // Check if response.data is null
      if (response.data == null) {
        printContent(
          "===> URL: $endpoint \n===> STATUS: ${response.statusCode} \n===> ERROR: Server returned null response",
        );
        return null;
      }

      return response.data;
    } on DioException catch (e) {
      if (showLoading) unawaited(_alertServices.hideLoading());
      if (_isStartupConfigBlocked(e)) {
        printContent('API request blocked: startup configuration invalid');
        return null;
      }

      // Better error logging with response data
      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> STATUS: $statusCode \n===> RESPONSE: $responseData \n===> ERROR: $errorMsg \n===> STACK: ${e.stackTrace}",
      );
      logApiErrorToCrashlytics(
        e,
        endpoint: endpoint,
        statusCode: statusCode is String
            ? int.tryParse(statusCode)
            : (statusCode as int?),
      );
      _handleError(e);
      return null;
    }
  }

  Future<dynamic> uploadFile(
    String endpoint,
    Map<String, dynamic> data,
    String fileKey,
    String filePath, {
    bool useToken = true,
  }) async {
    try {
      final headers = await _getHeader(useToken);
      // Remove Content-Type for multipart uploads (Dio will set it automatically)
      headers.remove('Content-Type');

      await _alertServices.showLoading();

      // Verify file exists before creating FormData
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File does not exist: $filePath");
      }

      final formData = FormData.fromMap({...data});
      formData.files.add(
        MapEntry(fileKey, await MultipartFile.fromFile(filePath)),
      );

      // Check if endpoint is a full URL or relative path
      final isFullUrl =
          endpoint.startsWith('http://') || endpoint.startsWith('https://');
      final fullUrl = isFullUrl ? endpoint : '$appBaseUri$endpoint';

      printContent(
        "===> Uploading file: $filePath (size: ${await file.length()} bytes)",
      );
      printContent("===> Full URL: $fullUrl");
      printContent(
        "===> Form data keys: ${formData.fields.map((e) => e.key).toList()}",
      );
      printContent("===> File key: $fileKey");
      printContent("===> Headers: $headers");

      // Dio automatically handles full URLs - if endpoint starts with http/https, it ignores baseUrl
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );

      await _alertServices.hideLoading();
      return response.data;
    } on DioException catch (e) {
      unawaited(_alertServices.hideLoading());
      if (_isStartupConfigBlocked(e)) {
        printContent('API request blocked: startup configuration invalid');
        return null;
      }

      String errorMessage = "Unknown error";
      try {
        if (e.response?.data != null) {
          if (e.response!.data is Map) {
            final responseData = e.response!.data as Map;
            errorMessage =
                responseData['message']?.toString() ??
                responseData['responseValue']?['message']?.toString() ??
                responseData['error']?.toString() ??
                e.message ??
                e.response?.statusMessage ??
                e.type.toString();
          } else {
            errorMessage = e.response!.data.toString();
          }
        } else {
          errorMessage =
              e.message ?? e.response?.statusMessage ?? e.type.toString();
        }
      } catch (parseError) {
        errorMessage =
            e.message ?? e.response?.statusMessage ?? e.type.toString();
        printContent("Error parsing error response: $parseError");
      }
      printContent(
        "===> URL: $endpoint \n===> REQUEST: $data \n===> ERROR: $errorMessage \n===> STATUS CODE: ${e.response?.statusCode} \n===> RESPONSE: ${e.response?.data}",
      );
      logApiErrorToCrashlytics(
        e,
        endpoint: endpoint,
        requestData: data,
        statusCode: e.response?.statusCode,
      );
      _handleError(e);
      return null;
    } catch (e) {
      unawaited(_alertServices.hideLoading());
      printContent(
        "===> URL: $endpoint \n===> REQUEST: $data \n===> UNEXPECTED ERROR: ${e.toString()}",
      );
      logErrorToCrashlytics(
        e,
        StackTrace.current,
        context: 'UPLOAD_FILE_ERROR: $endpoint',
      );
      return null;
    }
  }

  /// Check if error is a network/internet connectivity issue
  bool _isNetworkError(DioException e) {
    // Check error type
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      return true;
    }

    // Check error message for network-related keywords
    final errorMessage = (e.message ?? '').toLowerCase();
    final errorString = (e.error?.toString() ?? '').toLowerCase();

    final networkErrorKeywords = [
      'network is unreachable',
      'network unreachable',
      'failed host lookup',
      'socketexception',
      'connection refused',
      'connection reset',
      'no internet',
      'no connection',
      'internet connection',
      'network error',
      'connection error',
      'connection timed out',
      'connection failed',
      'unable to resolve host',
      'host lookup failed',
    ];

    for (final keyword in networkErrorKeywords) {
      if (errorMessage.contains(keyword) || errorString.contains(keyword)) {
        return true;
      }
    }

    // Check if error is a SocketException
    if (e.error is SocketException) {
      return true;
    }

    return false;
  }

  /// Returns true when the request was blocked because startup config is invalid.
  bool _isStartupConfigBlocked(DioException e) {
    return e.type == DioExceptionType.cancel &&
        e.message == ApiStartupConfig.blockedRequestMessage;
  }

  /// HANDLE ERROR
  void _handleError(DioException e) {
    if (_isStartupConfigBlocked(e)) {
      printContent('API request blocked: startup configuration invalid');
      return;
    }

    // Check for network/internet connectivity issues first
    if (_isNetworkError(e)) {
      _alertServices.errorToast(
        _tr('network.noInternet', 'No Internet Connection'),
      );
      return;
    }

    final pinningMessage = certificatePinningErrorMessage(e);
    if (pinningMessage != null) {
      printContent('Certificate pinning failure: $pinningMessage');
      _alertServices.errorToast(certificatePinningFailureMessage);
      return;
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      _alertServices.errorToast(
        _tr('network.receiveTimeout', 'Request timed out'),
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      switch (statusCode) {
        case 400:
          _alertServices.errorToast(
            responseData?['responseValue']?['message'] ??
                _tr('network.badRequest', 'Bad Request'),
          );
          break;
        case 401:
          _alertServices.errorToast(
            responseData?['responseValue']?['message'] ??
                _tr('network.unauthorized', 'Unauthorized'),
          );
          gotoLogin();
          break;
        case 403:
          _alertServices.errorToast(
            _tr('network.forbidden', 'Access Forbidden'),
          );
          break;
        case 404:
          _alertServices.errorToast(
            responseData?['responseValue']?['message'] ??
                _tr('network.notFound', 'Resource Not Found'),
          );
          break;
        case 500:
          _alertServices.errorToast(
            _tr('network.serverFailure', 'Internal Server Error'),
          );
          break;
        default:
          _alertServices.errorToast(
            '${_tr('network.serverError', 'Server Error')}: $statusCode',
          );
      }
    } else if (e.type == DioExceptionType.cancel) {
      _alertServices.errorToast(_tr('network.cancelled', 'Request Cancelled'));
    } else {
      _alertServices.errorToast(
        '${_tr('network.error', 'Network Error')}: ${e.message}',
      );
    }
  }

  Future<void> gotoLogin() async {
    BuildContext ctx = navigatorKey.currentState!.overlay!.context;
    await secureStorage.clearSessionData();
    if (ctx.mounted) {
      Navigator.pushNamedAndRemoveUntil(ctx, "login", (r) => false);
    }
  }
}
