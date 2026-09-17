import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_configs/api_endpoint_allowlist.dart';

void main() {
  group('isAllowedApiEndpoint', () {
    test('accepts approved HTTPS host', () {
      expect(
        isAllowedApiEndpoint('https://moi-api.floatwalktiruppur.in'),
        isTrue,
      );
    });

    test('rejects http', () {
      expect(
        isAllowedApiEndpoint('http://moi-api.floatwalktiruppur.in'),
        isFalse,
      );
    });

    test('rejects unknown host', () {
      expect(isAllowedApiEndpoint('https://evil.example.com'), isFalse);
    });

    test('rejects suffix attack host', () {
      expect(
        isAllowedApiEndpoint('https://moi-api.floatwalktiruppur.in.evil.com'),
        isFalse,
      );
    });
  });

  group('isAllowedHttpsImageUrl', () {
    test('accepts https CDN', () {
      expect(isAllowedHttpsImageUrl('https://cdn.example.com/img.png'), isTrue);
    });

    test('rejects http', () {
      expect(isAllowedHttpsImageUrl('http://cdn.example.com/img.png'), isFalse);
    });
  });
}
