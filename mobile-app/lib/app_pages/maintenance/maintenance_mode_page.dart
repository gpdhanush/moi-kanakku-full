import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/firebase_remote.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class MaintenanceModePage extends StatefulWidget {
  const MaintenanceModePage({super.key});

  @override
  State<MaintenanceModePage> createState() => _MaintenanceModePageState();
}

class _MaintenanceModePageState extends State<MaintenanceModePage> {
  bool _isChecking = false;

  Future<void> _tryAgain() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    try {
      final config = await getRuntimeConfig();
      if (!mounted) return;
      if (config?.maintenanceMode != true) {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          'splash',
          (route) => false,
        );
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.read<LanguageProvider>().tr('maintenance.stillActive'),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: colors.background,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    12,
                    AppSpacing.page,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/maintainence/under-constructure.png',
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 50),
                      Text(
                        languageProvider.tr('maintenance.title'),
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      Text(
                        languageProvider.tr('maintenance.subtitle'),
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle.copyWith(
                          color: primary,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        languageProvider.tr('maintenance.description'),
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: colors.textSecondary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _isChecking ? null : _tryAgain,
                          icon: _isChecking
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : HugeIcon(
                                  icon: HugeIcons.strokeRoundedRefresh,
                                  color: colorScheme.onPrimary,
                                  size: 20,
                                  strokeWidth: 1.9,
                                ),
                          label: Text(
                            _isChecking
                                ? languageProvider.tr('common.checking')
                                : languageProvider.tr('common.tryAgain'),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: primary.withValues(
                              alpha: 0.5,
                            ),
                            disabledForegroundColor: colorScheme.onPrimary,
                            textStyle: AppTypography.label.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Text(
                      'Thanks for your patience!',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                        fontFamily: 'BonheurRoyale',
                        fontSize: 30,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      '${languageProvider.tr('common.appVersion')}: $appVersion',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
