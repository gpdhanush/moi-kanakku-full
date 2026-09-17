import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/settings_page/settings_menus_panel.dart';
import 'package:moi/app_services/connection.dart';
import 'package:moi/app_services/export_service.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiAppHeader(
            title: languageProvider.tr('nav.more'),
          ),
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              MediaQuery.paddingOf(context).bottom + AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MoreCard(
                  children: [
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      iconBg: const Color(0xffEFF6FF),
                      iconColor: primary,
                      title: languageProvider.tr('menu.upcomingFunctions'),
                      subtitle: languageProvider.tr('more.upcomingHint'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        'upcoming-function-list',
                      ),
                    ),
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedUserCircle02,
                      iconBg: const Color(0xffECFDF5),
                      iconColor: const Color(0xff059669),
                      title: languageProvider.tr('menu.profile'),
                      subtitle: languageProvider.tr('more.profileHint'),
                      onTap: () => Navigator.pushNamed(context, 'profile'),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _MoreCard(
                  children: [
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedPdf02,
                      iconBg: const Color(0xffEEF2FF),
                      iconColor: const Color(0xff4F46E5),
                      title: languageProvider.tr('more.export'),
                      subtitle: languageProvider.tr('more.exportHint'),
                      onTap: () => _onExportTap(context),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const SettingsMenusPanel(),
                const SizedBox(height: AppSpacing.lg),
                _MoreCard(
                  children: [
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedStar,
                      iconBg: const Color(0xffFFF7ED),
                      iconColor: const Color(0xffEA580C),
                      title: languageProvider.tr('menu.rateUs'),
                      subtitle: languageProvider.tr('more.rateUsHint'),
                      onTap: () => _rateApp(),
                    ),
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedContact,
                      iconBg: const Color(0xffF0F9FF),
                      iconColor: const Color(0xff0284C7),
                      title: languageProvider.tr('menu.contactUs'),
                      subtitle: languageProvider.tr('more.contactHint'),
                      onTap: () => Navigator.pushNamed(context, 'contact_us'),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _MoreCard(
                  children: [
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedLogout01,
                      iconBg: AppColors.moiGivenSoft,
                      iconColor: AppColors.moiGiven,
                      title: languageProvider.tr('menu.logout'),
                      subtitle: languageProvider.tr('more.logoutHint'),
                      showChevron: false,
                      showDivider: false,
                      titleColor: AppColors.moiGiven,
                      onTap: () => _onLogoutTap(context),
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

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
    await inAppReview.openStoreListing(appStoreId: 'com.renzo.moi');
  }

  Future<void> _onExportTap(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    final confirm = await showMoiConfirmSheet(
      context: context,
      title: languageProvider.tr('more.export'),
      message: languageProvider.tr('more.exportConfirmMessage'),
      confirmLabel: languageProvider.tr('common.ok'),
      cancelLabel: languageProvider.tr('common.cancel'),
      icon: HugeIcons.strokeRoundedPdf02,
    );

    if (confirm == true && context.mounted) {
      await _exportAllFunctionTransactions(context);
    }
  }

  Future<void> _exportAllFunctionTransactions(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final alertServices = AlertServices();
    final storage = SecureStorageService();
    final txServices = TransactionServices();

    try {
      alertServices.showLoading(languageProvider.tr('more.exporting'));

      final user = await storage.get(AppVariables.userInformation);
      if (user == null) {
        await alertServices.hideLoading();
        alertServices.errorToast(
          languageProvider.tr('home.userDetailsNotFound'),
        );
        return;
      }

      final response = await txServices.listTransactions({
        'userId': user['id'].toString(),
      }, showLoading: false);

      final List transactions = (response != null &&
              response['responseType'] == 'S')
          ? (response['responseValue'] as List? ?? [])
          : [];

      if (transactions.isEmpty) {
        await alertServices.hideLoading();
        alertServices.errorToast(
          languageProvider.tr('home.noTransactionsToExport'),
        );
        return;
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      await ExportService.exportTransactionsToPdf(
        transactions: transactions,
        userDetails: user,
        fileName: 'Moi_Kanakku_All_Functions_$timestamp.pdf',
        saveToDownloads: true,
        onBeforeShare: () => alertServices.hideLoading(),
      );

      alertServices.successToast(
        languageProvider.tr('home.exportedSuccessfully'),
      );
    } catch (e) {
      debugPrint('More export error: $e');
      await alertServices.hideLoading();
      alertServices.errorToast(languageProvider.tr('home.exportError'));
    }
  }

  Future<void> _onLogoutTap(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    final confirm = await showMoiConfirmSheet(
      context: context,
      title: languageProvider.tr('menu.logout'),
      message: languageProvider.tr('menu.logoutConfirmation'),
      confirmLabel: languageProvider.tr('common.yes'),
      cancelLabel: languageProvider.tr('common.no'),
      icon: HugeIcons.strokeRoundedLogout01,
      isDestructive: true,
    );

    if (confirm == true && context.mounted) {
      await _logoutApp(context);
    }
  }

  Future<void> _logoutApp(BuildContext context) async {
    final secureStorage = SecureStorageService();
    final userServices = UserServices();

    if (!context.mounted) return;

    try {
      final userData = await secureStorage.get(AppVariables.userInformation);
      if (userData != null && userData['id'] != null) {
        await userServices.logout({
          'userId': userData['id'].toString(),
        });
      }
    } catch (_) {}

    if (!context.mounted) return;
    Connection.instance.clearCachedToken();
    await secureStorage.clearSessionData();

    if (context.mounted) {
      try {
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).clearUserData();
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
  }
}

class _MoreCard extends StatelessWidget {
  final List<Widget> children;

  const _MoreCard({required this.children});

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

class _MoreRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;
  final Color? titleColor;

  const _MoreRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
    this.titleColor,
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
                            color: titleColor ?? AppColors.textPrimary,
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
                  if (showChevron) ...[
                    const SizedBox(width: 8),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      strokeWidth: 1.9,
                      size: 16,
                      color: Color(0xffA1A1AA),
                    ),
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
