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
  /// Prevents duplicate "session expired" toasts / login redirects when many
  /// in-flight requests fail with 401 at once (timeout or backend restart).
  bool _isHandlingUnauthorized = false;
  late final Dio _dio;

  /// Shared singleton used by all *Services to avoid multiple Dio clients.
  static final Connection instance = Connection._internal();

  factory Connection() => instance;

  Connection._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: appBaseUri,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: _baseHeader,
        // Treat 404/400/403 as success so we can read API JSON (e.g. responseType "F", message, deleted account)
        validateStatus: (status) =>
            status != null &&
            (status < 300 || status == 400 || status == 403 || status == 404),
      ),
    );

    configureApiCertificatePinning(_dio);

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
          if (options.headers['X-API-Key'] == null) {
            options.headers['X-API-Key'] = apiSecretKey;
          }
          final useToken = options.extra['useToken'] as bool? ?? true;
          if (!useToken) {
            options.headers.remove('Authorization');
          } else if (options.headers['Authorization'] == null) {
            final token = await _getCachedToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          serviceLogs(
            response.requestOptions.path,
            method: response.requestOptions.method,
            request: response.requestOptions.data,
            response: response.data,
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            final useToken =
                e.requestOptions.extra['useToken'] as bool? ?? true;
            if (useToken) {
              // Fire-and-forget; guard inside dedupes concurrent 401s.
              unawaited(_handleUnauthorized(e));
            }
            return handler.reject(e);
          }
          return handler.next(e);
        },
      ),
    );

    // Retry idempotent GETs once on transient network/timeout failures.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, handler) async {
          final options = e.requestOptions;
          final alreadyRetried = options.extra['retried'] == true;
          final isGet = options.method.toUpperCase() == 'GET';
          final transient = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              _isNetworkError(e);

          if (!alreadyRetried && isGet && transient) {
            options.extra['retried'] = true;
            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(e);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  String _tr(String key, String fallback) {
    final context = navigatorKey.currentState?.overlay?.context;
    return context?.read<LanguageProvider>().tr(key) ?? fallback;
  }

  Future<String?> _getCachedToken() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken;
    }

    final token = await secureStorage.getToken();
    if (token.isNotEmpty) {
      _cachedToken = token;
      // New session available — allow a future unauthorized toast/redirect.
      _isHandlingUnauthorized = false;
      return _cachedToken;
    }
    return null;
  }

  /// Clears the in-memory JWT cache (call on logout / session clear).
  void clearCachedToken() {
    _cachedToken = null;
  }

  Options _requestOptions(bool useToken) {
    return Options(extra: {'useToken': useToken});
  }

  Future<Map<String, String>> _getHeader(bool useToken) async {
    final headers = Map<String, String>.from(_baseHeader);
    headers['X-API-Key'] = apiSecretKey;
    if (useToken) {
      final token = await _getCachedToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  String _safeLogPayload(dynamic data) {
    try {
      return redactSensitive(data).toString();
    } catch (_) {
      return '[redacted]';
    }
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
      final response = await _dio.get(
        endpoint,
        options: _requestOptions(useToken),
      );
      if (showLoading) unawaited(_alertServices.hideLoading());

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

      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> STATUS: $statusCode \n===> RESPONSE: ${_safeLogPayload(responseData)} \n===> ERROR: $errorMsg",
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
      final response = await _dio.post(
        endpoint,
        data: data,
        options: _requestOptions(useToken),
      );
      if (showLoading) unawaited(_alertServices.hideLoading());

      if (response.data == null) {
        printContent(
          "===> URL: $endpoint \n===> REQUEST: ${_safeLogPayload(data)} \n===> STATUS: ${response.statusCode} \n===> ERROR: Server returned null response",
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

      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> REQUEST: ${_safeLogPayload(data)} \n===> STATUS: $statusCode \n===> RESPONSE: ${_safeLogPayload(responseData)} \n===> ERROR: $errorMsg",
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
      final response = await _dio.put(
        endpoint,
        data: data,
        options: _requestOptions(useToken),
      );
      if (showLoading) unawaited(_alertServices.hideLoading());

      if (response.data == null) {
        printContent(
          "===> URL: $endpoint \n===> REQUEST: ${_safeLogPayload(data)} \n===> STATUS: ${response.statusCode} \n===> ERROR: Server returned null response",
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

      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> REQUEST: ${_safeLogPayload(data)} \n===> STATUS: $statusCode \n===> RESPONSE: ${_safeLogPayload(responseData)} \n===> ERROR: $errorMsg",
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
      final response = await _dio.delete(
        endpoint,
        options: _requestOptions(useToken),
      );
      if (showLoading) unawaited(_alertServices.hideLoading());

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

      final errorMsg = e.message ?? "Unknown error";
      final responseData = e.response?.data ?? "No response data";
      final statusCode = e.response?.statusCode ?? "No status code";

      printContent(
        "===> URL: $endpoint \n===> STATUS: $statusCode \n===> RESPONSE: ${_safeLogPayload(responseData)} \n===> ERROR: $errorMsg",
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
      headers.remove('Content-Type');

      await _alertServices.showLoading();

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File does not exist: $filePath");
      }

      final formData = FormData.fromMap({...data});
      formData.files.add(
        MapEntry(fileKey, await MultipartFile.fromFile(filePath)),
      );

      final isFullUrl =
          endpoint.startsWith('http://') || endpoint.startsWith('https://');
      final fullUrl = isFullUrl ? endpoint : '$appBaseUri$endpoint';

      printContent(
        "===> Uploading file size: ${await file.length()} bytes",
      );
      printContent("===> Full URL: $fullUrl");
      printContent(
        "===> Form data keys: ${formData.fields.map((e) => e.key).toList()}",
      );
      printContent("===> File key: $fileKey");
      printContent("===> Headers: ${redactHeaders(headers)}");

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: headers,
          extra: {'useToken': useToken},
          sendTimeout: const Duration(seconds: 60),
        ),
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
        "===> URL: $endpoint \n===> REQUEST: ${_safeLogPayload(data)} \n===> ERROR: $errorMessage \n===> STATUS CODE: ${e.response?.statusCode}",
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
        "===> URL: $endpoint \n===> REQUEST: ${_safeLogPayload(data)} \n===> UNEXPECTED ERROR: ${e.toString()}",
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
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return true;
    }

    final errorMessage = (e.message ?? '').toLowerCase();
    final errorString = (e.error?.toString() ?? '').toLowerCase();

    const networkErrorKeywords = [
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

    if (e.error is SocketException) {
      return true;
    }

    return false;
  }

  bool _isStartupConfigBlocked(DioException e) {
    return e.type == DioExceptionType.cancel &&
        e.message == ApiStartupConfig.blockedRequestMessage;
  }

  void _handleError(DioException e) {
    // Already logging out from a 401 — skip further toasts from in-flight requests.
    if (_isHandlingUnauthorized) return;

    if (_isStartupConfigBlocked(e)) {
      printContent('API request blocked: startup configuration invalid');
      return;
    }

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
          final useToken =
              e.requestOptions.extra['useToken'] as bool? ?? true;
          if (useToken) {
            // Interceptor may already be handling this; guard prevents duplicates.
            unawaited(_handleUnauthorized(e));
          } else {
            _alertServices.errorToast(
              responseData?['responseValue']?['message'] ??
                  _tr('network.unauthorized', 'Unauthorized'),
            );
          }
          break;
        case 403:
          _alertServices.errorToast(
            responseData?['responseValue']?['message'] ??
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

  /// Shows one session-expired toast and navigates to login at most once
  /// while concurrent 401 responses are still arriving.
  Future<void> _handleUnauthorized(DioException e) async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    final responseData = e.response?.data;
    String? message;
    if (responseData is Map) {
      message = responseData['responseValue']?['message']?.toString();
    }

    _alertServices.errorToast(
      (message != null && message.trim().isNotEmpty)
          ? message
          : _tr('network.unauthorized', 'Unauthorized'),
    );

    clearCachedToken();
    await secureStorage.clearSessionData();

    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    final ctx = overlay.context;
    if (ctx.mounted) {
      Navigator.pushNamedAndRemoveUntil(ctx, "login", (r) => false);
    }
  }

  Future<void> gotoLogin() async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;
    clearCachedToken();
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      await secureStorage.clearSessionData();
      return;
    }
    final ctx = overlay.context;
    await secureStorage.clearSessionData();
    if (ctx.mounted) {
      Navigator.pushNamedAndRemoveUntil(ctx, "login", (r) => false);
    }
  }
}
