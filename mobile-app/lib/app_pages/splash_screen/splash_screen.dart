import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final SplashScreenController _splashController;
  late final AnimationController _entrance;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _splashController = SplashScreenController();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 640),
    );
    _fadeIn = CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrance, curve: Curves.easeOutCubic));
    _entrance.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _splashController.setContext(context);
      _splashController.init();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final media = MediaQuery.of(context);

    return ChangeNotifierProvider.value(
      value: _splashController,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  AppColors.surfaceBlue.withValues(alpha: 0.55),
                  Color.lerp(AppColors.primarySoft, Colors.white, 0.35)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      media.size.height * 0.08,
                      AppSpacing.page,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Container(
                          width: 112,
                          height: 112,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.14),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            AppImages.appLogoImage,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          appName,
                          textAlign: TextAlign.center,
                          style: AppTypography.authTitle.copyWith(
                            fontSize: 24,
                            color: AppColors.authTitle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track functions & moi with ease',
                          textAlign: TextAlign.center,
                          style: AppTypography.authSubtitle.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(flex: 3),
                        Consumer<SplashScreenController>(
                          builder: (context, controller, _) {
                            return _SplashProgressSection(
                              progress: controller.progress,
                              percent: controller.progressPercent,
                              statusLabel: controller.statusLabel,
                              version: controller.version,
                              primary: primary,
                            );
                          },
                        ),
                        SizedBox(height: media.padding.bottom > 0 ? 4 : 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashProgressSection extends StatelessWidget {
  final double progress;
  final int percent;
  final String statusLabel;
  final String version;
  final Color primary;

  const _SplashProgressSection({
    required this.progress,
    required this.percent,
    required this.statusLabel,
    required this.version,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                statusLabel,
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: AppTypography.label.copyWith(
                color: primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          version.isEmpty ? ' ' : 'Version $version',
          textAlign: TextAlign.center,
          style: AppTypography.label.copyWith(
            color: AppColors.textSecondary.withValues(alpha: 0.85),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
