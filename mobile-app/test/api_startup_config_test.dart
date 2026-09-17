import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_configs/api_startup_config.dart';

void main() {
  tearDown(() {
    ApiStartupConfig.reset();
  });

  test('blocks empty api key', () {
    final result = ApiStartupConfig.validate(
      baseUrl: 'https://moi-api.floatwalktiruppur.in',
      apiKey: '',
    );
    expect(result.isValid, isFalse);
    expect(result.issue, ApiStartupConfigIssue.missingApiKey);
  });

  test('accepts valid https + key', () {
    final result = ApiStartupConfig.validate(
      baseUrl: 'https://moi-api.floatwalktiruppur.in',
      apiKey: 'test-key',
    );
    expect(result.isValid, isTrue);
  });

  test('applyStartupValidation gates requests', () {
    final invalid = ApiStartupConfig.applyStartupValidation(
      baseUrl: '',
      apiKey: 'x',
    );
    expect(invalid.isValid, isFalse);
    expect(ApiStartupConfig.apiRequestsAllowed, isFalse);

    final valid = ApiStartupConfig.applyStartupValidation(
      baseUrl: 'https://moi-api.floatwalktiruppur.in',
      apiKey: 'test-key',
    );
    expect(valid.isValid, isTrue);
    expect(ApiStartupConfig.apiRequestsAllowed, isTrue);
  });
}
