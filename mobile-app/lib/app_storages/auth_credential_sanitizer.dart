/// Strips authentication secrets from maps before they are persisted.
///
/// JWT / session fields must live only under [SecureStorageService.saveToken],
/// never inside the user-profile blob (or logs).
class AuthCredentialSanitizer {
  AuthCredentialSanitizer._();

  /// Keys that must never be written into user / profile JSON storage.
  static const Set<String> secretKeys = {
    'token',
    'accessToken',
    'access_token',
    'refreshToken',
    'refresh_token',
    'idToken',
    'id_token',
    'sessionToken',
    'session_token',
    'authorization',
    'Authorization',
    'jwt',
    'JWT',
    'password',
    'Password',
    'otp',
    'OTP',
  };

  /// Returns a shallow copy of [input] without credential fields.
  static Map<String, dynamic> stripSecretsFromMap(
    Map<String, dynamic> input,
  ) {
    final cleaned = Map<String, dynamic>.from(input);
    for (final key in secretKeys) {
      cleaned.remove(key);
    }
    // Case-insensitive sweep for unexpected variants.
    cleaned.removeWhere((key, _) {
      final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      return normalized == 'token' ||
          normalized == 'accesstoken' ||
          normalized == 'refreshtoken' ||
          normalized == 'idtoken' ||
          normalized == 'sessiontoken' ||
          normalized == 'authorization' ||
          normalized == 'jwt' ||
          normalized == 'password' ||
          normalized == 'otp';
    });
    return cleaned;
  }
}
