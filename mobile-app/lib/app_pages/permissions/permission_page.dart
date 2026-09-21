import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

import 'permission_controller.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  PermissionController? _controller;
  final SecureStorageService _storage = SecureStorageService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    pageTitleLogs("PERMISSION PAGE");
    _initializePage();
  }

  Future<void> _initializePage() async {
    final permissionsRequested = await _storage.hasPermissionsBeenRequested();
    if (!mounted) return;

    if (permissionsRequested) {
      Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
      return;
    }

    _controller = PermissionController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller == null) return;
      _controller!.setContext(context);
    });

    setState(() => _isChecking = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();

    if (_isChecking || _controller == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2.4, color: primary),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: ChangeNotifierProvider.value(
              value: _controller!,
              child: Consumer<PermissionController>(
                builder: (context, controller, child) {
                  final totalCount = controller.permissions.length;
                  final grantedCount = controller.grantedPermissions.length;
                  final allGranted =
                      totalCount > 0 && grantedCount == totalCount;

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.lg,
                            AppSpacing.page,
                            AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PermissionIntro(
                                title: languageProvider.tr('permissions.title'),
                                subtitle: languageProvider.tr(
                                  'permissions.subtitle',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Row(
                                children: [
                                  Text(
                                    languageProvider.tr('permissions.section'),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (controller.isLoadingPermissions)
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: primary,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (controller.isLoadingPermissions)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  ),
                                )
                              else
                                _PermissionList(
                                  controller: controller,
                                  languageProvider: languageProvider,
                                  primary: primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                      _PermissionBottomBar(
                        primary: primary,
                        languageProvider: languageProvider,
                        controller: controller,
                        allGranted: allGranted,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionIntro extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PermissionIntro({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.card,
          ),
          child: Image.asset(AppImages.appLogoImage, fit: BoxFit.contain),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.authTitle,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.authSubtitle,
        ),
      ],
    );
  }
}

class _PermissionList extends StatelessWidget {
  final PermissionController controller;
  final LanguageProvider languageProvider;
  final Color primary;

  const _PermissionList({
    required this.controller,
    required this.languageProvider,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: controller.permissions.asMap().entries.map((entry) {
        final index = entry.key;
        final permission = entry.value;
        final isGranted = controller.grantedPermissions.contains(permission.id);
        final isPermanentlyDenied = controller.permanentlyDeniedPermissions
            .contains(permission.id);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == controller.permissions.length - 1
                ? 0
                : AppSpacing.sm,
          ),
          child: _PermissionCard(
            permission: permission,
            imageAsset: permission.imageAsset,
            name: languageProvider.tr(permission.nameKey),
            description: languageProvider.tr(permission.descriptionKey),
            isGranted: isGranted,
            isPermanentlyDenied: isPermanentlyDenied,
            iconBg: primary.withValues(alpha: 0.1),
            iconColor: primary,
            allowLabel: languageProvider.tr('permissions.allowOne'),
            allowedLabel: languageProvider.tr('permissions.allowed'),
            settingsLabel: languageProvider.tr('permissions.openSettings'),
            onTap: () => controller.requestSinglePermission(permission),
          ),
        );
      }).toList(),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final PermissionInfo permission;
  final String? imageAsset;
  final String name;
  final String description;
  final bool isGranted;
  final bool isPermanentlyDenied;
  final Color iconBg;
  final Color iconColor;
  final String allowLabel;
  final String allowedLabel;
  final String settingsLabel;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.permission,
    required this.imageAsset,
    required this.name,
    required this.description,
    required this.isGranted,
    required this.isPermanentlyDenied,
    required this.iconBg,
    required this.iconColor,
    required this.allowLabel,
    required this.allowedLabel,
    required this.settingsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: AppRadius.mdAll,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isGranted
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : AppColors.white,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isGranted
                  ? primary.withValues(alpha: 0.4)
                  : primary.withValues(alpha: 0.28),
            ),
            boxShadow: isGranted ? null : AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isGranted ? primary.withValues(alpha: 0.12) : iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                        semanticLabel: name,
                      )
                    : HugeIcon(
                        icon: isGranted
                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                            : permission.icon,
                        size: isGranted ? 24 : 20,
                        color: isGranted ? primary : iconColor,
                        strokeWidth: 1.8,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: AppTypography.body.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusChip(
                isGranted: isGranted,
                isPermanentlyDenied: isPermanentlyDenied,
                allowLabel: allowLabel,
                allowedLabel: allowedLabel,
                settingsLabel: settingsLabel,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isGranted;
  final bool isPermanentlyDenied;
  final String allowLabel;
  final String allowedLabel;
  final String settingsLabel;
  final VoidCallback onTap;

  const _StatusChip({
    required this.isGranted,
    required this.isPermanentlyDenied,
    required this.allowLabel,
    required this.allowedLabel,
    required this.settingsLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (isGranted) {
      return _ChipShell(
        background: primary.withValues(alpha: 0.12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTick02,
              size: 13,
              color: primary,
              strokeWidth: 1.8,
            ),
            const SizedBox(width: 4),
            Text(
              allowedLabel,
              style: AppTypography.chip.copyWith(
                color: primary,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      );
    }

    if (isPermanentlyDenied) {
      return GestureDetector(
        onTap: onTap,
        child: _ChipShell(
          background: AppColors.accentAmberSoft,
          border: AppColors.accentAmber.withValues(alpha: 0.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                size: 13,
                color: AppColors.accentAmber,
                strokeWidth: 1.8,
              ),
              const SizedBox(width: 4),
              Text(
                settingsLabel,
                style: AppTypography.chip.copyWith(
                  color: const Color(0xffB45309),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: _ChipShell(
        background: primary.withValues(alpha: 0.08),
        border: primary.withValues(alpha: 0.35),
        child: Text(
          allowLabel,
          style: AppTypography.chip.copyWith(color: primary, fontSize: 12),
        ),
      ),
    );
  }
}

class _ChipShell extends StatelessWidget {
  final Color background;
  final Color? border;
  final Widget child;

  const _ChipShell({
    required this.background,
    required this.child,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: child,
    );
  }
}

class _PermissionBottomBar extends StatelessWidget {
  final Color primary;
  final LanguageProvider languageProvider;
  final PermissionController controller;
  final bool allGranted;

  const _PermissionBottomBar({
    required this.primary,
    required this.languageProvider,
    required this.controller,
    required this.allGranted,
  });

  @override
  Widget build(BuildContext context) {
    final busy = controller.isRequesting || controller.isLoadingPermissions;
    final title = allGranted
        ? languageProvider.tr('permissions.continue')
        : languageProvider.tr('permissions.allow');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff09090B).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: title,
            child: AppButton(
              title: title,
              onPressed: () => controller.requestAllPermissions(),
              isLoading: busy,
              color: primary,
              showIcon: false,
            ),
          ),
          if (!busy)
            TextButton(
              onPressed: () => controller.skipPermissions(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                languageProvider.tr('permissions.skip'),
                style: AppTypography.label.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
