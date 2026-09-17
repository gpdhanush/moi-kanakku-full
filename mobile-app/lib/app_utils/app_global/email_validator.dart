import 'package:check_disposable_email/check_disposable_email.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';

/// Email validation utility class that provides comprehensive email validation
/// including format validation and disposable email detection.
class EmailValidator {
  /// Validates an email address with comprehensive checks:
  /// 1. Empty check
  /// 2. Format validation (RFC 5322 compliant)
  /// 3. Disposable email domain check
  ///
  /// Returns null if email is valid, otherwise returns a localized error message.
  static String? validateEmail(
    String? value, {
    LanguageProvider? languageProvider,
  }) {
    String msg(String key, String fallback) {
      final translated = languageProvider?.tr(key);
      if (translated == null || translated.isEmpty || translated == key) {
        return fallback;
      }
      return translated;
    }

    if (value == null || value.trim().isEmpty) {
      return msg('auth.emailRequired', 'Email is required');
    }

    final email = value.trim().toLowerCase();
    final validationResult = Disposable.instance.validateEmail(email);

    if (!validationResult.isFormatValid) {
      return msg('auth.emailInvalid', 'Enter a valid email address');
    }

    if (validationResult.isDisposable) {
      return msg(
        'auth.emailDisposable',
        'Temporary email addresses are not allowed. Please use a valid email.',
      );
    }

    return null;
  }

  /// Soft login-field check: avoid harsh format errors while the user is still typing.
  static String? validateEmailOnInteraction(
    String? value, {
    LanguageProvider? languageProvider,
    required bool forceValidate,
  }) {
    if (value == null || value.trim().isEmpty) {
      return forceValidate
          ? validateEmail(value, languageProvider: languageProvider)
          : null;
    }

    final email = value.trim();
    final looksComplete =
        email.contains('@') &&
        email.contains('.') &&
        email.indexOf('@') < email.lastIndexOf('.') &&
        email.split('@').last.contains('.');

    if (!forceValidate && !looksComplete) {
      return null;
    }

    return validateEmail(value, languageProvider: languageProvider);
  }

  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return false;
    }
    return Disposable.instance.hasValidEmail(email.trim().toLowerCase());
  }

  static EmailValidationResult getValidationResult(String? email) {
    if (email == null || email.trim().isEmpty) {
      return EmailValidationResult.invalidFormat(
        'Email address cannot be null',
      );
    }
    return Disposable.instance.validateEmail(email.trim().toLowerCase());
  }
}
