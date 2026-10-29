import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_configs/app_logs.dart';

void main() {
  test('redacts password and token fields', () {
    final redacted = redactSensitive({
      'email': 'a@b.com',
      'password': 'secret',
      'token': 'jwt-value',
      'idToken': 'google-token',
      'sessionToken': 'session',
      'nested': {'otp': '123456'},
    }) as Map;

    expect(redacted['email'], 'a@b.com');
    expect(redacted['password'], '***');
    expect(redacted['token'], '***');
    expect(redacted['idToken'], '***');
    expect(redacted['sessionToken'], '***');
    expect((redacted['nested'] as Map)['otp'], '***');
  });

  test('redacts raw JWT-looking strings', () {
    final redacted = redactSensitive(
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.payload.signature',
    );
    expect(redacted, '***');
  });

  test('redacts authorization headers', () {
    final headers = redactHeaders({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer abc',
      'X-API-Key': 'key',
    });
    expect(headers['Content-Type'], 'application/json');
    expect(headers['Authorization'], '***');
    expect(headers['X-API-Key'], '***');
  });
}
