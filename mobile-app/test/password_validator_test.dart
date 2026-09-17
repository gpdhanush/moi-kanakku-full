import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_utils/app_global/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    test('rejects empty', () {
      expect(
        PasswordValidator.validateSecure('', requiredKey: 'required'),
        'required',
      );
    });

    test('rejects short password', () {
      expect(
        PasswordValidator.validateSecure('Ab1!', requiredKey: 'required'),
        'auth.passwordMinLength',
      );
    });

    test('accepts secure password', () {
      expect(
        PasswordValidator.validateSecure(
          'Secure1!',
          requiredKey: 'required',
        ),
        isNull,
      );
    });
  });
}
