import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

import 'login_controller.dart';
import 'package:hugeicons/hugeicons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final LoginController _controller = LoginController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _submitted = false;
  late final AnimationController _entrance;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    pageTitleLogs('LOGIN PAGE');
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _controller.submitLogin(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final media = MediaQuery.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final screenHeight = media.size.height;
    final keyboardOpen = media.viewInsets.bottom > 0;
    final heroHeight = (screenHeight * (keyboardOpen ? 0.18 : 0.32)).clamp(
      keyboardOpen ? 120.0 : 200.0,
      keyboardOpen ? 160.0 : 300.0,
    );
    final fadeOverlap = keyboardOpen ? 36.0 : 72.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: heroHeight + fadeOverlap,
                child: LoginHeroHeader(
                  height: heroHeight + fadeOverlap,
                  headline: keyboardOpen
                      ? null
                      : languageProvider.tr('login.heroHeadline'),
                  support: keyboardOpen
                      ? null
                      : languageProvider.tr('login.heroSupport'),
                ),
              ),
              Column(
                children: [
                  SizedBox(height: heroHeight),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  AppSpacing.page,
                                  fadeOverlap * 0.42,
                                  AppSpacing.page,
                                  AppSpacing.md,
                                ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode: _submitted
                                  ? AutovalidateMode.onUserInteraction
                                  : AutovalidateMode.disabled,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    languageProvider.tr('login.title'),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.authTitle,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    languageProvider.tr('login.subtitle'),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.authSubtitle,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  TextFormWidget(
                                    title: languageProvider.tr('login.email'),
                                    hintText: languageProvider.tr(
                                      'login.emailHint',
                                    ),
                                    required: true,
                                    controller: _controller.emailCtrl,
                                    focusNode: _emailFocus,
                                    prefixIcon: HugeIcons.strokeRoundedMail01,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.deny(
                                        RegExp(r'\s'),
                                      ),
                                    ],
                                    autovalidateMode: _submitted
                                        ? AutovalidateMode.onUserInteraction
                                        : AutovalidateMode.disabled,
                                    validator: (value) =>
                                        _controller.validateEmail(
                                      value,
                                      languageProvider,
                                      forceValidate: _submitted,
                                    ),
                                    onFieldSubmitted: (_) {
                                      _passwordFocus.requestFocus();
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormWidget(
                                    title: languageProvider.tr(
                                      'login.password',
                                    ),
                                    hintText: languageProvider.tr(
                                      'login.passwordHint',
                                    ),
                                    required: true,
                                    controller: _controller.passCtrl,
                                    focusNode: _passwordFocus,
                                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                                    obscureText: _controller.showPass,
                                    obscuringCharacter: '●',
                                    textInputAction: TextInputAction.done,
                                    maxLength: 64,
                                    suffixIconTrue: true,
                                    suffixIcon: _controller.showPass
                                        ? HugeIcons.strokeRoundedView
                                        : HugeIcons.strokeRoundedViewOffSlash,
                                    suffixIconOnPressed: () {
                                      setState(() {
                                        _controller.togglePasswordVisibility();
                                      });
                                    },
                                    autovalidateMode: _submitted
                                        ? AutovalidateMode.onUserInteraction
                                        : AutovalidateMode.disabled,
                                    validator: (value) =>
                                        _controller.validatePassword(
                                      value,
                                      languageProvider,
                                    ),
                                    onFieldSubmitted: (_) => _onLogin(),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => Navigator.pushNamed(
                                                context,
                                                'forgot_password',
                                              ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 10,
                                        ),
                                        minimumSize: const Size(48, 48),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        languageProvider.tr(
                                          'login.forgotPassword',
                                        ),
                                        style: AppTypography.label.copyWith(
                                          color: primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _LoginPrimaryButton(
                                    title: languageProvider.tr(
                                      'login.loginNow',
                                    ),
                                    isLoading: _isLoading,
                                    onPressed: _onLogin,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  _CreateAccountRow(
                                    prefix: languageProvider.tr(
                                      'login.noAccount',
                                    ),
                                    action: languageProvider.tr(
                                      'login.createAccount',
                                    ),
                                    enabled: !_isLoading,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      'signup',
                                    ),
                                  ),
                                  SizedBox(height: media.padding.bottom + 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!keyboardOpen)
                          _LoginWavesPattern(
                            primary: primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _LoginPrimaryButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginPrimaryButton({
    required this.title,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            height: 56,
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
      ),
    );
  }
}

class _CreateAccountRow extends StatelessWidget {
  final String prefix;
  final String action;
  final bool enabled;
  final VoidCallback onTap;

  const _CreateAccountRow({
    required this.prefix,
    required this.action,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

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
        Semantics(
          button: true,
          label: action,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                action,
                style: AppTypography.label.copyWith(
                  color: primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: primary,
                  decorationThickness: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginWavesPattern extends StatelessWidget {
  final Color primary;

  const _LoginWavesPattern({required this.primary});

  @override
  Widget build(BuildContext context) {
    final backWave = Color.lerp(primary, const Color(0xffA8C8F0), 0.55)!;
    final frontWave = primary;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 78,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: WaveBottom(
                color: backWave,
                height: 64,
                opacity: 0.55,
                style: WaveCurveStyle.gentle,
                phase: 0.12,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: WaveBottom(
                color: frontWave,
                height: 46,
                opacity: 0.38,
                style: WaveCurveStyle.soft,
                phase: 0.58,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
