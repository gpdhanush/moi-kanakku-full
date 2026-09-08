import 'package:flutter/foundation.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_storages/secure_storages.dart';

/// UserProvider manages user-related state including user details, JWT token, and device info.
/// This replaces the global mutable state variables for better state management.
class UserProvider extends ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();

  List<dynamic> _userDetails = [];
  Map<String, dynamic> _deviceInfo = {};
  String? _jwtToken;

  /// Get current user details
  List<dynamic> get userDetails => _userDetails;

  /// Get current device info
  Map<String, dynamic> get deviceInfo => _deviceInfo;

  /// Get current JWT token
  String? get jwtToken => _jwtToken;

  /// Check if user is logged in (has user details)
  bool get isLoggedIn => _userDetails.isNotEmpty;

  /// Initialize user provider by loading user data from secure storage
  Future<void> initialize() async {
    try {
      final userInfo = await _secureStorage.get(AppVariables.userInformation);
      if (userInfo != null) {
        _userDetails = [userInfo];
      }
      _jwtToken = await _secureStorage.getToken();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing UserProvider: $e');
    }
  }

  /// Set user details
  void setUserDetails(List<dynamic> userDetails) {
    _userDetails = userDetails;
    notifyListeners();
  }

  /// Update user details (single user object)
  void updateUserDetails(dynamic userInfo) {
    if (userInfo != null) {
      _userDetails = [userInfo];
      notifyListeners();
    }
  }

  /// Set device info
  void setDeviceInfo(Map<String, dynamic> deviceInfo) {
    _deviceInfo = deviceInfo;
    notifyListeners();
  }

  /// Update JWT token
  Future<void> updateJwtToken(String? token) async {
    _jwtToken = token;
    if (token != null) {
      await _secureStorage.saveToken(token);
    }
    notifyListeners();
  }

  /// Clear in-memory user state. Storage is cleared separately via [clearSessionData].
  Future<void> clearUserData() async {
    _userDetails = [];
    _deviceInfo = {};
    _jwtToken = null;
    notifyListeners();
  }

  /// Refresh user data from secure storage
  Future<void> refreshUserData() async {
    await initialize();
  }
}
