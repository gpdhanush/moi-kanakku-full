import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _userServices = UserServices();
  final _alerts = AlertServices();
  bool _showPassword = true;
  bool _showConfirmPassword = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final response = await _userServices.setPassword({
        'password': _passwordController.text.trim(),
      });
      if (!mounted) return;
      if (response != null && response['responseType'] == 'S') {
        _alerts.successToast('Password created successfully.');
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      } else {
        _alerts.errorToast(
          response?['responseValue']?['message'] ??
              'Unable to create your password. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _alerts.errorToast('Unable to create your password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validatePassword(String? value, LanguageProvider languageProvider) {
    final key = PasswordValidator.validateSecure(
      value,
      requiredKey: 'auth.newPasswordRequired',
    );
    return key == null ? null : languageProvider.tr(key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: MoiFlowAppHeader(
          title: 'Create Password',
          accent: theme.colorScheme.primary,
          onBack: () => Navigator.pushNamedAndRemoveUntil(
            context,
            'login',
            (route) => false,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your Google account is connected.',
                    textAlign: TextAlign.center,
                    style: AppTypography.authSubtitle.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormWidget(
                    title: languageProvider.tr('auth.newPassword'),
                    controller: _passwordController,
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    obscureText: _showPassword,
                    obscuringCharacter: '●',
                    required: true,
                    maxLength: 32,
                    suffixIconTrue: true,
                    suffixIcon: _showPassword
                        ? HugeIcons.strokeRoundedView
                        : HugeIcons.strokeRoundedViewOffSlash,
                    suffixIconOnPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                    validator: (value) =>
                        _validatePassword(value, languageProvider),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormWidget(
                    title: languageProvider.tr('auth.confirmPassword'),
                    controller: _confirmController,
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    obscureText: _showConfirmPassword,
                    obscuringCharacter: '●',
                    required: true,
                    maxLength: 32,
                    textInputAction: TextInputAction.done,
                    suffixIconTrue: true,
                    suffixIcon: _showConfirmPassword
                        ? HugeIcons.strokeRoundedView
                        : HugeIcons.strokeRoundedViewOffSlash,
                    suffixIconOnPressed: () {
                      setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      );
                    },
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return languageProvider.tr('auth.passwordsDoNotMatch');
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _savePassword(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    title: 'Create Password',
                    showIcon: false,
                    onPressed: _isSaving ? () {} : _savePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
