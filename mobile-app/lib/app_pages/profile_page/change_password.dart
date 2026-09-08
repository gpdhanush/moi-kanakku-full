import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  // Controllers for text fields
  final TextEditingController oldPassCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Services
  final AlertServices alertServices = AlertServices();
  final UserServices userServices = UserServices();
  final SecureStorageService secureStorageService = SecureStorageService();

  // User ID and password visibility flags
  String userId = "";
  bool showOldPass = true;
  bool showNewPass = true;
  bool showConfirmPass = true;

  @override
  void initState() {
    super.initState();
    initUserDetails();
  }

  Future<void> initUserDetails() async {
    var user = await secureStorageService.get(AppVariables.userInformation);
    setState(() {
      userId = user['id'].toString();
    });
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    oldPassCtrl.dispose();
    passwordCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBarWidget(
        title: languageProvider.tr('auth.changePassword'),
        action: const [],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 16),
                // Old password input field
                _buildPasswordField(
                  title: languageProvider.tr('auth.oldPassword'),
                  controller: oldPassCtrl,
                  obscureText: showOldPass,
                  toggleVisibility: () {
                    setState(() {
                      showOldPass = !showOldPass;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return languageProvider.tr('auth.oldPasswordRequired');
                    }
                    if (value.length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // New password input field
                _buildPasswordField(
                  title: languageProvider.tr('auth.newPassword'),
                  controller: passwordCtrl,
                  obscureText: showNewPass,
                  toggleVisibility: () {
                    setState(() {
                      showNewPass = !showNewPass;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return languageProvider.tr('auth.newPasswordRequired');
                    }
                    if (value.length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirm password input field
                _buildPasswordField(
                  title: languageProvider.tr('auth.confirmPassword'),
                  controller: confirmPassCtrl,
                  obscureText: showConfirmPass,
                  toggleVisibility: () {
                    setState(() {
                      showConfirmPass = !showConfirmPass;
                    });
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return languageProvider.tr(
                        'auth.confirmPasswordRequired',
                      );
                    }
                    if (value.length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    }
                    if (value != passwordCtrl.text) {
                      return languageProvider.tr('auth.passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 25),
                // Change password button
                AppButton(
                  title: languageProvider.tr('auth.changePassword'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      FocusScope.of(context).unfocus();
                      changePassword();
                    }
                  },
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to build password input fields
  Widget _buildPasswordField({
    required String title,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormWidget(
      title: title,
      controller: controller,
      obscureText: obscureText,
      obscuringCharacter: "●",
      suffixIconTrue: true,
      suffixIcon: obscureText
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
      suffixIconOnPressed: toggleVisibility,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9!@#$^&*]')),
      ],
      maxLength: 16,
      required: true,
      validator: validator,
      onSaved: (value) {},
    );
  }

  // Method to handle password change
  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    alertServices.showLoading();

    var params = {
      "id": userId,
      "password": oldPassCtrl.text.trim(),
      "newPassword": passwordCtrl.text.trim(),
    };

    try {
      var response = await userServices.updateUserPassword(params);
      alertServices.hideLoading();

      if (response != null && response['responseType'] == "S") {
        alertServices.successToast(
          response['responseValue']['message'] ??
              languageProvider.tr('auth.passwordChanged'),
        );

        // Clear input fields
        oldPassCtrl.clear();
        passwordCtrl.clear();
        confirmPassCtrl.clear();

        // Call logout API to invalidate the session
        try {
          await userServices.logout({"userId": userId});
        } catch (e) {
          debugPrint("Logout API error: $e");
          // Continue with local logout even if API fails
        }

        // Clear local storage
        await secureStorageService.clearSessionData();

        if (!mounted) return;
        // Navigate to login page and clear navigation stack
        Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
      } else {
        alertServices.errorToast(
          response?['responseValue']?['message'] ??
              response?['message'] ??
              languageProvider.tr('auth.passwordChangeFailed'),
        );
      }
    } catch (error) {
      alertServices.hideLoading();
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('common.tryAgain'),
      );
      debugPrint("Error changing password: $error");
    }
  }
}
