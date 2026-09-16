/// Helpers for mixed secure password validation.
class PasswordValidator {
  static final RegExp upperCase = RegExp(r'[A-Z]');
  static final RegExp lowerCase = RegExp(r'[a-z]');
  static final RegExp digit = RegExp(r'[0-9]');
  static final RegExp special = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]');

  static bool hasMinLength(String value, {int min = 8}) => value.length >= min;
  static bool hasUpperCase(String value) => upperCase.hasMatch(value);
  static bool hasLowerCase(String value) => lowerCase.hasMatch(value);
  static bool hasDigit(String value) => digit.hasMatch(value);
  static bool hasSpecial(String value) => special.hasMatch(value);

  static bool isSecure(String value, {int min = 8}) {
    return hasMinLength(value, min: min) &&
        hasUpperCase(value) &&
        hasLowerCase(value) &&
        hasDigit(value) &&
        hasSpecial(value);
  }

  /// Returns a translation key for the first failed rule, or null if valid.
  static String? validateSecure(
    String? value, {
    required String requiredKey,
    int min = 8,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredKey;
    if (!hasMinLength(text, min: min)) return 'auth.passwordMinLength';
    if (!hasUpperCase(text)) return 'auth.passwordNeedUpper';
    if (!hasLowerCase(text)) return 'auth.passwordNeedLower';
    if (!hasDigit(text)) return 'auth.passwordNeedNumber';
    if (!hasSpecial(text)) return 'auth.passwordNeedSpecial';
    return null;
  }
}
