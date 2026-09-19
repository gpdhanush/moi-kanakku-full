import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/firebase_remote.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/wave_bottom.dart';
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
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  12,
                  AppSpacing.page,
                  120,
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/maintainence/under-constructure.png',
                      width: double.infinity,
                      height: 270,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      languageProvider.tr('maintenance.title'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        height: 1.02,
                      ),
                    ),
                    Text(
                      languageProvider.tr('maintenance.subtitle'),
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle.copyWith(
                        color: primary,
                        fontSize: 36,
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
                        fontSize: 15,
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
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: _MaintenanceFooter(
                  primary: primary,
                  versionLabel:
                      '${languageProvider.tr('common.appVersion')}: $appVersion',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceFooter extends StatelessWidget {
  final Color primary;
  final String versionLabel;

  const _MaintenanceFooter({required this.primary, required this.versionLabel});

  @override
  Widget build(BuildContext context) {
    final footerColor = primary.withValues(alpha: 0.12);
    return SizedBox(
      width: double.infinity,
      height: 210,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Container(color: footerColor.withValues(alpha: 0.42)),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: WaveBottom(
              color: footerColor,
              height: 76,
              style: WaveCurveStyle.gentle,
            ),
          ),
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: WaveBottom(
              color: primary.withValues(alpha: 0.045),
              height: 64,
              style: WaveCurveStyle.deep,
            ),
          ),
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Text(
              versionLabel,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 58, 16, 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Thanks for your patience!',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontFamily: 'BonheurRoyale',
                    fontSize: 34,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 148,
                  height: 4,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(Icons.favorite, color: primary, size: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
