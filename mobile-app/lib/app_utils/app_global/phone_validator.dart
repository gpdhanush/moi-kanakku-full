/// Phone number validation utility class that provides comprehensive phone number validation
/// for Indian mobile numbers (10 digits).
class PhoneValidator {
  /// Default country ISO code (India)
  static const String defaultCountryIso = 'IN';

  /// Validates a phone number with comprehensive checks:
  /// 1. Empty check (if required)
  /// 2. Format validation
  /// 3. Length validation (10 digits for India)
  /// 4. Fake pattern detection
  ///
  /// [value] - The phone number string to validate
  /// [required] - Whether the phone number is required (default: true)
  /// [countryIso] - Country ISO code (default: 'IN' for India)
  ///
  /// Returns null if phone number is valid, otherwise returns error message in Tamil.
  static String? validatePhone(
    String? value, {
    bool required = true,
    String countryIso = defaultCountryIso,
  }) {
    // Check if phone number is empty
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return "மொபைல் எண் கட்டாயம்!";
      }
      // If not required and empty, it's valid
      return null;
    }

    // Trim the phone number
    final phoneNumber = value.trim();

    // Remove any spaces, dashes, or other formatting characters
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return "மொபைல் எண் எண்களை மட்டும் கொண்டிருக்க வேண்டும்!";
    }

    // Handle country code (+91) - remove it if present
    String nationalNumber = cleanedPhone;
    if (cleanedPhone.startsWith('+91')) {
      nationalNumber = cleanedPhone.substring(3);
    } else if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
      nationalNumber = cleanedPhone.substring(2);
    } else if (cleanedPhone.startsWith('0') && cleanedPhone.length == 11) {
      // Remove leading zero
      nationalNumber = cleanedPhone.substring(1);
    }

    // Validate length (must be exactly 10 digits for Indian mobile)
    if (nationalNumber.length != 10) {
      return "மொபைல் எண் சரியாக 10 இலக்கங்கள் இருக்க வேண்டும்!";
    }

    // Check: Ensure it's a mobile number (for India, mobile numbers start with 6-9)
    final firstDigit = nationalNumber[0];
    if (!['6', '7', '8', '9'].contains(firstDigit)) {
      return "மொபைல் எண் 6, 7, 8 அல்லது 9 இல் தொடங்க வேண்டும்!";
    }

    // Check for fake/repeated digit patterns
    final fakePatternError = _checkFakePatterns(nationalNumber);
    if (fakePatternError != null) {
      return fakePatternError;
    }

    // Phone number is valid
    return null;
  }

  /// Formats a phone number to a standard format (10 digits)
  /// Returns formatted phone number or original if formatting fails
  static String formatPhone(
    String? phoneNumber, {
    String countryIso = defaultCountryIso,
  }) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return '';
    }

    // Remove formatting characters
    final cleanedPhone = phoneNumber.trim().replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );

    // Handle country code (+91) - remove it if present
    String nationalNumber = cleanedPhone;
    if (cleanedPhone.startsWith('+91')) {
      nationalNumber = cleanedPhone.substring(3);
    } else if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
      nationalNumber = cleanedPhone.substring(2);
    } else if (cleanedPhone.startsWith('0') && cleanedPhone.length == 11) {
      // Remove leading zero
      nationalNumber = cleanedPhone.substring(1);
    }

    // Return 10-digit number
    if (nationalNumber.length == 10) {
      return nationalNumber;
    }

    // Return original if can't format
    return phoneNumber;
  }

  /// Checks if a phone number is valid
  static bool isValidPhone(
    String? phoneNumber, {
    String countryIso = defaultCountryIso,
  }) {
    // Use validatePhone and check if it returns null (valid)
    return validatePhone(phoneNumber, required: true, countryIso: countryIso) ==
        null;
  }

  /// Checks for fake/repeated digit patterns in phone numbers
  /// Returns error message if fake pattern detected, null otherwise
  static String? _checkFakePatterns(String phoneNumber) {
    if (phoneNumber.length != 10) {
      return null; // Only check 10-digit numbers
    }

    // Check 1: All digits are the same (1111111111, 2222222222, etc.)
    final firstChar = phoneNumber[0];
    if (phoneNumber.split('').every((char) => char == firstChar)) {
      return "தவறான மொபைல் எண்! அனைத்து இலக்கங்களும் ஒரே மாதிரியாக இருக்கக்கூடாது.";
    }

    // Check 2: Sequential ascending (1234567890, 2345678901, etc.)
    bool isSequentialAscending = true;
    for (int i = 0; i < phoneNumber.length - 1; i++) {
      final current = int.tryParse(phoneNumber[i]);
      final next = int.tryParse(phoneNumber[i + 1]);
      if (current == null || next == null) {
        isSequentialAscending = false;
        break;
      }
      // Check if next digit is exactly one more than current (handling wrap-around)
      final expectedNext = (current + 1) % 10;
      if (next != expectedNext && (current != 9 || next != 0)) {
        // Special case: 9 followed by 0 is valid sequential
        if (!(current == 9 && next == 0)) {
          isSequentialAscending = false;
          break;
        }
      }
    }
    if (isSequentialAscending) {
      return "தவறான மொபைல் எண்! வரிசை எண்கள் அனுமதிக்கப்படவில்லை.";
    }

    // Check 3: Sequential descending (9876543210, 8765432109, etc.)
    bool isSequentialDescending = true;
    for (int i = 0; i < phoneNumber.length - 1; i++) {
      final current = int.tryParse(phoneNumber[i]);
      final next = int.tryParse(phoneNumber[i + 1]);
      if (current == null || next == null) {
        isSequentialDescending = false;
        break;
      }
      // Check if next digit is exactly one less than current (handling wrap-around)
      final expectedNext = current == 0 ? 9 : current - 1;
      if (next != expectedNext) {
        isSequentialDescending = false;
        break;
      }
    }
    if (isSequentialDescending) {
      return "தவறான மொபைல் எண்! வரிசை எண்கள் அனுமதிக்கப்படவில்லை.";
    }

    // Check 4: Repeating pairs (1212121212, 1231231234, etc.)
    // Check for 2-digit repetition (e.g., 1212121212)
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
        return "தவறான மொபைல் எண்! மீண்டும் மீண்டும் வரும் எண்கள் அனுமதிக்கப்படவில்லை.";
      }
    }

    // Check 5: Repeating triplets (1231231234, 4564564567, etc.)
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
        return "தவறான மொபைல் எண்! மீண்டும் மீண்டும் வரும் எண்கள் அனுமதிக்கப்படவில்லை.";
      }
    }

    // Check 6: Too many repeated digits (at least 7 same digits)
    final digitCounts = <String, int>{};
    for (final char in phoneNumber.split('')) {
      digitCounts[char] = (digitCounts[char] ?? 0) + 1;
    }
    final maxCount = digitCounts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount >= 7) {
      return "தவறான மொபைல் எண்! பல மீண்டும் மீண்டும் வரும் இலக்கங்கள் அனுமதிக்கப்படவில்லை.";
    }

    // Check 7: Alternating pattern (e.g., 1010101010, 1212121212)
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
        return "தவறான மொபைல் எண்! மாறி மாறி வரும் எண்கள் அனுமதிக்கப்படவில்லை.";
      }
    }

    // No fake pattern detected
    return null;
  }
}
