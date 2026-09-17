import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Consumer2<LanguageProvider, UserProvider>(
      builder: (context, languageProvider, userProvider, _) {
        final user = userProvider.userDetails.isNotEmpty
            ? Map<String, dynamic>.from(userProvider.userDetails[0] as Map)
            : null;
        final name = user?['name']?.toString().trim().isNotEmpty == true
            ? user!['name'].toString().trim()
            : languageProvider.tr('menu.guestUser');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _MoreAppHeader(
            title: languageProvider.tr('nav.more'),
            subtitle: languageProvider.tr('more.subtitle'),
            name: name,
            user: user,
            onProfileTap: () => Navigator.pushNamed(context, 'profile'),
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
                    ),
                    _MoreRow(
                      icon: HugeIcons.strokeRoundedSettings01,
                      iconBg: const Color(0xffEEF2FF),
                      iconColor: const Color(0xff4F46E5),
                      title: languageProvider.tr('menu.settings'),
                      subtitle: languageProvider.tr('more.settingsHint'),
                      onTap: () => Navigator.pushNamed(context, 'settings'),
                      showDivider: false,
                    ),
                  ],
                ),
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

class _MoreAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String name;
  final Map<String, dynamic>? user;
  final VoidCallback onProfileTap;

  const _MoreAppHeader({
    required this.title,
    required this.subtitle,
    required this.name,
    required this.user,
    required this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(118);

  String _resolveProfileImageUrl() {
    if (user == null) return '';
    final path = (user!['profile_image_url'] ?? user!['profile_image'])
            ?.toString()
            .trim() ??
        '';
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '$appImageUrl/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  String get _contactLine {
    final email = user?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;
    final phone = user?['phone']?.toString().trim() ??
        user?['mobile']?.toString().trim() ??
        '';
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = _resolveProfileImageUrl();
    final contact = _contactLine;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      centerTitle: false,
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
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 56,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 10,
                  ),
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
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTypography.label.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: imageUrl.isEmpty
                            ? Container(
                                color: Colors.white.withValues(alpha: 0.2),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: AppTypography.sectionTitle.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initial,
                                      style:
                                          AppTypography.sectionTitle.copyWith(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sectionTitle.copyWith(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            contact.isNotEmpty ? contact : subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        color: Colors.white,
                        size: 16,
                        strokeWidth: 1.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
