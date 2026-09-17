import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/home_page/widgets/drawer_widget.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_services/connection.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'package:moi/app_utils/app_widgets/moi_network_image.dart';
import 'package:provider/provider.dart';

class BuildSideDrawer extends StatelessWidget {
  final List<dynamic> userDetails;

  const BuildSideDrawer({
    super.key,
    required this.userDetails,
    required BuildContext context,
  });

  Widget _buildMenuItem({
    required BuildContext context,
    required List<List<dynamic>> icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DrawerWidget(
        icon: icon,
        title: title,
        isLogout: isLogout,
        onTab: onTap,
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.chip.copyWith(
          color: const Color(0xff71717A), // zinc-500
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final drawerWidth = (width * 0.82).clamp(280.0, 340.0);

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final name = userDetails.isNotEmpty
            ? userDetails[0]['name'].toString()
            : languageProvider.tr('menu.guestUser');

        return Drawer(
          width: drawerWidth,
          backgroundColor: const Color(0xffFAFAFA), // zinc-50
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          elevation: 0,
          child: Column(
            children: [
              _DrawerHeader(
                primary: primary,
                name: name,
                user: userDetails.isNotEmpty
                    ? Map<String, dynamic>.from(userDetails[0] as Map)
                    : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  children: [
                    _sectionLabel(languageProvider.tr('menu.sectionMain')),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedWedding,
                      title: languageProvider.tr('menu.functions'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "functions-list");
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedAnalytics01,
                      title: languageProvider.tr('menu.moiDashboard'),
                      onTap: () {
                        Navigator.popAndPushNamed(
                          context,
                          "transaction-dashboard",
                        );
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedCalendar01,
                      title: languageProvider.tr('menu.upcomingFunctions'),
                      onTap: () {
                        Navigator.popAndPushNamed(
                          context,
                          "upcoming-function-list",
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _sectionLabel(languageProvider.tr('menu.sectionAccount')),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedUserCircle02,
                      title: languageProvider.tr('menu.profile'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "profile");
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedSettings01,
                      title: languageProvider.tr('menu.settings'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "settings");
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedComment01,
                      title: languageProvider.tr('menu.feedbacks'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "feedbacks");
                      },
                    ),
                    const SizedBox(height: 10),
                    _sectionLabel(languageProvider.tr('menu.sectionSupport')),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedStar,
                      title: languageProvider.tr('menu.rateUs'),
                      onTap: () async {
                        Navigator.pop(context);
                        final InAppReview inAppReview = InAppReview.instance;
                        if (await inAppReview.isAvailable()) {
                          inAppReview.requestReview();
                          inAppReview.openStoreListing(
                            appStoreId: 'com.renzo.moi',
                          );
                        } else {
                          inAppReview.openStoreListing(
                            appStoreId: 'com.renzo.moi',
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedContact,
                      title: languageProvider.tr('menu.contactUs'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "contact_us");
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuItem(
                      context: context,
                      icon: HugeIcons.strokeRoundedLogout01,
                      title: languageProvider.tr('menu.logout'),
                      isLogout: true,
                      onTap: () => _onLogoutTap(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onLogoutTap(BuildContext drawerContext) async {
    final scaffoldContext = Scaffold.maybeOf(drawerContext)?.context;
    final languageProvider = Provider.of<LanguageProvider>(
      drawerContext,
      listen: false,
    );

    // Close drawer first, then show confirmation on the page underneath.
    Navigator.of(drawerContext).pop();

    final hostContext = scaffoldContext ?? drawerContext;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!hostContext.mounted) return;

    final confirm = await showMoiConfirmSheet(
      context: hostContext,
      title: languageProvider.tr('menu.logout'),
      message: languageProvider.tr('menu.logoutConfirmation'),
      confirmLabel: languageProvider.tr('common.yes'),
      cancelLabel: languageProvider.tr('common.no'),
      icon: HugeIcons.strokeRoundedLogout01,
      isDestructive: true,
    );

    if (confirm == true && hostContext.mounted) {
      await logoutApp(hostContext);
    }
  }

  Future<void> logoutApp(BuildContext context) async {
    SecureStorageService secureStorage = SecureStorageService();
    UserServices userServices = UserServices();

    if (!context.mounted) return;

    try {
      final userData = await secureStorage.get(AppVariables.userInformation);
      if (userData != null && userData['id'] != null) {
        final response = await userServices.logout({
          "userId": userData['id'].toString(),
        });

        if (response != null && response['responseType'] == 'S') {
          printContent('Logout API successful');
        } else {
          printContent('Logout API failed, but continuing with local logout');
        }
      }
    } catch (e) {
      printContent('Error calling logout API: $e');
    }

    if (!context.mounted) return;

    Connection.instance.clearCachedToken();
    await secureStorage.clearSessionData();

    if (context.mounted) {
      try {
        final userProvider = Provider.of<UserProvider>(
          context,
          listen: false,
        );
        await userProvider.clearUserData();
      } catch (e) {
        printContent('UserProvider not available: $e');
      }
    }

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, "login", (route) => false);
  }
}

class _DrawerHeader extends StatelessWidget {
  final Color primary;
  final String name;
  final Map<String, dynamic>? user;

  const _DrawerHeader({
    required this.primary,
    required this.name,
    required this.user,
  });

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

  String get _subtitle {
    final email = user?['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;
    final phone = user?['phone']?.toString().trim() ??
        user?['mobile']?.toString().trim() ??
        '';
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveProfileImageUrl();
    final subtitle = _subtitle;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
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
          topRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 18,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
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
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : MoiNetworkImage(
                              url: imageUrl,
                              fit: BoxFit.cover,
                              width: 56,
                              height: 56,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: AppTypography.sectionTitle.copyWith(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: AppTypography.sectionTitle.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

