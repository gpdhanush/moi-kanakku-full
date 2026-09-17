import 'package:moi/app_utils/app_providers/language_provider.dart';

/// Phone number validation for Indian mobile numbers (10 digits).
class PhoneValidator {
  /// Default country ISO code (India)
  static const String defaultCountryIso = 'IN';

  /// Returns null if phone number is valid, otherwise a localized error message.
  static String? validatePhone(
    String? value, {
    bool required = true,
    String countryIso = defaultCountryIso,
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
      if (required) {
        return msg(
          'profile.enterValidPhoneNumber',
          'Mobile number is required',
        );
      }
      return null;
    }

    final phoneNumber = value.trim();
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return msg('profile.invalidPhone', 'Please enter a valid phone number');
    }

    String nationalNumber = cleanedPhone;
    if (cleanedPhone.startsWith('+91')) {
      nationalNumber = cleanedPhone.substring(3);
    } else if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
      nationalNumber = cleanedPhone.substring(2);
    } else if (cleanedPhone.startsWith('0') && cleanedPhone.length == 11) {
      nationalNumber = cleanedPhone.substring(1);
    }

    if (nationalNumber.length != 10) {
      return msg(
        'profile.invalidPhone',
        'Please enter a valid 10-digit mobile number',
      );
    }

    final firstDigit = nationalNumber[0];
    if (!['6', '7', '8', '9'].contains(firstDigit)) {
      return msg('profile.invalidPhone', 'Please enter a valid phone number');
    }

    final fakePatternError = _checkFakePatterns(
      nationalNumber,
      languageProvider: languageProvider,
    );
    if (fakePatternError != null) {
      return fakePatternError;
    }

    return null;
  }

  static String formatPhone(
    String? phoneNumber, {
    String countryIso = defaultCountryIso,
  }) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return '';
    }

    final cleanedPhone = phoneNumber.trim().replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );

    String nationalNumber = cleanedPhone;
    if (cleanedPhone.startsWith('+91')) {
      nationalNumber = cleanedPhone.substring(3);
    } else if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
      nationalNumber = cleanedPhone.substring(2);
    } else if (cleanedPhone.startsWith('0') && cleanedPhone.length == 11) {
      nationalNumber = cleanedPhone.substring(1);
    }

    if (nationalNumber.length == 10) {
      return nationalNumber;
    }

    return phoneNumber;
  }

  static bool isValidPhone(
    String? phoneNumber, {
    String countryIso = defaultCountryIso,
  }) {
    return validatePhone(phoneNumber, required: true, countryIso: countryIso) ==
        null;
  }

  static String? _checkFakePatterns(
    String phoneNumber, {
    LanguageProvider? languageProvider,
  }) {
    if (phoneNumber.length != 10) {
      return null;
    }

    String invalidMsg() {
      final translated = languageProvider?.tr('profile.invalidPhone');
      if (translated == null ||
          translated.isEmpty ||
          translated == 'profile.invalidPhone') {
        return 'Please enter a valid phone number';
      }
      return translated;
    }

    final firstChar = phoneNumber[0];
    if (phoneNumber.split('').every((char) => char == firstChar)) {
      return invalidMsg();
    }

    bool isSequentialAscending = true;
    for (int i = 0; i < phoneNumber.length - 1; i++) {
      final current = int.tryParse(phoneNumber[i]);
      final next = int.tryParse(phoneNumber[i + 1]);
      if (current == null || next == null) {
        isSequentialAscending = false;
        break;
      }
      if (next != (current + 1) % 10 && !(current == 9 && next == 0)) {
        isSequentialAscending = false;
        break;
      }
    }
    if (isSequentialAscending) {
      return invalidMsg();
    }

    bool isSequentialDescending = true;
    for (int i = 0; i < phoneNumber.length - 1; i++) {
      final current = int.tryParse(phoneNumber[i]);
      final next = int.tryParse(phoneNumber[i + 1]);
      if (current == null || next == null) {
        isSequentialDescending = false;
        break;
      }
      final expectedNext = current == 0 ? 9 : current - 1;
      if (next != expectedNext) {
        isSequentialDescending = false;
        break;
      }
    }
    if (isSequentialDescending) {
      return invalidMsg();
    }

    if (phoneNumber.length >= 4) {
      final firstTwo = phoneNumber.substring(0, 2);
      bool isRepeatingPair = true;
      for (int i = 2; i < phoneNumber.length; i += 2) {
        if (i + 1 < phoneNumber.length) {
          final pair = phoneNumber.substring(i, i + 2);
          if (pair != firstTwo) {
            isRepeatingPair = false;
            break;
          }
        }
      }
      if (isRepeatingPair && phoneNumber.length == 10) {
        return invalidMsg();
      }
    }

    if (phoneNumber.length >= 6) {
      final firstThree = phoneNumber.substring(0, 3);
      bool isRepeatingTriplet = true;
      for (int i = 3; i < phoneNumber.length; i += 3) {
        if (i + 2 < phoneNumber.length) {
          final triplet = phoneNumber.substring(i, i + 3);
          if (triplet != firstThree) {
            isRepeatingTriplet = false;
            break;
          }
        }
      }
      if (isRepeatingTriplet && phoneNumber.length == 10) {
        return invalidMsg();
      }
    }

    final digitCounts = <String, int>{};
    for (final char in phoneNumber.split('')) {
      digitCounts[char] = (digitCounts[char] ?? 0) + 1;
    }
    final maxCount = digitCounts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount >= 7) {
      return invalidMsg();
    }

    if (phoneNumber.length >= 4) {
      final pattern1 = phoneNumber[0];
      final pattern2 = phoneNumber[1];
      bool isAlternating = true;
      for (int i = 0; i < phoneNumber.length; i++) {
        final expected = i.isEven ? pattern1 : pattern2;
        if (phoneNumber[i] != expected) {
          isAlternating = false;
          break;
        }
      }
      if (isAlternating) {
        return invalidMsg();
      }
    }

    return null;
  }
}
