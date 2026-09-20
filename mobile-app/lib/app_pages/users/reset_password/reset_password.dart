import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

class ResetPassword extends StatefulWidget {
  final String email;
  final String otp;
  const ResetPassword({super.key, required this.email, this.otp = ''});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final UserServices userServices = UserServices();
  final AlertServices alertServices = AlertServices();

  String confirmPass = '';
  bool showPass = true;
  bool showCPass = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final media = MediaQuery.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (isDarkMode ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
              .copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDarkMode
                    ? Brightness.light
                    : Brightness.dark,
                statusBarBrightness: isDarkMode
                    ? Brightness.dark
                    : Brightness.light,
              ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    children: [
                      _buildCreativeHero(media, primary),
                      const SizedBox(height: 28),
                      _buildTitleText(theme, languageProvider),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormWidget(
                          title: languageProvider.tr('auth.newPassword'),
                          prefixIcon: HugeIcons.strokeRoundedLockPassword,
                          obscureText: showPass,
                          obscuringCharacter: '●',
                          maxLength: 16,
                          suffixIconTrue: true,
                          suffixIcon: showPass
                              ? HugeIcons.strokeRoundedView
                              : HugeIcons.strokeRoundedViewOffSlash,
                          suffixIconOnPressed: () {
                            setState(() {
                              showPass = !showPass;
                            });
                          },
                          required: true,
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: (value) {
                            confirmPass = value.toString();
                            final key = PasswordValidator.validateSecure(
                              value,
                              requiredKey: 'auth.newPasswordRequired',
                            );
                            if (key != null) {
                              return languageProvider.tr(key);
                            }
                            return null;
                          },
                          onSaved: (value) {},
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormWidget(
                          obscureText: showCPass,
                          title: languageProvider.tr('auth.confirmPassword'),
                          prefixIcon: HugeIcons.strokeRoundedLockPassword,
                          obscuringCharacter: '●',
                          maxLength: 16,
                          textInputAction: TextInputAction.done,
                          required: true,
                          autovalidateMode: AutovalidateMode.disabled,
                          validator: (value) {
                            if (value.toString().isEmpty) {
                              return languageProvider.tr(
                                'auth.passwordRequired',
                              );
                            }
                            if (value.toString().length < 8) {
                              return languageProvider.tr(
                                'auth.passwordMinLength',
                              );
                            } else if (value.toString() != confirmPass) {
                              return languageProvider.tr(
                                'auth.passwordsDoNotMatch',
                              );
                            }
                            return null;
                          },
                          suffixIconTrue: true,
                          suffixIcon: showCPass
                              ? HugeIcons.strokeRoundedView
                              : HugeIcons.strokeRoundedViewOffSlash,
                          suffixIconOnPressed: () {
                            setState(() {
                              showCPass = !showCPass;
                            });
                          },
                          onSaved: (value) {},
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: AppButton(
                          title: languageProvider.tr('auth.changePassword'),
                          showIcon: false,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              changePassword();
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
                    AppColors.deepenAccent(primary, amount: 0.45),
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
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
              onPressed: () => Navigator.pop(context),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 22,
                color: Colors.white,
                strokeWidth: 1.9,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: media.padding.top + 36,
            bottom: 18,
            child: Image.asset(
              AppImages.resetPasswordImage,
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
            languageProvider.tr('auth.resetTitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
              fontFamily: 'Inter',
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            languageProvider.tr('auth.resetSubtitle'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
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
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              'login',
              (r) => false,
            ),
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

  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    if (widget.otp.trim().length != 6) {
      alertServices.errorToast(
        context.read<LanguageProvider>().tr('auth.otpSixDigits'),
      );
      return;
    }
    await alertServices.showLoading();
    final params = {
      'email': widget.email.toString().toLowerCase(),
      'password': confirmPass.toString(),
      'otp': widget.otp.trim(),
      'type': 'forgot',
    };
    try {
      final response = await userServices.resetUserPasswords(
        params,
        showLoading: false,
      );
      if (response != null && response['responseType'] == 'S') {
        alertServices.successToast(response['responseValue']['message']);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, 'login', (r) => false);
      }
    } catch (_) {
      // Loader cleared in finally.
    } finally {
      await alertServices.hideLoading();
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
