import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class VerifyForgotOtp extends StatefulWidget {
  final String email;
  const VerifyForgotOtp({super.key, required this.email});

  @override
  State<VerifyForgotOtp> createState() => _VerifyForgotOtpState();
}

class _VerifyForgotOtpState extends State<VerifyForgotOtp> {
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
                              languageProvider.tr('auth.verifyEmailOtpTitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,

                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Email Masking
                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: languageProvider.tr('auth.otpSentTo'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,

                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                  TextSpan(
                                    text: maskEmail(widget.email),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  fontFamily: 'amountFont',
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
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    countdownTimer?.cancel();
                                    resentOtp();
                                  },
                                style: TextStyle(
                                  fontSize: 14,

                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                // Verify Button
                AppButton(
                  title: languageProvider.tr('auth.verify'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      verifyOTP();
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

  // Verifies the OTP
  Future<void> verifyOTP() async {
    FocusScope.of(context).unfocus();
    alertServices.showLoading();
    var params = {
      "type": "forgot",
      "email": widget.email.toLowerCase(),
      "otp": otpCtrl.text,
    };
    try {
      var response = await userServices.verifyOTP(params);
      alertServices.hideLoading();
      if (response != null && response['responseType'] == "S") {
        String msg = response['responseValue']['message'].toString();
        alertServices.successToast(msg);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          "reset_password",
          arguments: widget.email.toLowerCase(),
          (r) => false,
        );
      }
    } catch (error) {
      alertServices.hideLoading();
      // Handle error
    }
  }

  // Masks the email for display
  String maskEmail(String email) {
    var nameUser = email.split("@");
    int length = nameUser[0].length;
    var emailCharacter = email.replaceRange(2, length, "x" * (length - 2));
    return emailCharacter.toLowerCase();
  }

  // Resends the OTP
  Future<void> resentOtp() async {
    alertServices.showLoading();
    otpCtrl.clear();
    var params = {"type": "forgot", "email": widget.email.toLowerCase()};
    try {
      var response = await userServices.sentOTP(params);
      alertServices.hideLoading();
      if (response != null && response['responseType'] == "S") {
        alertServices.successToast(response['responseValue']['message']);
        _start = 120;
        enableResend = false;
        startTimer();
      }
    } catch (error) {
      alertServices.hideLoading();
      // Handle error
    }
  }
}
