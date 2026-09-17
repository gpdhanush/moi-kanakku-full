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

class _MaintenanceModePageState extends State<MaintenanceModePage>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryAgain() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final config = await getFirebaseRemoteConfig(forceRefresh: true);

      if (!mounted) return;

      if (config?.maintenanceMode != true) {
        await Navigator.pushNamedAndRemoveUntil(
          context,
          'splash',
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LanguageProvider>().tr('maintenance.stillActive'),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentAmber.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: const Color(0xffE4E4E7)),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.12),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.accentAmberSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedConstruction,
                              size: 22,
                              color: AppColors.accentAmber,
                              strokeWidth: 1.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        languageProvider.tr('maintenance.title'),
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        languageProvider.tr('maintenance.subtitle'),
                        textAlign: TextAlign.center,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        languageProvider.tr('maintenance.description'),
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xffE4E4E7)),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: HugeIcons.strokeRoundedClock01,
                              text: languageProvider.tr(
                                'maintenance.availableSoon',
                              ),
                              accent: AppColors.accentAmber,
                              soft: AppColors.accentAmberSoft,
                            ),
                            const SizedBox(height: 10),
                            _InfoRow(
                              icon: HugeIcons.strokeRoundedCloud,
                              text: languageProvider.tr(
                                'maintenance.checkStatus',
                              ),
                              accent: primary,
                              soft: AppColors.primarySoft,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _isChecking ? null : _tryAgain,
                          icon: _isChecking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const HugeIcon(
                                  icon: HugeIcons.strokeRoundedRefresh,
                                  color: Colors.white,
                                  size: 18,
                                  strokeWidth: 1.9,
                                ),
                          label: Text(
                            _isChecking
                                ? languageProvider.tr('common.checking')
                                : languageProvider.tr('common.tryAgain'),
                            style: AppTypography.label.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.7),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: AppColors.primary.withValues(
                              alpha: 0.26,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${languageProvider.tr('common.appVersion')}: $appVersion',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String text;
  final Color accent;
  final Color soft;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.accent,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.14)),
            ),
            alignment: Alignment.center,
            child: HugeIcon(
              icon: icon,
              size: 18,
              color: accent,
              strokeWidth: 1.8,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
