import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_services/connection.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController oldPassCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmPassCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final AlertServices alertServices = AlertServices();
  final UserServices userServices = UserServices();
  final SecureStorageService secureStorageService = SecureStorageService();

  static final _passwordAllowed = FilteringTextInputFormatter.allow(
    RegExp(r'[a-zA-Z0-9!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]'),
  );

  String userId = "";
  bool showOldPass = true;
  bool showNewPass = true;
  bool showConfirmPass = true;

  @override
  void initState() {
    super.initState();
    passwordCtrl.addListener(_onNewPasswordChanged);
    initUserDetails();
  }

  void _onNewPasswordChanged() {
    if (mounted) setState(() {});
  }

  Future<void> initUserDetails() async {
    var user = await secureStorageService.get(AppVariables.userInformation);
    setState(() {
      userId = user['id'].toString();
    });
  }

  @override
  void dispose() {
    passwordCtrl.removeListener(_onNewPasswordChanged);
    oldPassCtrl.dispose();
    passwordCtrl.dispose();
    confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MoiFlowAppHeader(
        title: languageProvider.tr('auth.changePassword').toTitleCase(),
        accent: primary,
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        _buildPasswordField(
                          title: languageProvider.tr('auth.oldPassword'),
                          controller: oldPassCtrl,
                          obscureText: showOldPass,
                          toggleVisibility: () {
                            setState(() => showOldPass = !showOldPass);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return languageProvider.tr(
                                'auth.oldPasswordRequired',
                              );
                            }
                            if (value.length < 8) {
                              return languageProvider.tr(
                                'auth.passwordMinLength',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildPasswordField(
                          title: languageProvider.tr('auth.newPassword'),
                          controller: passwordCtrl,
                          obscureText: showNewPass,
                          toggleVisibility: () {
                            setState(() => showNewPass = !showNewPass);
                          },
                          validator: (value) {
                            final key = PasswordValidator.validateSecure(
                              value,
                              requiredKey: 'auth.newPasswordRequired',
                            );
                            if (key != null) {
                              return languageProvider.tr(key);
                            }
                            if (value!.trim() == oldPassCtrl.text.trim()) {
                              return languageProvider.tr(
                                'auth.passwordSameAsOld',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildPasswordField(
                          title: languageProvider.tr('auth.confirmPassword'),
                          controller: confirmPassCtrl,
                          obscureText: showConfirmPass,
                          toggleVisibility: () {
                            setState(() => showConfirmPass = !showConfirmPass);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return languageProvider.tr(
                                'auth.confirmPasswordRequired',
                              );
                            }
                            if (value != passwordCtrl.text) {
                              return languageProvider.tr(
                                'auth.passwordsDoNotMatch',
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _PasswordRulesChecklist(
                          password: passwordCtrl.text,
                          languageProvider: languageProvider,
                          primary: primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: AppButton(
                title: languageProvider.tr('auth.changePassword'),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    FocusScope.of(context).unfocus();
                    changePassword();
                  }
                },
                showIcon: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String title,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormWidget(
      title: title,
      controller: controller,
      obscureText: obscureText,
      obscuringCharacter: "●",
      suffixIconTrue: true,
      suffixIcon: obscureText
          ? HugeIcons.strokeRoundedView
          : HugeIcons.strokeRoundedViewOffSlash,
      suffixIconOnPressed: toggleVisibility,
      inputFormatters: [_passwordAllowed],
      maxLength: 32,
      required: true,
      validator: validator,
      onSaved: (value) {},
    );
  }

  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    await alertServices.showLoading();

    var params = {
      "id": userId,
      "password": oldPassCtrl.text.trim(),
      "newPassword": passwordCtrl.text.trim(),
    };

    try {
      var response = await userServices.updateUserPassword(
        params,
        showLoading: false,
      );

      if (response != null && response['responseType'] == "S") {
        alertServices.successToast(
          response['responseValue']['message'] ??
              languageProvider.tr('auth.passwordChanged'),
        );

        oldPassCtrl.clear();
        passwordCtrl.clear();
        confirmPassCtrl.clear();

        try {
          await userServices.logout({"userId": userId});
        } catch (e) {
          debugPrint("Logout API error: $e");
        }

        await secureStorageService.clearSessionData();
        Connection.instance.clearCachedToken();

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
      } else {
        alertServices.errorToast(
          response?['responseValue']?['message'] ??
              response?['message'] ??
              languageProvider.tr('auth.passwordChangeFailed'),
        );
      }
    } catch (error) {
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('common.tryAgain'),
      );
      debugPrint("Error changing password: $error");
    } finally {
      await alertServices.hideLoading();
    }
  }
}

class _PasswordRulesChecklist extends StatelessWidget {
  final String password;
  final LanguageProvider languageProvider;
  final Color primary;

  const _PasswordRulesChecklist({
    required this.password,
    required this.languageProvider,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final rules = <({bool met, String key})>[
      (
        met: PasswordValidator.hasMinLength(password),
        key: 'auth.passwordRuleMin',
      ),
      (
        met: PasswordValidator.hasUpperCase(password),
        key: 'auth.passwordRuleUpper',
      ),
      (
        met: PasswordValidator.hasLowerCase(password),
        key: 'auth.passwordRuleLower',
      ),
      (
        met: PasswordValidator.hasDigit(password),
        key: 'auth.passwordRuleNumber',
      ),
      (
        met: PasswordValidator.hasSpecial(password),
        key: 'auth.passwordRuleSpecial',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  HugeIcon(
                    icon: rule.met
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : HugeIcons.strokeRoundedCircle,
                    size: 16,
                    color: rule.met
                        ? const Color(0xFF2E7D32)
                        : AppColors.textSecondary.withValues(alpha: 0.55),
                    strokeWidth: 1.8,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      languageProvider.tr(rule.key),
                      style: AppTypography.body.copyWith(
                        fontSize: 12,
                        height: 1.25,
                        color: rule.met
                            ? const Color(0xFF2E7D32)
                            : AppColors.textSecondary,
                        fontWeight: rule.met
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
