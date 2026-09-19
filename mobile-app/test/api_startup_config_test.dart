import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_configs/api_startup_config.dart';

void main() {
  tearDown(() {
    ApiStartupConfig.reset();
  });

  test('blocks empty base URL', () {
    final result = ApiStartupConfig.validate(baseUrl: '');
    expect(result.isValid, isFalse);
    expect(result.issue, ApiStartupConfigIssue.missingBaseUrl);
  });

  test('accepts valid https URL', () {
    final result = ApiStartupConfig.validate(
      baseUrl: 'https://moi-api.floatwalktiruppur.in',
    );
    expect(result.isValid, isTrue);
  });

  test('applyStartupValidation gates requests', () {
    final invalid = ApiStartupConfig.applyStartupValidation(baseUrl: '');
    expect(invalid.isValid, isFalse);
    expect(ApiStartupConfig.apiRequestsAllowed, isFalse);

    final valid = ApiStartupConfig.applyStartupValidation(
      baseUrl: 'https://moi-api.floatwalktiruppur.in',
    );
    expect(valid.isValid, isTrue);
    expect(ApiStartupConfig.apiRequestsAllowed, isTrue);
  });
}
