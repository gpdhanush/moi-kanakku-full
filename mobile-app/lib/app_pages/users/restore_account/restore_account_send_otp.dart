import 'package:flutter/material.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class RestoreAccountSendOtp extends StatefulWidget {
  final String email;
  const RestoreAccountSendOtp({super.key, required this.email});

  @override
  State<RestoreAccountSendOtp> createState() => _RestoreAccountSendOtpState();
}

class _RestoreAccountSendOtpState extends State<RestoreAccountSendOtp> {
  final AlertServices alertServices = AlertServices();
  final UserServices userServices = UserServices();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Automatically send OTP when this page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendRestoreOtp();
    });
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
                          const SizedBox(height: 18),
                          // Title
                          Text(
                            languageProvider.tr('auth.restoreTitle'),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,

                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            languageProvider.tr('auth.otpSent'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,

                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Deleted Account Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        languageProvider.tr('auth.deletedAccountInfo'),
                        style: TextStyle(
                          fontSize: 14,

                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email Display Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.tr('login.email'),
                            style: TextStyle(
                              fontSize: 12,

                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maskEmail(widget.email),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              AppButton(
                title: isLoading
                    ? languageProvider.tr('common.loading')
                    : languageProvider.tr('common.continue'),
                onPressed: () {
                  if (isLoading) return;
                  Navigator.pushReplacementNamed(
                    context,
                    "restore_account_verify_otp",
                    arguments: widget.email,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Resend OTP Button
              TextButton(
                onPressed: isLoading ? null : sendRestoreOtp,
                child: Text(
                  languageProvider.tr('auth.resendOtp'),
                  style: TextStyle(
                    color: colorScheme.primary,

                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "login");
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      languageProvider.tr('auth.backToLogin'),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Masks the email for display
  String maskEmail(String email) {
    if (!email.contains('@')) return email;
    var nameUser = email.split("@");
    int length = nameUser[0].length;
    if (length <= 2) return email;
    var emailCharacter = email.replaceRange(2, length, "x" * (length - 2));
    return emailCharacter.toLowerCase();
  }

  // Send OTP for account restoration
  Future<void> sendRestoreOtp() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    setState(() {
      isLoading = true;
    });
    alertServices.showLoading();
    var params = {"type": "restore", "email": widget.email.toLowerCase()};
    try {
      var response = await userServices.sendRestoreOtp(params);
      alertServices.hideLoading();
      setState(() {
        isLoading = false;
      });
      if (response != null && response['responseType'] == "S") {
        String msg =
            response['responseValue']['message']?.toString() ??
            languageProvider.tr('auth.otpSentSuccess');
        alertServices.successToast(msg);
      } else {
        String msg =
            response?['responseValue']?['message']?.toString() ??
            languageProvider.tr('auth.otpSendFailed');
        alertServices.errorToast(msg);
      }
    } catch (error) {
      alertServices.hideLoading();
      setState(() {
        isLoading = false;
      });
      alertServices.errorToast(languageProvider.tr('common.tryAgain'));
    }
  }
}
