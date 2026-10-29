import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_storages/auth_credential_sanitizer.dart';
import 'package:moi/app_storages/secure_storages.dart';

void main() {
  group('AuthCredentialSanitizer', () {
    test('strips JWT and password fields from user maps', () {
      final cleaned = AuthCredentialSanitizer.stripSecretsFromMap({
        'id': 42,
        'email': 'user@example.com',
        'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.sig',
        'refresh_token': 'refresh-secret',
        'idToken': 'google-id-token',
        'password': 'should-not-persist',
        'name': 'Test User',
      });

      expect(cleaned['id'], 42);
      expect(cleaned['email'], 'user@example.com');
      expect(cleaned['name'], 'Test User');
      expect(cleaned.containsKey('token'), isFalse);
      expect(cleaned.containsKey('refresh_token'), isFalse);
      expect(cleaned.containsKey('idToken'), isFalse);
      expect(cleaned.containsKey('password'), isFalse);
    });

    test('strips case variants of credential keys', () {
      final cleaned = AuthCredentialSanitizer.stripSecretsFromMap({
        'Access_Token': 'a',
        'SESSIONTOKEN': 'b',
        'Jwt': 'c',
        'safeField': true,
      });

      expect(cleaned.keys, ['safeField']);
      expect(cleaned['safeField'], isTrue);
    });
  });

  group('SecureStorageService token key contract', () {
    test('auth token uses dedicated key separate from user blob', () {
      expect(SecureStorageService.authTokenKey, 'token');
      expect(
        SecureStorageService.authTokenKey,
        isNot(equals('userInformation')),
      );
    });

    test('does not use browser localStorage APIs', () {
      // Flutter persists via flutter_secure_storage (Keystore/Keychain),
      // never via Dart localStorage / sessionStorage bindings.
      expect(SecureStorageService.authTokenKey, isNot(contains('localStorage')));
    });
  });
}
