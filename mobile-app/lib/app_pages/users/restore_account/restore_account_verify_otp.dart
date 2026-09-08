import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class RestoreAccountVerifyOtp extends StatefulWidget {
  final String email;
  const RestoreAccountVerifyOtp({super.key, required this.email});

  @override
  State<RestoreAccountVerifyOtp> createState() =>
      _RestoreAccountVerifyOtpState();
}

class _RestoreAccountVerifyOtpState extends State<RestoreAccountVerifyOtp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otpCtrl = TextEditingController();
  final AlertServices alertServices = AlertServices();
  final UserServices userServices = UserServices();

  Timer? countdownTimer;
  int _start = 120;
  bool enableResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    otpCtrl.dispose();
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
                            const SizedBox(height: 18),
                            // Title
                            Text(
                              languageProvider.tr('auth.verifyOtpTitle'),
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
                            // Subtitle with email
                            Text(
                              '${languageProvider.tr('auth.otpSentToLabel')}: ${maskEmail(widget.email)}',
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

                // Account Restore Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restore_outlined,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          languageProvider.tr('auth.restoreInfo'),
                          style: TextStyle(
                            fontSize: 14,

                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // OTP Input Field
                TextFormWidget(
                  title: languageProvider.tr('auth.otp'),
                  prefixIcon: Icons.lock_outlined,
                  required: true,
                  controller: otpCtrl,
                  maxLength: 6,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    if (value.length == 6) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'\d')),
                  ],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return languageProvider.tr('auth.otpRequired');
                    }
                    if (value.length < 6) {
                      return languageProvider.tr('auth.otpSixDigits');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Resend OTP Timer or Link
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: !enableResend
                      ? Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            children: [
                              TextSpan(
                                text: languageProvider.tr('auth.resendIn'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,

                                  color: Colors.grey.shade700,
                                ),
                              ),
                              TextSpan(
                                text: timerText,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,

                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(
                            children: [
                              TextSpan(
                                text: languageProvider.tr(
                                  'auth.didNotReceiveOtp',
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,

                                  color: Colors.grey.shade700,
                                ),
                              ),
                              TextSpan(
                                text: languageProvider.tr('auth.resendCode'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,

                                  color: colorScheme.primary,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = resentOtp,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Verify and Restore Button
                AppButton(
                  title: languageProvider.tr('auth.verifyAndRestore'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      verifyOTPAndRestore();
                    }
                  },
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
      ),
    );
  }

  // Starts the countdown timer
  void startTimer() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (_start > 0) {
        setState(() {
          _start--;
        });
      } else {
        setState(() {
          enableResend = true;
        });
        countdownTimer?.cancel();
      }
    });
  }

  // Formats the timer text
  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // Verifies the OTP and restores the account
  Future<void> verifyOTPAndRestore() async {
    FocusScope.of(context).unfocus();
    alertServices.showLoading();

    // Step 1: Verify OTP
    var verifyParams = {
      "type": "restore",
      "email": widget.email.toLowerCase(),
      "otp": otpCtrl.text,
    };

    try {
      var verifyResponse = await userServices.verifyRestoreOtp(verifyParams);

      if (verifyResponse != null && verifyResponse['responseType'] == "S") {
        // Step 2: If OTP is verified, restore the account
        var restoreParams = {"email": widget.email.toLowerCase()};

        var restoreResponse = await userServices.restoreAccount(restoreParams);
        alertServices.hideLoading();

        if (restoreResponse != null && restoreResponse['responseType'] == "S") {
          String msg =
              restoreResponse['responseValue']['message']?.toString() ??
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).tr('auth.accountRestored');
          alertServices.successToast(msg);
          if (!mounted) return;
          // Navigate to login page
          Navigator.pushNamedAndRemoveUntil(context, "login", (r) => false);
        } else {
          String msg =
              restoreResponse?['responseValue']?['message']?.toString() ??
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).tr('auth.restoreFailed');
          alertServices.errorToast(msg);
        }
      } else {
        alertServices.hideLoading();
        String msg =
            verifyResponse?['responseValue']?['message']?.toString() ??
            Provider.of<LanguageProvider>(
              context,
              listen: false,
            ).tr('auth.invalidOtp');
        alertServices.errorToast(msg);
      }
    } catch (error) {
      alertServices.hideLoading();
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('common.tryAgain'),
      );
    }
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

  // Resends the OTP
  Future<void> resentOtp() async {
    alertServices.showLoading();
    otpCtrl.clear();
    var params = {"type": "restore", "email": widget.email.toLowerCase()};
    try {
      var response = await userServices.sendRestoreOtp(params);
      alertServices.hideLoading();
      if (response != null && response['responseType'] == "S") {
        alertServices.successToast(
          response['responseValue']['message']?.toString() ??
              Provider.of<LanguageProvider>(
                context,
                listen: false,
              ).tr('auth.otpResent'),
        );
        _start = 120;
        enableResend = false;
        startTimer();
      } else {
        String msg =
            response?['responseValue']?['message']?.toString() ??
            Provider.of<LanguageProvider>(
              context,
              listen: false,
            ).tr('auth.otpSendFailed');
        alertServices.errorToast(msg);
      }
    } catch (error) {
      alertServices.hideLoading();
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('common.tryAgain'),
      );
    }
  }
}
