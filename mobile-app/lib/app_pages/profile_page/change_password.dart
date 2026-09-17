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
      appBar: _ChangePasswordHeader(
        title: languageProvider.tr('auth.changePassword').toUpperCase(),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: HugeIcon(icon: HugeIcons.strokeRoundedLockPassword,
                              strokeWidth: 1.8, size: 20, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              languageProvider.tr('auth.passwordSecureHint'),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Column(
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
                          const SizedBox(height: AppSpacing.sm),
                          _PasswordRulesChecklist(
                            password: passwordCtrl.text,
                            languageProvider: languageProvider,
                            primary: primary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildPasswordField(
                            title: languageProvider.tr('auth.confirmPassword'),
                            controller: confirmPassCtrl,
                            obscureText: showConfirmPass,
                            toggleVisibility: () {
                              setState(
                                () => showConfirmPass = !showConfirmPass,
                              );
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
                        ],
                      ),
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
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      FocusScope.of(context).unfocus();
                      changePassword();
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary,
                          Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        languageProvider.tr('auth.changePassword'),
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
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
    alertServices.showLoading();

    var params = {
      "id": userId,
      "password": oldPassCtrl.text.trim(),
      "newPassword": passwordCtrl.text.trim(),
    };

    try {
      var response = await userServices.updateUserPassword(params);
      alertServices.hideLoading();

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
      alertServices.hideLoading();
      alertServices.errorToast(
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).tr('common.tryAgain'),
      );
      debugPrint("Error changing password: $error");
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
                  HugeIcon(icon: rule.met
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : HugeIcons.strokeRoundedCircle, size: 16, color: rule.met
                        ? const Color(0xFF2E7D32)
                        : AppColors.textSecondary.withValues(alpha: 0.55), strokeWidth: 1.8),
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
                        fontWeight:
                            rule.met ? FontWeight.w600 : FontWeight.w500,
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

class _ChangePasswordHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _ChangePasswordHeader({required this.title, required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              Color.lerp(primary, const Color(0xff0A3D8F), 0.35)!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -18,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: 48,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      leadingWidth: 54,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01,
                    strokeWidth: 1.9, size: 22, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.sectionTitle.copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      actions: const [SizedBox(width: 54)],
    );
  }
}
