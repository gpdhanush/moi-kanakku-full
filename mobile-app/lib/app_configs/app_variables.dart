import 'package:flutter/material.dart';

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String appBaseUri = "";
String appImageUrl = "";

// API Secret Key for rate limiting and authentication
// This is now loaded from Firebase Remote Config, with a fallback value
// The actual key should be set in Firebase Remote Config for security
String _cachedApiSecretKey = "MY_SON_NAME_IS_RENZO_ROWAN"; // Fallback value

// Getter function to retrieve API secret key
// This allows the key to be updated from Firebase Remote Config
String get apiSecretKey {
  return _cachedApiSecretKey;
}

// Function to update API secret key (called from firebase_remote.dart)
void updateApiSecretKey(String newKey) {
  _cachedApiSecretKey = newKey;
}

const String appName = "Moi Kanakku";
String appVersion = "";
const String appPackageName = "com.renzo.moi";

// Global variables - DEPRECATED: Use UserProvider instead
// Kept for backward compatibility during migration
List<dynamic> userDetails = [];
Map<String, dynamic> deviceInfo = {};
String? jwtToken;
// late String notificationToken;
const String deleteUserAccount =
    "இந்த கணக்கில் உள்ள அனைத்து விவரங்களும் நீக்கப்படும். மீண்டும் பெற இயலாது!\nமீண்டும் ஒரு முறை யோசிக்கவும்.";

// Profile field labels
const String genderLabel = "பாலினம்";
const String dateOfBirthLabel = "பிறந்த தேதி";
const String statusLabel = "நிலை";
const String addressLine1Label = "முதல் முகவரி";
const String addressLine2Label = "இரண்டாவது முகவரி";
const String cityLabel = "நகரம்";
const String stateLabel = "மாநிலம்";
const String countryLabel = "நாடு";
const String postalCodeLabel = "தபால் குறியீடு";
const String deviceInfoLabel = "சாதன நிர்வாணம்";

// Profile section headers
const String personalDetailsHeader = "தனிப்பட்ட தகவல்கள்";
const String addressDetailsHeader = "விலாச தகவல்கள்";
const String deviceDetailsHeader = "சாதന விவரங்கள்";

// Validation messages
const String nameRequired = "முழுப்பெயர் கட்டாயம்!";
const String dateOfBirthRequired = "பிறந்த தேதி கட்டாயம்!";
const String emailRequired = "மின்னஞ்சல் கட்டாயம்!";

class AppVariables {
  static String isLogin = "isUserIsLoggedIn";
  static String userInformation = "userInformation";
  static const String appLock = "appLock";
  static const String isDark = "isDark";
  static const String permissionsGranted = "permissionsGranted";
  static const String permissionsRequested = "permissionsRequested";
}
