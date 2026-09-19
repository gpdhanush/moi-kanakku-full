class AppImages {
  static const String appLogoImage = "assets/app-logo/app-logo-light.png";
  static const String appLightLogo = "assets/app-logo/app-logo-light.png";
  static const String appIconLogo = "assets/app-logo/light-logo.png";
  static const String appNotificationLogo =
      "assets/app-logo/notification-logo.png";
  static const String splashLabelDark = "assets/images/splash/label-dark.png";
  static const String splashLightText = "assets/images/splash/light-text.png";
  static const String loginHeroImage = "assets/images/login_hero.png";
  static const String signupHeroImage = "assets/images/signup-image.png";
  static const String forgotPasswordImage = "assets/images/forgot-password.png";
  static const String verifyOtpImage = "assets/images/verify-otp.png";
  static const String resetPasswordImage = "assets/images/reset-password.png";
  static const String profileMen = "assets/images/profile-men.png";
  static const String profileFemale = "assets/images/profile-female.png";
  static const String profileImage = profileMen;
  static const String defaultImage = "assets/images/default-image.png";

  /// Default avatar: female → [profileFemale]; male / null / other → [profileMen].
  static String profileForGender(String? gender) {
    final normalized = gender?.trim().toUpperCase() ?? '';
    if (normalized == 'FEMALE' || normalized == 'F') {
      return profileFemale;
    }
    return profileMen;
  }
}
