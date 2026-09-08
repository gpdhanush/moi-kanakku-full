import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/home_page/widgets/drawer_widget.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_global/alert_services.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
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
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DrawerWidget(
        icon: icon,
        title: title,
        isLogout: isLogout,
        onTab: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Drawer(
          backgroundColor: Colors.grey.shade50,
          shape: const RoundedRectangleBorder(),
          elevation: 0,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern - decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -40,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    // Content
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo with container
                            Container(
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                AppImages.appLogoImage,
                                height: 50,
                              ),
                            ),

                            const SizedBox(height: 8),
                            // User name with icon
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.person_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    userDetails.isNotEmpty
                                        ? userDetails[0]['name'].toString()
                                        : languageProvider.tr('menu.guestUser'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: "ProximaNova",
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.celebration_outlined,
                      title: languageProvider.tr('menu.functions'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "functions-list");
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.bar_chart_outlined,
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
                      icon: Icons.celebration_outlined,
                      title: languageProvider.tr('menu.upcomingFunctions'),
                      onTap: () {
                        Navigator.popAndPushNamed(
                          context,
                          "upcoming-function-list",
                        );
                      },
                    ),

                    _buildMenuItem(
                      context: context,
                      icon: Icons.account_circle_outlined,
                      title: languageProvider.tr('menu.profile'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "profile");
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: languageProvider.tr('menu.settings'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "settings");
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.feedback_outlined,
                      title: languageProvider.tr('menu.feedbacks'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "feedbacks");
                      },
                    ),
                    // _buildMenuItem(
                    //   context: context,
                    //   icon: Icons.local_offer_outlined,
                    //   title: languageProvider.tr('menu.specialOffers'),
                    //   onTap: () {
                    //     Navigator.popAndPushNamed(context, "promotion");
                    //   },
                    // ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.star_border_outlined,
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
                      icon: Icons.contact_phone_outlined,
                      title: languageProvider.tr('menu.contactUs'),
                      onTap: () {
                        Navigator.popAndPushNamed(context, "contact_us");
                      },
                    ),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.exit_to_app_outlined,
                      title: languageProvider.tr('menu.logout'),
                      isLogout: true,
                      onTap: () => logoutApp(context),
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

  // Handle user logout
  Future<void> logoutApp(BuildContext context) async {
    SecureStorageService secureStorage = SecureStorageService();
    AlertServices alertServices = AlertServices();
    UserServices userServices = UserServices();
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );

    String msg = languageProvider.tr('menu.logoutConfirmation');
    bool? confirm = await alertServices.confirmAlert(context, msg);

    if (confirm != null && confirm) {
      if (!context.mounted) return;

      try {
        // Get user ID from secure storage
        final userData = await secureStorage.get(AppVariables.userInformation);
        if (userData != null && userData['id'] != null) {
          // Call logout API
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
        // Continue with logout even if API call fails
      }

      if (!context.mounted) return;

      // Clear local storage and user provider
      await secureStorage.clearSessionData();

      // Clear UserProvider if available
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
}
