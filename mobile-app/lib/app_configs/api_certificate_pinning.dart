import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:moi/app_configs/api_endpoint_allowlist.dart';

/// User-visible message when a pinned production API host fails verification.
const String certificatePinningFailureMessage =
    'Secure connection verification failed. The server certificate does not match '
    'the expected security profile. Please update the app or try again later.';

/// SHA-256 SPKI (Subject Public Key Info) pins for production API hosts.
///
/// ## Certificate rotation
/// Before renewing a TLS certificate, generate the pin for the **new** certificate
/// and add it here while keeping the current pin. Deploy the app update, renew the
/// certificate on the server, then remove the old pin after all clients have updated.
///
/// Generate a pin with:
/// ```bash
/// echo | openssl s_client -servername HOST -connect HOST:443 2>/dev/null \
///   | openssl x509 -pubkey -noout \
///   | openssl pkey -pubin -outform der \
///   | openssl dgst -sha256 -binary \
///   | openssl enc -base64
/// ```
///
/// Multiple pins per host are supported so old and new certificates can overlap
/// during rotation.
const Map<String, Set<String>> apiCertificatePins = {
  'moi-api.floatwalktiruppur.in': {
    'sFRLMLlp/cJS7YS6qm5GwEiGg55Ieq6mSB6cxqiY+f8=',
  },
};

/// Whether [host] is a production API domain that requires certificate pinning.
bool isPinnedApiHost(String host) {
  return allowedApiHosts.contains(host);
}

/// Computes the base64-encoded SHA-256 hash of the certificate SPKI bytes.
String computeSpkiSha256Pin(X509Certificate certificate) {
  final spkiBytes = extractSubjectPublicKeyInfoBytes(certificate.der);
  final digest = sha256.convert(spkiBytes);
  return base64.encode(digest.bytes);
}

/// Locates the SubjectPublicKeyInfo SEQUENCE inside an X.509 certificate DER blob.
@visibleForTesting
Uint8List extractSubjectPublicKeyInfoBytes(Uint8List certificateDer) {
  final certificate = ASN1Parser(certificateDer).nextObject() as ASN1Sequence;
  final tbsCertificate = certificate.elements[0] as ASN1Sequence;

  for (final element in tbsCertificate.elements) {
    if (element is! ASN1Sequence || element.elements.length != 2) {
      continue;
    }
    if (element.elements[1] is ASN1BitString) {
      return Uint8List.fromList(element.encodedBytes);
    }
  }

  throw const FormatException(
    'Unable to locate SubjectPublicKeyInfo in certificate',
  );
}

/// Validates the leaf certificate for Dio's [IOHttpClientAdapter.validateCertificate].
///
/// Normal platform TLS validation still runs first; this callback adds SPKI pinning
/// for production API hosts only. Non-production hosts are not pinned.
bool validateApiCertificatePin(
  X509Certificate? certificate,
  String host,
  int port,
) {
  if (!isPinnedApiHost(host)) {
    return true;
  }

  if (certificate == null) {
    return false;
  }

  final effectivePort = port == 0 ? 443 : port;
  if (effectivePort != 443) {
    return false;
  }

  final allowedPins = apiCertificatePins[host];
  if (allowedPins == null || allowedPins.isEmpty) {
    return false;
  }

  try {
    final observedPin = computeSpkiSha256Pin(certificate);
    return allowedPins.contains(observedPin);
  } on FormatException {
    return false;
  }
}

/// Describes a pinning failure for logs and [DioException] messages.
String describeCertificatePinningFailure(String host) {
  return 'Certificate pinning validation failed for production API host "$host". '
      'The server leaf certificate public key does not match any configured pin.';
}
