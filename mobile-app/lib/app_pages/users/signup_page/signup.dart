import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/users/models/login_model.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/device_info_service.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SignUpRequestModel requestModel = SignUpRequestModel();
  final AlertServices alertServices = AlertServices();
  final UserServices userServices = UserServices();
  final SecureStorageService secureStorage = SecureStorageService();

  bool showPass = true;
  bool _isLoading = false;

  late final AnimationController _entrance;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    pageTitleLogs('SIGNUP PAGE');
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fadeIn = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _formKey.currentState!.save();
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await submitForm();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final media = MediaQuery.of(context);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final heroHeight = (media.size.height * (keyboardOpen ? 0.18 : 0.34))
        .clamp(keyboardOpen ? 120.0 : 200.0, keyboardOpen ? 160.0 : 300.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            AuthImageHero(
              height: heroHeight,
              imageAsset: AppImages.signupHeroImage,
              enableSnow: false,
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      media.viewInsets.bottom > 0
                          ? AppSpacing.md
                          : AppSpacing.xl,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            languageProvider.tr('auth.createAccountTitle'),
                            textAlign: TextAlign.center,
                            style: AppTypography.authTitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            languageProvider.tr('auth.createAccountSubtitle'),
                            textAlign: TextAlign.center,
                            style: AppTypography.authSubtitle,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextFormWidget(
                            prefixIcon: Icons.account_circle_outlined,
                            title: languageProvider.tr('auth.fullName'),
                            required: true,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 20,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z]+|\s'),
                              ),
                            ],
                            onSaved: (value) {
                              requestModel.name = value.toString().trim();
                            },
                            validator: (value) {
                              if (value.toString().isEmpty) {
                                return languageProvider.tr(
                                  'auth.fullNameRequired',
                                );
                              }
                              if (value.toString().length < 3) {
                                return languageProvider.tr('auth.nameMinLength');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormWidget(
                            title: languageProvider.tr('login.email'),
                            prefixIcon: Icons.email_outlined,
                            required: true,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            onSaved: (value) {
                              requestModel.email = value.toString();
                            },
                            validator: (value) {
                              return EmailValidator.validateEmail(
                                value,
                                languageProvider: languageProvider,
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormWidget(
                                  title: languageProvider.tr('profile.mobile'),
                                  prefixIcon: Icons.phone_outlined,
                                  required: true,
                                  maxLength: 10,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onSaved: (value) {
                                    requestModel.mobile = value.toString();
                                  },
                                  validator: (value) {
                                    return PhoneValidator.validatePhone(
                                      value,
                                      required: true,
                                      languageProvider: languageProvider,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextFormWidget(
                                  title: languageProvider.tr('profile.city'),
                                  prefixIcon: Icons.location_city_outlined,
                                  required: true,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  onSaved: (value) {
                                    requestModel.city =
                                        value.toString().trim();
                                  },
                                  validator: (value) {
                                    if (value.toString().trim().isEmpty) {
                                      return languageProvider.tr(
                                        'auth.cityRequired',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormWidget(
                            title: languageProvider.tr('login.password'),
                            prefixIcon: Icons.lock_outlined,
                            required: true,
                            maxLines: 1,
                            maxLength: 16,
                            obscuringCharacter: '●',
                            textInputAction: TextInputAction.done,
                            obscureText: showPass,
                            suffixIconTrue: true,
                            suffixIcon: showPass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            suffixIconOnPressed: () {
                              setState(() {
                                showPass = !showPass;
                              });
                            },
                            onSaved: (value) {
                              final password = value.toString();
                              requestModel.password = password;
                              requestModel.confirmPassword = password;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
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
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _SignupPrimaryButton(
                            title: languageProvider.tr('common.save'),
                            isLoading: _isLoading,
                            onPressed: _onSubmit,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _LoginLinkRow(
                            prefix: languageProvider.tr(
                              'auth.alreadyHaveAccount',
                            ),
                            action: languageProvider.tr('auth.backToLogin'),
                            enabled: !_isLoading,
                            color: primary,
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              'login',
                            ),
                          ),
                          SizedBox(height: media.padding.bottom + 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> submitForm() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final device = await DeviceService.getDeviceInfo();
      requestModel.device_id = device.device_id;
      requestModel.device_name = device.device_name;
      requestModel.brand = device.brand;
      requestModel.model = device.model;
      requestModel.manufacturer = device.manufacturer;
      requestModel.android_version = device.android_version;
      requestModel.ram_size = device.ram_size;
      if (fcmToken != null) {
        await secureStorage.saveNotificationToken(fcmToken);
        requestModel.fcm_token = fcmToken;
      } else {
        requestModel.fcm_token = '';
      }
    } catch (e) {
      printContent('Error getting FCM token: $e');
      requestModel.fcm_token = '';
    }
    printDirect(requestModel.toJson().toString());
    final response = await userServices.signup(
      jsonEncode(requestModel.toJson()),
    );
    printContent(response.toString());
    if (response != null && response['responseType'] == 'S') {
      alertServices.successToast(
        response['responseValue']['message'].toString(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
    }
  }
}

class _SignupPrimaryButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SignupPrimaryButton({
    required this.title,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: isLoading ? primary.withValues(alpha: 0.72) : primary,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      key: const ValueKey('label'),
                      title,
                      style: AppTypography.label.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginLinkRow extends StatelessWidget {
  final String prefix;
  final String action;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _LoginLinkRow({
    required this.prefix,
    required this.action,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$prefix ',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              action,
              style: AppTypography.label.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: color,
                decorationThickness: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
