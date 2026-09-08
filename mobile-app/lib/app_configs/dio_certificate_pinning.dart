import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:moi/app_configs/api_certificate_pinning.dart';

/// Applies SPKI certificate pinning to [dio] for production API hosts.
///
/// Platform TLS chain validation remains enabled; [validateApiCertificatePin]
/// performs an additional leaf-certificate check after the handshake succeeds.
void configureApiCertificatePinning(Dio dio) {
  if (kIsWeb) {
    return;
  }

  dio.httpClientAdapter = IOHttpClientAdapter(
    validateCertificate: validateApiCertificatePin,
  );
}

/// Returns a descriptive error when [error] represents a pinning failure.
String? certificatePinningErrorMessage(DioException error) {
  if (error.type != DioExceptionType.badCertificate) {
    return null;
  }

  final host = error.requestOptions.uri.host;
  if (!isPinnedApiHost(host)) {
    return null;
  }

  return describeCertificatePinningFailure(host);
}
