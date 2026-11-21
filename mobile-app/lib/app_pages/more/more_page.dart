import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/settings_page/settings_menus_panel.dart';
import 'package:moi/app_services/connection.dart';
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
    context.watch<ThemeProvider>();
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: MoiAppHeader(
            title: languageProvider.tr('nav.more'),
            titleFontSize: 12,
            height: AppConstants.appHeaderHeight,
            accent: AppColors.primary,
            showBack: false,
          ),
          body: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              MediaQuery.paddingOf(context).bottom + AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MoiInfoSectionLabel(
                  title: languageProvider.tr('more.sectionGeneral'),
                ),
                const SizedBox(height: AppSpacing.sm),
                MoiInfoCard(
                  children: [
                    MoiInfoTile(
                      icon: HugeIcons.strokeRoundedCalendar01,
                      title: languageProvider.tr('menu.upcomingFunctions'),
                      subtitle: languageProvider.tr('more.upcomingHint'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        'upcoming-function-list',
                      ),
                    ),
                    MoiInfoTile(
                      icon: HugeIcons.strokeRoundedComment01,
                      title: languageProvider.tr('nav.feedbacks'),
                      subtitle: languageProvider.tr('more.feedbacksHint'),
                      onTap: () => Navigator.pushNamed(context, 'feedbacks'),
                    ),
                    MoiInfoTile(
                      icon: HugeIcons.strokeRoundedUserCircle02,
                      title: languageProvider.tr('menu.profile'),
                      subtitle: languageProvider.tr('more.profileHint'),
                      onTap: () => Navigator.pushNamed(context, 'profile'),
                    ),
                    MoiInfoTile(
                      icon: HugeIcons.strokeRoundedPdf02,
                      title: languageProvider.tr('more.export'),
                      subtitle: languageProvider.tr('more.exportHint'),
                      onTap: () => _onExportTap(context),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SettingsMenusPanel(
                  onContactUs: () => Navigator.pushNamed(context, 'contact_us'),
                  onRateUs: () => _rateApp(),
                  onLogout: () => _onLogoutTap(context),
                  contactSubtitle: languageProvider.tr('more.contactHint'),
                  rateUsSubtitle: languageProvider.tr('more.rateUsHint'),
                  logoutSubtitle: languageProvider.tr('more.logoutHint'),
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

  Future<void> _onExportTap(BuildContext context) {
    return showExportSupportSheet(
      context: context,
      languageProvider: Provider.of<LanguageProvider>(context, listen: false),
    );
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
        await userServices.logout({'userId': userData['id'].toString()});
      }
    } catch (_) {}

    if (!context.mounted) return;
    Connection.instance.clearCachedToken();
    await secureStorage.clearSessionData();

    if (context.mounted) {
      try {
        await Provider.of<UserProvider>(context, listen: false).clearUserData();
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
  }
}
