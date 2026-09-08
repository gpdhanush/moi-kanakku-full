import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/connection.dart';

/// SERVICE CLASS FOR USER SERVICES
class UserServices {
  final Connection connection = Connection();

  Future<dynamic> login(dynamic requestParams) async {
    String url = '$appBaseUri/users/login';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> signup(dynamic requestParams) async {
    String url = '$appBaseUri/users/create';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> sentOTP(dynamic requestParams) async {
    String url = '$appBaseUri/email/sendEmail';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> verifyOTP(dynamic requestParams) async {
    String url = '$appBaseUri/email/verifyOtp';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> resetUserPasswords(dynamic requestParams) async {
    String url = '$appBaseUri/users/reset-password';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> updateUserNotificationToken(
    dynamic requestParams, {
    bool showLoading = true,
  }) async {
    String url = '$appBaseUri/users/update-notification-token';
    return await connection.postData(
      url,
      requestParams,
      useToken: true,
      showLoading: showLoading,
    );
  }

  Future<dynamic> updateUserDetails(dynamic requestParams) async {
    String url = '$appBaseUri/users/update';
    return await connection.postData(url, requestParams, useToken: true);
  }

  Future<dynamic> changeUserPassword(dynamic requestParams) async {
    String url = '$appBaseUri/users/updatePassword';
    return await connection.postData(url, requestParams, useToken: true);
  }

  Future<dynamic> updateUserPassword(dynamic requestParams) async {
    String url = '$appBaseUri/users/update-password';
    return await connection.postData(url, requestParams, useToken: true);
  }

  Future<dynamic> deleteUserAccount(dynamic requestParams) async {
    String url = '$appBaseUri/users/delete';
    return await connection.postData(url, requestParams, useToken: true);
  }

  Future<dynamic> getUserImportantDetails(String userId) async {
    String url = '$appBaseUri/users/details/$userId';
    return await connection.getData(url, useToken: true, showLoading: false);
  }

  Future<dynamic> uploadProfileImage(
    Map<String, dynamic> params,
    String imagePath,
  ) async {
    String url = '$appBaseUri/users/update-profile-picture';
    return await connection.uploadFile(
      url,
      params,
      'profile_image',
      imagePath,
      useToken: true,
    );
  }

  Future<dynamic> logout(dynamic requestParams) async {
    String url = '$appBaseUri/sessions/logout';
    return await connection.postData(
      url,
      requestParams,
      useToken: true,
      showLoading: false,
    );
  }

  Future<dynamic> sendRestoreOtp(dynamic requestParams) async {
    String url = '$appBaseUri/email/sendEmail';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> verifyRestoreOtp(dynamic requestParams) async {
    String url = '$appBaseUri/email/verifyOtp';
    return await connection.postData(url, requestParams, useToken: false);
  }

  Future<dynamic> restoreAccount(dynamic requestParams) async {
    String url = '$appBaseUri/users/restore';
    return await connection.postData(url, requestParams, useToken: false);
  }
}
