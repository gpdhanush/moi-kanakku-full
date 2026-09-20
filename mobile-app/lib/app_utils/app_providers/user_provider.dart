import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';

/// UserProvider manages user-related state including user details, JWT token, and device info.
/// This replaces the global mutable state variables for better state management.
class UserProvider extends ChangeNotifier {
  final SecureStorageService _secureStorage = SecureStorageService();
  final UserServices _userServices = UserServices();

  List<dynamic> _userDetails = [];
  Map<String, dynamic> _deviceInfo = {};
  String? _jwtToken;

  /// Paths that 404'd this session — ignore if server still returns them.
  final Set<String> _rejectedProfileImagePaths = {};

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

  /// Whether [pathOrUrl] was already marked missing (404) this session.
  bool isRejectedProfileImage(String? pathOrUrl) {
    final key = _normalizeProfileImageKey(pathOrUrl);
    if (key == null) return false;
    return _rejectedProfileImagePaths.contains(key);
  }

  /// Clears a stale / deleted profile photo from memory + secure storage.
  /// When [fromMissingFile] is true, also asks the API to null the DB path
  /// so a later sync does not reintroduce a 404 URL.
  Future<void> clearProfileImage({
    bool fromMissingFile = false,
    String? missingUrl,
  }) async {
    if (_userDetails.isEmpty) return;
    final user = Map<String, dynamic>.from(_userDetails[0] as Map);
    final existing = (user['profile_image_url'] ?? user['profile_image'])
        ?.toString();
    final hadImage = existing?.trim().isNotEmpty ?? false;
    if (!hadImage && missingUrl == null) return;

    final rejectKey = _normalizeProfileImageKey(missingUrl ?? existing);
    if (rejectKey != null) {
      _rejectedProfileImagePaths.add(rejectKey);
    }

    final urlToEvict = missingUrl?.trim().isNotEmpty == true
        ? missingUrl!.trim()
        : _resolveFullImageUrl(existing);
    if (urlToEvict != null && urlToEvict.isNotEmpty) {
      try {
        await NetworkImage(urlToEvict).evict();
      } catch (_) {}
    }

    user.remove('profile_image');
    user.remove('profile_image_url');
    _userDetails = [user];
    notifyListeners();
    try {
      await _secureStorage.save(AppVariables.userInformation, user);
    } catch (e) {
      debugPrint('Error clearing profile image from storage: $e');
    }

    if (fromMissingFile) {
      final userId = user['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        try {
          await _userServices.removeProfileImage({'userId': userId});
        } catch (e) {
          debugPrint('Error clearing stale profile image on server: $e');
        }
      }
    }
  }

  String? _normalizeProfileImageKey(String? pathOrUrl) {
    if (pathOrUrl == null) return null;
    var value = pathOrUrl.trim();
    if (value.isEmpty ||
        value.toLowerCase() == 'null' ||
        value.toLowerCase() == 'undefined') {
      return null;
    }
    value = value.replaceFirst(RegExp(r'^https?://[^/]+/'), '');
    value = value.replaceFirst(RegExp(r'^/+'), '');
    return value;
  }

  String? _resolveFullImageUrl(String? pathOrUrl) {
    final key = pathOrUrl?.trim() ?? '';
    if (key.isEmpty) return null;
    if (key.startsWith('http://') || key.startsWith('https://')) return key;

    final normalized = key.replaceFirst(RegExp(r'^/+'), '');
    if (appImageUrl.trim().isNotEmpty) {
      return '$appImageUrl/$normalized';
    }
    if (bootstrapApiBaseUri.trim().endsWith('/apis')) {
      final baseWithoutApis = bootstrapApiBaseUri.trim().replaceFirst(
        RegExp(r'/apis$'),
        '',
      );
      return '$baseWithoutApis/$normalized';
    }
    return '$bootstrapApiBaseUri/$normalized';
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
