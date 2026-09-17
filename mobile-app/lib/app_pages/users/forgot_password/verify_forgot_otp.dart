import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

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
    otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final media = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey.shade50,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCreativeHero(media, primary),
                      const SizedBox(height: 28),
                      _buildTitleText(theme, languageProvider),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormWidget(
                          title: languageProvider.tr('auth.otp'),
                          prefixIcon: HugeIcons.strokeRoundedLockPassword,
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
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: _buildResendBlock(theme, languageProvider, primary),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: AppButton(
                          title: languageProvider.tr('auth.verify'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              verifyOTP();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 50),
                      _buildBackToLogin(theme, languageProvider, primary),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            if (!isKeyboardOpen) _BottomPattern(color: primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCreativeHero(MediaQueryData media, Color primary) {
    final heroHeight = media.size.height * 0.34;

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xff0B1220),
                    Color.lerp(primary, const Color(0xff0A3D8F), 0.45)!,
                    primary,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            top: -36,
            right: -28,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: media.padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.white.withValues(alpha: 0.14),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 18, color: Colors.white, strokeWidth: 1.8),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: media.padding.top + 36,
            bottom: 18,
            child: Image.asset(
              AppImages.verifyOtpImage,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleText(ThemeData theme, LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            languageProvider.tr('auth.verifyEmailOtpTitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            textAlign: TextAlign.center,
            TextSpan(
              children: [
                TextSpan(
                  text: '${languageProvider.tr('auth.otpSentTo')} ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                TextSpan(
                  text: maskEmail(widget.email),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendBlock(
    ThemeData theme,
    LanguageProvider languageProvider,
    Color primary,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withValues(alpha: 0.1),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextSpan(
                    text: timerText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontFamily: 'Inter',
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
                    text: languageProvider.tr('auth.didNotReceiveOtp'),
                    style: theme.textTheme.bodyMedium?.copyWith(
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBackToLogin(
    ThemeData theme,
    LanguageProvider languageProvider,
    Color primary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${languageProvider.tr('auth.rememberPassword')} ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, 'login'),
            child: Text(
              languageProvider.tr('auth.backToLogin'),
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.underline,
                decorationThickness: 1.5,
                decorationColor: primary,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  String get timerText {
    final minutes = _start ~/ 60;
    final seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> verifyOTP() async {
    FocusScope.of(context).unfocus();
    alertServices.showLoading();
    final params = {
      'type': 'forgot',
      'email': widget.email.toLowerCase(),
      'otp': otpCtrl.text,
    };
    try {
      final response = await userServices.verifyOTP(params);
      alertServices.hideLoading();
      if (response != null && response['responseType'] == 'S') {
        final msg = response['responseValue']['message'].toString();
        alertServices.successToast(msg);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          'reset_password',
          arguments: widget.email.toLowerCase(),
          (r) => false,
        );
      }
    } catch (_) {
      alertServices.hideLoading();
    }
  }

  String maskEmail(String email) {
    final nameUser = email.split('@');
    final length = nameUser[0].length;
    final emailCharacter = email.replaceRange(2, length, 'x' * (length - 2));
    return emailCharacter.toLowerCase();
  }

  Future<void> resentOtp() async {
    alertServices.showLoading();
    otpCtrl.clear();
    final params = {'type': 'forgot', 'email': widget.email.toLowerCase()};
    try {
      final response = await userServices.sentOTP(params);
      alertServices.hideLoading();
      if (response != null && response['responseType'] == 'S') {
        alertServices.successToast(response['responseValue']['message']);
        _start = 120;
        enableResend = false;
        startTimer();
      }
    } catch (_) {
      alertServices.hideLoading();
    }
  }
}

class _BottomPattern extends StatelessWidget {
  final Color color;

  const _BottomPattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 72,
        width: double.infinity,
        child: CustomPaint(painter: _AuthBottomPatternPainter(color: color)),
      ),
    );
  }
}

class _AuthBottomPatternPainter extends CustomPainter {
  final Color color;

  _AuthBottomPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final mid = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final dot = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.12, size.height * 1.15), 48, soft);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 1.05), 56, soft);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 1.35), 70, mid);

    const spacing = 18.0;
    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 18; y < size.height - 8; y += spacing) {
        final offset = ((x / spacing).round() + (y / spacing).round()).isEven
            ? 0.0
            : 4.0;
        canvas.drawCircle(Offset(x + offset, y), 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBottomPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
