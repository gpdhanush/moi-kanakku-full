import 'dart:async';

import 'package:flutter/material.dart';
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
      await Future.wait([
        secureStorage.save(
          AppVariables.userInformation,
          response['responseValue'],
        ),
        secureStorage.save(AppVariables.isLogin, true),
        secureStorage.saveToken(response['responseValue']['token']),
      ]);
      unawaited(PushNotificationService.instance.syncTokenForCurrentUser());
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

  String? validateEmail(String? value) {
    return EmailValidator.validateEmail(value);
  }

  String? validatePassword(String? value, LanguageProvider languageProvider) {
    if (value == null || value.isEmpty) {
      return languageProvider.tr('auth.passwordRequired');
    }
    if (value.length < 8) {
      return languageProvider.tr('auth.passwordMinLength');
    }
    return null;
  }
}
