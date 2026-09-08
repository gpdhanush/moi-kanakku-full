import 'package:flutter/material.dart';
import 'package:moi/app_configs/api_startup_config.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/firebase_remote.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class ConfigurationErrorPage extends StatefulWidget {
  const ConfigurationErrorPage({super.key});

  @override
  State<ConfigurationErrorPage> createState() => _ConfigurationErrorPageState();
}

class _ConfigurationErrorPageState extends State<ConfigurationErrorPage>
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
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
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
      await getFirebaseRemoteConfig(forceRefresh: true);

      if (!mounted) return;

      final result = ApiStartupConfig.applyStartupValidation(
        baseUrl: appBaseUri,
        apiKey: apiSecretKey,
      );

      if (!mounted) return;

      if (result.isValid) {
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
            context.read<LanguageProvider>().tr('configuration.stillInvalid'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.error.withValues(alpha: 0.06),
              colorScheme.surface,
              colorScheme.secondaryContainer.withValues(alpha: 0.12),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 36),
                Image.asset(AppImages.appLogoImage, width: 72, height: 72),
                const Spacer(),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.error.withValues(alpha: 0.18),
                          colorScheme.error.withValues(alpha: 0.06),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.error.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      size: 54,
                      color: colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  languageProvider.tr('configuration.title'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  languageProvider.tr('configuration.subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  languageProvider.tr('configuration.description'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isChecking ? null : _tryAgain,
                    icon: _isChecking
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isChecking
                          ? languageProvider.tr('common.checking')
                          : languageProvider.tr('common.tryAgain'),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${languageProvider.tr('common.appVersion')}: $appVersion',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
