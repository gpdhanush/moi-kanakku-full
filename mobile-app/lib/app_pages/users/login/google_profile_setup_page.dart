import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class GoogleProfileSetupPage extends StatefulWidget {
  const GoogleProfileSetupPage({super.key});

  @override
  State<GoogleProfileSetupPage> createState() => _GoogleProfileSetupPageState();
}

class _GoogleProfileSetupPageState extends State<GoogleProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _services = UserServices();
  final _storage = SecureStorageService();
  final _alerts = AlertServices();
  Map<String, dynamic>? _user;
  bool _isSaving = false;
  bool _showPassword = true;
  bool _showConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _storage.get(AppVariables.userInformation);
    if (!mounted || user is! Map) return;
    setState(() {
      _user = Map<String, dynamic>.from(user);
      _nameController.text = _user?['name']?.toString() ?? '';
      _mobileController.text = _user?['mobile']?.toString() ?? '';
      _cityController.text = _user?['city']?.toString() ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate() || _isSaving || _user == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final response = await _services.updateUserDetails({
        'id': _user!['id']?.toString(),
        'name': _nameController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'city': _cityController.text.trim(),
      });

      if (!mounted) return;
      if (response?['responseType'] == 'S') {
        final passwordResponse = await _services.setPassword({
          'password': _passwordController.text.trim(),
        });
        if (passwordResponse?['responseType'] != 'S') {
          _alerts.errorToast(
            passwordResponse?['responseValue']?['message'] ??
                context.read<LanguageProvider>().tr('common.tryAgain'),
          );
          return;
        }
        _user!
          ..['name'] = _nameController.text.trim()
          ..['mobile'] = _mobileController.text.trim()
          ..['city'] = _cityController.text.trim();
        await _storage.save(AppVariables.userInformation, _user);
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      } else {
        _alerts.errorToast(
          response?['responseValue']?['message'] ??
              context.read<LanguageProvider>().tr('common.tryAgain'),
        );
      }
    } catch (_) {
      if (mounted) {
        _alerts.errorToast(
          context.read<LanguageProvider>().tr('common.tryAgain'),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: MoiFlowAppHeader(
        title: language.tr('auth.completeProfileTitle'),
        accent: Theme.of(context).colorScheme.primary,
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
                  language.tr('auth.completeProfileSubtitle'),
                  textAlign: TextAlign.center,
                  style: AppTypography.authSubtitle.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormWidget(
                  title: language.tr('auth.fullName'),
                  controller: _nameController,
                  prefixIcon: HugeIcons.strokeRoundedUser,
                  required: true,
                  validator: (value) {
                    if ((value ?? '').trim().length < 3) {
                      return language.tr('auth.nameMinLength');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormWidget(
                  title: language.tr('profile.mobile'),
                  controller: _mobileController,
                  prefixIcon: HugeIcons.strokeRoundedCall,
                  required: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => PhoneValidator.validatePhone(
                    value,
                    required: true,
                    languageProvider: language,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormWidget(
                  title: language.tr('profile.city'),
                  controller: _cityController,
                  prefixIcon: HugeIcons.strokeRoundedCity01,
                  required: true,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? language.tr('auth.cityRequired')
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormWidget(
                  title: language.tr('auth.newPassword'),
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
                  suffixIconOnPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  onChanged: (_) {
                    if (_confirmPasswordController.text.isNotEmpty) {
                      _formKey.currentState?.validate();
                    }
                  },
                  validator: (value) {
                    final key = PasswordValidator.validateSecure(
                      value,
                      requiredKey: 'auth.newPasswordRequired',
                    );
                    return key == null ? null : language.tr(key);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormWidget(
                  title: language.tr('auth.confirmPassword'),
                  controller: _confirmPasswordController,
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
                  suffixIconOnPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return language.tr('auth.passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  title: language.tr('auth.createAccountPassword'),
                  onPressed: _saveAndContinue,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
