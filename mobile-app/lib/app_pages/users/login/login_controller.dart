import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class LoginController {
  final UserServices userServices = UserServices();
  final SecureStorageService secureStorage = SecureStorageService();
  final AlertServices alertServices = AlertServices();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool showPass = true;

  void togglePasswordVisibility() {
    showPass = !showPass;
  }

  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
  }

  Future<bool> submitLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final params = {
      "email": emailCtrl.text.trim(),
      "password": passCtrl.text.trim(),
    };
    final response = await userServices.login(params);
    if (response != null && response['responseType'] == "S") {
      await _persistAuthSession(response['responseValue']);
      if (!context.mounted) return false;
      Navigator.pushNamedAndRemoveUntil(context, "home", (route) => false);
      return true;
    } else if (response != null &&
        response['responseType'] == "F" &&
        response['responseValue'] != null &&
        response['responseValue']['account_status'] == "DELETED") {
      // Account is deleted - navigate to restore flow
      if (!context.mounted) return false;
      Navigator.pushNamed(
        context,
        "restore_account_send_otp",
        arguments: emailCtrl.text.trim(),
      );
      return false;
    } else if (response != null &&
        response['responseType'] == "F" &&
        response['responseValue'] != null &&
        response['responseValue']['account_status'] == "INACTIVE") {
      if (!context.mounted) return false;
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('auth.accountDeactivated'),
      );
      return false;
    } else if (response != null &&
        response['responseType'] == "F" &&
        response['responseValue'] != null &&
        response['responseValue']['message'] != null) {
      // Show error message to user
      alertServices.errorToast(response['responseValue']['message']);
      return false;
    } else {
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('common.tryAgain'),
      );
      return false;
    }
  }

  Future<bool> submitGoogleLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final account = await googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        alertServices.errorToast(
          'Google sign-in could not produce a valid token.',
        );
        return false;
      }

      final response = await userServices.googleLogin({'idToken': idToken});
      if (response != null && response['responseType'] == 'S') {
        final userData = response['responseValue'];
        if (userData == null) {
          alertServices.errorToast('Unable to complete Google sign-in.');
          return false;
        }

        await _persistAuthSession(userData);
        if (!context.mounted) return false;
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
        return true;
      }

      final message =
          response?['responseValue']?['message'] ??
          'Google sign-in failed. Please try again.';
      alertServices.errorToast(message);
      return false;
    } catch (error) {
      debugPrint('Google login error: $error');
      alertServices.errorToast('Google sign-in failed. Please try again.');
      return false;
    }
  }

  Future<void> _persistAuthSession(Map<String, dynamic> authData) async {
    final token = authData['token']?.toString();
    final user = authData['user'];
    if (token != null && token.isNotEmpty) {
      await Future.wait([
        secureStorage.save(AppVariables.userInformation, user ?? authData),
        secureStorage.save(AppVariables.isLogin, true),
        secureStorage.saveToken(token),
      ]);
      unawaited(
        PushNotificationService.instance.syncTokenForCurrentUser(force: true),
      );
      return;
    }

    await Future.wait([
      secureStorage.save(AppVariables.userInformation, user ?? authData),
      secureStorage.save(AppVariables.isLogin, true),
    ]);
  }

  String? validateEmail(
    String? value,
    LanguageProvider languageProvider, {
    bool forceValidate = true,
  }) {
    return EmailValidator.validateEmailOnInteraction(
      value,
      languageProvider: languageProvider,
      forceValidate: forceValidate,
    );
  }

  /// Login only requires a non-empty password; length rules belong on signup/reset.
  String? validatePassword(String? value, LanguageProvider languageProvider) {
    if (value == null || value.trim().isEmpty) {
      return languageProvider.tr('auth.passwordRequired');
    }
    return null;
  }
}
