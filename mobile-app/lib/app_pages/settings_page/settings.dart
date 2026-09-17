import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final AlertServices alertServices = AlertServices();
  final SecureStorageService secureStorage = SecureStorageService();
  bool _switchValue = false;

  @override
  void initState() {
    super.initState();
    checkBio();
  }

  Future<void> checkBio() async {
    final value = await secureStorage.get(AppVariables.appLock) ?? false;
    if (mounted) {
      setState(() => _switchValue = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        final languageLabel =
            LanguageProvider.supportedLanguages[languageProvider
                .currentLanguage] ??
            languageProvider.currentLanguage;
        final voiceCode = languageProvider.voiceLanguageCode;
        final voiceLabel = languageProvider.tr(
          'voiceLanguages.${voiceCode.substring(0, 2)}',
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _SettingsAppHeader(
            title: languageProvider.tr('settings.title').toUpperCase(),
            onBack: () => Navigator.pop(context),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.tr('settings.subtitle'),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Security
                _SectionHeader(
                  primary: primary,
                  icon: HugeIcons.strokeRoundedSecurityCheck,
                  title: languageProvider.tr('settings.security'),
                  hint: languageProvider.tr('settings.securityHint'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: HugeIcons.strokeRoundedFingerPrint,
                      iconBg: const Color(0xffECFDF3),
                      iconColor: AppColors.moiReceived,
                      title: languageProvider.tr('settings.appLock'),
                      subtitle: languageProvider.tr('settings.appLockHint'),
                      trailing: Switch.adaptive(
                        value: _switchValue,
                        activeTrackColor: primary.withValues(alpha: 0.45),
                        activeThumbColor: primary,
                        onChanged: (value) async {
                          if (await _authenticateUser()) {
                            if (!mounted) return;
                            setState(() => _switchValue = value);
                            await secureStorage.save(
                              AppVariables.appLock,
                              value,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Appearance
                _SectionHeader(
                  primary: primary,
                  icon: HugeIcons.strokeRoundedPaintBoard,
                  title: languageProvider.tr('settings.theme'),
                  hint: languageProvider.tr('settings.appearanceHint'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: HugeIcons.strokeRoundedLanguageCircle,
                      iconBg: const Color(0xffECFDF5),
                      iconColor: const Color(0xff059669),
                      title: languageProvider.tr('settings.language'),
                      subtitle: languageProvider.tr('settings.languageHint'),
                      trailingLabel: languageLabel,
                      onTap: () => _showLanguagePicker(languageProvider),
                    ),
                    _SettingsRow(
                      icon: HugeIcons.strokeRoundedMic01,
                      iconBg: const Color(0xffEEF2FF),
                      iconColor: const Color(0xff4F46E5),
                      title: languageProvider.tr('settings.voiceLanguage'),
                      subtitle:
                          languageProvider.tr('settings.voiceLanguageHint'),
                      trailingLabel: voiceLabel,
                      onTap: () => _showVoiceLanguagePicker(languageProvider),
                    ),
                    _SettingsRow(
                      icon: HugeIcons.strokeRoundedPaintBrush04,
                      iconBg: const Color(0xffF3E8FF),
                      iconColor: const Color(0xff7C3AED),
                      title: languageProvider.tr('settings.accentColor'),
                      subtitle: languageProvider.tr('settings.themeHint'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: themeProvider.seedColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xffE4E4E7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            color: Color(0xffA1A1AA),
                            size: 16,
                            strokeWidth: 1.9,
                          ),
                        ],
                      ),
                      onTap: () => _showAccentColorSheet(themeProvider),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // About
                _SectionHeader(
                  primary: primary,
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  title: languageProvider.tr('settings.aboutApp'),
                  hint: languageProvider.tr('settings.aboutHint'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      icon: HugeIcons.strokeRoundedSmartPhone01,
                      iconBg: const Color(0xffEFF6FF),
                      iconColor: primary,
                      title: languageProvider.tr('settings.appName'),
                      subtitle: appName.toUpperCase(),
                      trailingLabel: null,
                      showChevron: false,
                    ),
                    _SettingsRow(
                      icon: HugeIcons.strokeRoundedInformationCircle,
                      iconBg: const Color(0xffF0F9FF),
                      iconColor: const Color(0xff0284C7),
                      title: languageProvider.tr('settings.appVersion'),
                      subtitle: languageProvider.tr('settings.aboutHint'),
                      trailingLabel: appVersion,
                      showChevron: false,
                      showDivider: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _authenticateUser() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      final LocalAuthentication auth = LocalAuthentication();
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported =
          canCheckBiometrics || await auth.isDeviceSupported();

      if (isDeviceSupported) {
        final List<BiometricType> availableBiometrics =
            await auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty &&
            (availableBiometrics.contains(BiometricType.strong) ||
                availableBiometrics.contains(BiometricType.face))) {
          return await auth.authenticate(
            localizedReason: languageProvider.tr('settings.biometricReason'),
            biometricOnly: true,
            sensitiveTransaction: true,
            persistAcrossBackgrounding: false,
          );
        } else {
          alertServices.errorToast(
            languageProvider.tr('settings.biometricsEmpty'),
          );
        }
      } else {
        alertServices.errorToast(
          languageProvider.tr('settings.deviceNotSupported'),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'no_fragment_activity') {
        alertServices.errorToast(
          languageProvider.tr('settings.authenticationUnavailable'),
        );
      } else {
        alertServices.errorToast(
          '${languageProvider.tr('settings.authenticationFailed')}: ${e.message}',
        );
      }
    } catch (_) {
      alertServices.errorToast(languageProvider.tr('settings.unexpectedError'));
    }
    return false;
  }

  Future<void> _showLanguagePicker(LanguageProvider languageProvider) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PickerSheet(
          title: languageProvider.tr('settings.selectLanguage'),
          options: languageProvider.languageCodes
              .map(
                (code) => (
                  value: code,
                  label: LanguageProvider.supportedLanguages[code]!,
                ),
              )
              .toList(),
          selectedValue: languageProvider.currentLanguage,
        );
      },
    );
    if (selected != null) {
      await languageProvider.setLanguage(selected);
    }
  }

  Future<void> _showVoiceLanguagePicker(
    LanguageProvider languageProvider,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _PickerSheet(
          title: languageProvider.tr('settings.voiceLanguage'),
          options: languageProvider.voiceLanguageCodes
              .map(
                (code) => (
                  value: code,
                  label: languageProvider.tr(
                    'voiceLanguages.${code.substring(0, 2)}',
                  ),
                ),
              )
              .toList(),
          selectedValue: languageProvider.voiceLanguageCode,
        );
      },
    );
    if (selected != null) {
      await languageProvider.setVoiceLanguage(selected);
    }
  }

  Future<void> _showAccentColorSheet(ThemeProvider themeProvider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final primary = Theme.of(sheetContext).colorScheme.primary;
        final colors = ThemeProvider.availableColors;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xffE4E4E7)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffE4E4E7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.read<LanguageProvider>().tr('settings.accentColor'),
                  style: AppTypography.sectionTitle.copyWith(
                    color: primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    final color = colors[index];
                    final selected = themeProvider.seedColor == color;
                    return GestureDetector(
                      onTap: () {
                        themeProvider.setSeedColor(color);
                        Navigator.pop(sheetContext);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xff18181B)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Center(
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _SettingsAppHeader({required this.title, required this.onBack});

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
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: Colors.white,
                    size: 22,
                    strokeWidth: 1.9,
                  ),
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

class _SectionHeader extends StatelessWidget {
  final Color primary;
  final List<List<dynamic>> icon;
  final String title;
  final String hint;

  const _SectionHeader({
    required this.primary,
    required this.icon,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        HugeIcon(
          icon: icon,
          color: primary,
          size: 16,
          strokeWidth: 1.9,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.label.copyWith(
            color: primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            hint,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              color: const Color(0xffA1A1AA),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;

  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingLabel,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: icon,
                      color: iconColor,
                      size: 18,
                      strokeWidth: 1.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.label.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (trailing != null)
                    trailing!
                  else ...[
                    if (trailingLabel != null)
                      Text(
                        trailingLabel!,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (showChevron) ...[
                      const SizedBox(width: 4),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Color(0xffA1A1AA),
                        size: 16,
                        strokeWidth: 1.9,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 66,
            endIndent: 14,
            color: Color(0xffF4F4F5),
          ),
      ],
    );
  }
}

typedef _PickerOption = ({String value, String label});

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerOption> options;
  final String selectedValue;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE4E4E7)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xffE4E4E7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final selected = option.value == selectedValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected
                      ? primary.withValues(alpha: 0.08)
                      : const Color(0xffFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => Navigator.pop(context, option.value),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              style: AppTypography.label.copyWith(
                                color: selected
                                    ? primary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selected)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              color: primary,
                              size: 18,
                              strokeWidth: 1.9,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
