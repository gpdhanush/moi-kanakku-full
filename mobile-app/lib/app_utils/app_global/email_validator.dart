import 'package:check_disposable_email/check_disposable_email.dart';

/// Email validation utility class that provides comprehensive email validation
/// including format validation and disposable email detection.
class EmailValidator {
  /// Validates an email address with comprehensive checks:
  /// 1. Empty check
  /// 2. Format validation (RFC 5322 compliant)
  /// 3. Disposable email domain check
  ///
  /// Returns null if email is valid, otherwise returns error message in Tamil.
  static String? validateEmail(String? value) {
    // Check if email is empty
    if (value == null || value.trim().isEmpty) {
      return "மின்னஞ்சல் கட்டாயம்!";
    }

    // Trim and normalize email
    final email = value.trim().toLowerCase();

    // Use the disposable email package for comprehensive validation
    final validationResult = Disposable.instance.validateEmail(email);

    // Check if email format is valid
    if (!validationResult.isFormatValid) {
      return "தவறான மின்னஞ்சல் வடிவம்!";
    }

    // Check if email uses a disposable/temporary domain
    if (validationResult.isDisposable) {
      return "தற்காலிக மின்னஞ்சல் முகவரிகள் அனுமதிக்கப்படவில்லை. சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்.";
    }

    // Email is valid
    return null;
  }

  /// Simple boolean check if email is valid and non-disposable
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return false;
    }
    return Disposable.instance.hasValidEmail(email.trim().toLowerCase());
  }

  /// Get detailed validation result for advanced use cases
  static EmailValidationResult getValidationResult(String? email) {
    if (email == null || email.trim().isEmpty) {
      return EmailValidationResult.invalidFormat(
        'Email address cannot be null',
      );
    }
    return Disposable.instance.validateEmail(email.trim().toLowerCase());
  }
}
