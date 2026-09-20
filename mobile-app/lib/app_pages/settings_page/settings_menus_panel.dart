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

/// Settings menus shared by the More tab (and Settings route).
///
/// Grouping:
/// 1. App lock
/// 2. Language, voice, dark mode
/// 3. About app → optional contact / rate / app name / version / logout
class SettingsMenusPanel extends StatefulWidget {
  final VoidCallback? onContactUs;
  final VoidCallback? onRateUs;
  final VoidCallback? onLogout;
  final String? contactSubtitle;
  final String? rateUsSubtitle;
  final String? logoutSubtitle;

  const SettingsMenusPanel({
    super.key,
    this.onContactUs,
    this.onRateUs,
    this.onLogout,
    this.contactSubtitle,
    this.rateUsSubtitle,
    this.logoutSubtitle,
  });

  @override
  State<SettingsMenusPanel> createState() => _SettingsMenusPanelState();
}

class _SettingsMenusPanelState extends State<SettingsMenusPanel> {
  final AlertServices _alertServices = AlertServices();
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _appLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAppLock();
  }

  Future<void> _loadAppLock() async {
    final value = await _secureStorage.get(AppVariables.appLock) ?? false;
    if (mounted) setState(() => _appLockEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

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

        final aboutChildren = <Widget>[
          if (widget.onContactUs != null)
            _MenuRow(
              icon: HugeIcons.strokeRoundedContact,
              title: languageProvider.tr('menu.contactUs'),
              subtitle:
                  widget.contactSubtitle ??
                  languageProvider.tr('settings.contactUs'),
              onTap: widget.onContactUs,
            ),
          if (widget.onRateUs != null)
            _MenuRow(
              icon: HugeIcons.strokeRoundedStar,
              title: languageProvider.tr('menu.rateUs'),
              subtitle:
                  widget.rateUsSubtitle ??
                  languageProvider.tr('settings.rateApp'),
              onTap: widget.onRateUs,
            ),
          // _MenuRow(
          //   icon: HugeIcons.strokeRoundedSmartPhone01,
          //   title: languageProvider.tr('settings.appName'),
          //   subtitle: appName.toUpperCase(),
          //   showChevron: false,
          // ),
          _MenuRow(
            icon: HugeIcons.strokeRoundedInformationCircle,
            title: languageProvider.tr('settings.appVersion'),
            subtitle: languageProvider.tr('settings.aboutHint'),
            trailingLabel: appVersion,
            showChevron: false,
            showDivider: widget.onLogout != null,
          ),
          if (widget.onLogout != null)
            _MenuRow(
              icon: HugeIcons.strokeRoundedLogout01,
              title: languageProvider.tr('menu.logout'),
              subtitle:
                  widget.logoutSubtitle ?? languageProvider.tr('menu.logout'),
              showChevron: false,
              showDivider: false,
              isDestructive: true,
              onTap: widget.onLogout,
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(title: languageProvider.tr('settings.security')),
            const SizedBox(height: AppSpacing.sm),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: HugeIcons.strokeRoundedFingerPrint,
                  title: languageProvider.tr('settings.appLock'),
                  subtitle: languageProvider.tr('settings.appLockHint'),
                  trailing: Switch.adaptive(
                    value: _appLockEnabled,
                    activeTrackColor: primary.withValues(alpha: 0.45),
                    activeThumbColor: primary,
                    onChanged: (value) async {
                      if (await _authenticateUser()) {
                        if (!mounted) return;
                        setState(() => _appLockEnabled = value);
                        await _secureStorage.save(AppVariables.appLock, value);
                      }
                    },
                  ),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(title: languageProvider.tr('settings.preferences')),
            const SizedBox(height: AppSpacing.sm),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: HugeIcons.strokeRoundedLanguageCircle,
                  title: languageProvider.tr('settings.language'),
                  subtitle: languageProvider.tr('settings.languageHint'),
                  trailingLabel: languageLabel,
                  onTap: () => _showLanguagePicker(languageProvider),
                ),
                _MenuRow(
                  icon: HugeIcons.strokeRoundedMic01,
                  title: languageProvider.tr('settings.voiceLanguage'),
                  subtitle: languageProvider.tr('settings.voiceLanguageHint'),
                  trailingLabel: voiceLabel,
                  onTap: () => _showVoiceLanguagePicker(languageProvider),
                ),
                _MenuRow(
                  icon: HugeIcons.strokeRoundedMoon02,
                  title: languageProvider.tr('settings.darkMode'),
                  subtitle: languageProvider.tr('settings.darkModeHint'),
                  trailing: Switch.adaptive(
                    value: themeProvider.isDarkMode,
                    activeTrackColor: primary.withValues(alpha: 0.45),
                    activeThumbColor: primary,
                    onChanged: (value) async {
                      await themeProvider.setDarkMode(value);
                    },
                  ),
                  showDivider: false,
                ),
                // _MenuRow(
                //   icon: HugeIcons.strokeRoundedPaintBrush04,
                //   title: languageProvider.tr('settings.accentColor'),
                //   subtitle: languageProvider.tr('settings.themeHint'),
                //   trailing: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Container(
                //         width: 18,
                //         height: 18,
                //         decoration: BoxDecoration(
                //           color: themeProvider.seedColor,
                //           shape: BoxShape.circle,
                //           border: Border.all(color: colorScheme.outlineVariant),
                //         ),
                //       ),
                //       const SizedBox(width: 6),
                //       HugeIcon(
                //         icon: HugeIcons.strokeRoundedArrowRight01,
                //         strokeWidth: 1.9,
                //         size: 16,
                //         color: colorScheme.onSurfaceVariant,
                //       ),
                //     ],
                //   ),
                //   onTap: () => _showAccentColorSheet(themeProvider),
                //   showDivider: false,
                // ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionLabel(title: languageProvider.tr('settings.aboutApp')),
            const SizedBox(height: AppSpacing.sm),
            _MenuCard(children: aboutChildren),
          ],
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
      final auth = LocalAuthentication();
      final canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported =
          canCheckBiometrics || await auth.isDeviceSupported();

      if (isDeviceSupported) {
        final availableBiometrics = await auth.getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty &&
            (availableBiometrics.contains(BiometricType.strong) ||
                availableBiometrics.contains(BiometricType.face))) {
          return await auth.authenticate(
            localizedReason: languageProvider.tr('settings.biometricReason'),
            biometricOnly: true,
            sensitiveTransaction: true,
            persistAcrossBackgrounding: false,
          );
        }
        _alertServices.errorToast(
          languageProvider.tr('settings.biometricsEmpty'),
        );
      } else {
        _alertServices.errorToast(
          languageProvider.tr('settings.deviceNotSupported'),
        );
      }
    } on PlatformException catch (e) {
      if (e.code.toLowerCase().contains('cancel')) {
        return false;
      }
      if (e.code == 'no_fragment_activity') {
        _alertServices.errorToast(
          languageProvider.tr('settings.authenticationUnavailable'),
        );
      } else {
        _alertServices.errorToast(
          '${languageProvider.tr('settings.authenticationFailed')}: ${e.message}',
        );
      }
    } catch (_) {
      _alertServices.errorToast(
        languageProvider.tr('settings.unexpectedError'),
      );
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

  // Future<void> _showAccentColorSheet(ThemeProvider themeProvider) async {
  //   await showModalBottomSheet<void>(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     builder: (sheetContext) {
  //       final primary = Theme.of(sheetContext).colorScheme.primary;
  //       final colors = ThemeProvider.availableColors;
  //       return Container(
  //         margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
  //         padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(24),
  //           border: Border.all(color: const Color(0xffE4E4E7)),
  //         ),
  //         child: SafeArea(
  //           top: false,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Container(
  //                 width: 40,
  //                 height: 4,
  //                 decoration: BoxDecoration(
  //                   color: const Color(0xffE4E4E7),
  //                   borderRadius: BorderRadius.circular(999),
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               Text(
  //                 context.read<LanguageProvider>().tr('settings.accentColor'),
  //                 style: AppTypography.sectionTitle.copyWith(
  //                   color: primary,
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w700,
  //                 ),
  //               ),
  //               const SizedBox(height: 16),
  //               GridView.builder(
  //                 shrinkWrap: true,
  //                 physics: const NeverScrollableScrollPhysics(),
  //                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //                   crossAxisCount: 6,
  //                   crossAxisSpacing: 10,
  //                   mainAxisSpacing: 10,
  //                 ),
  //                 itemCount: colors.length,
  //                 itemBuilder: (context, index) {
  //                   final color = colors[index];
  //                   final selected = themeProvider.isSeedColor(color);
  //                   return GestureDetector(
  //                     onTap: () {
  //                       themeProvider.setSeedColor(color);
  //                       Navigator.pop(sheetContext);
  //                     },
  //                     child: AnimatedContainer(
  //                       duration: const Duration(milliseconds: 150),
  //                       decoration: BoxDecoration(
  //                         color: color,
  //                         borderRadius: BorderRadius.circular(12),
  //                         border: Border.all(
  //                           color: selected
  //                               ? const Color(0xff18181B)
  //                               : Colors.transparent,
  //                           width: 2,
  //                         ),
  //                       ),
  //                       child: selected
  //                           ? const Center(
  //                               child: HugeIcon(
  //                                 icon: HugeIcons.strokeRoundedTick02,
  //                                 size: 18,
  //                                 color: Colors.white,
  //                                 strokeWidth: 1.8,
  //                               ),
  //                             )
  //                           : null,
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.label.copyWith(
          color: colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;

  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;
  final bool isDestructive;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingLabel,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final iconColor = isDestructive
        ? (isDark ? colorScheme.error : const Color(0xFFEF4444))
        : (isDark ? colorScheme.primary : const Color(0xFF059669));

    final iconBg = isDestructive
        ? (isDark
            ? colorScheme.error.withValues(alpha: 0.1)
            : const Color(0xFFFEE2E2))
        : (isDark
            ? colorScheme.primary.withValues(alpha: 0.1)
            : const Color(0xFFE8F6EB));

    final titleColor = isDestructive
        ? (isDark ? colorScheme.error : const Color(0xFFEF4444))
        : colors.textPrimary;

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
                            color: titleColor,
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
                            color: colors.textSecondary,
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
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (showChevron) ...[
                      const SizedBox(width: 4),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        strokeWidth: 1.9,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 66,
            endIndent: 14,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
    final colors = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
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
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTypography.sectionTitle.copyWith(
                color: colors.textPrimary,
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
                      ? primary.withValues(alpha: 0.14)
                      : colors.surfaceVariant,
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
                                color: selected ? primary : colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selected)
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedTick02,
                              strokeWidth: 1.9,
                              size: 18,
                              color: primary,
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
