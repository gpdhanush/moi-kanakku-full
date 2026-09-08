import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class ResetPassword extends StatefulWidget {
  final String email;
  const ResetPassword({super.key, required this.email});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  String confirmPass = "";
  UserServices userServices = UserServices();
  AlertServices alertServices = AlertServices();

  bool showPass = true;
  bool showCPass = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Header Section with Logo and Title
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pattern - geometric shapes
                      Positioned(
                        top: -15,
                        right: -15,
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Transform.rotate(
                          angle: -0.3,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: -10,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 15),
                            // App Logo with container
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                AppImages.appLogoImage,
                                height: 45,
                                width: 45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Title
                            Text(
                              languageProvider.tr('auth.resetTitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,

                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Subtitle
                            Text(
                              languageProvider.tr('auth.resetSubtitle'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.normal,

                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // New Password Input
                TextFormWidget(
                  title: languageProvider.tr('auth.newPassword'),
                  prefixIcon: Icons.lock_outlined,
                  obscureText: showPass,
                  obscuringCharacter: "●",
                  maxLength: 16,
                  suffixIconTrue: true,
                  suffixIcon: showPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  suffixIconOnPressed: () {
                    setState(() {
                      showPass = !showPass;
                    });
                  },
                  required: true,
                  validator: (value) {
                    confirmPass = value.toString();
                    if (value.toString().isEmpty) {
                      return languageProvider.tr('auth.newPasswordRequired');
                    }
                    if (value.toString().length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    }
                    return null;
                  },
                  onSaved: (value) {},
                ),
                const SizedBox(height: 12),
                // Confirm Password Input
                TextFormWidget(
                  obscureText: showCPass,
                  title: languageProvider.tr('auth.confirmPassword'),
                  prefixIcon: Icons.lock_outlined,
                  obscuringCharacter: "●",
                  maxLength: 16,
                  textInputAction: TextInputAction.done,
                  required: true,
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return languageProvider.tr('auth.passwordRequired');
                    }
                    if (value.toString().length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    } else if (value.toString() != confirmPass) {
                      return languageProvider.tr('auth.passwordsDoNotMatch');
                    }
                    return null;
                  },
                  suffixIconTrue: true,
                  suffixIcon: showCPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  suffixIconOnPressed: () {
                    setState(() {
                      showCPass = !showCPass;
                    });
                  },
                  onSaved: (value) {},
                ),
                const SizedBox(height: 24),
                // Submit Button
                AppButton(
                  title: languageProvider.tr('auth.changePassword'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      changePassword();
                    }
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    alertServices.showLoading();
    var params = {
      "email": widget.email.toString().toLowerCase(),
      "password": confirmPass.toString(),
    };
    userServices
        .resetUserPasswords(params)
        .then((response) {
          alertServices.hideLoading();
          if (response != null && response['responseType'] == "S") {
            alertServices.successToast(response['responseValue']['message']);
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, "login", (r) => false);
          }
        })
        .catchError((error) {
          alertServices.hideLoading();
        });
  }
}
