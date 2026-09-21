import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/theme_provider.dart';
import 'package:moi/app_utils/app_widgets/moi_app_header.dart';
import 'package:provider/provider.dart';

/// Home tab header — shared [MoiAppHeader] with notifications action.
class HomeAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final int unreadNotificationCount;
  final VoidCallback onNotificationsTap;
  final String notificationsTooltip;

  const HomeAppHeader({
    super.key,
    required this.unreadNotificationCount,
    required this.onNotificationsTap,
    required this.notificationsTooltip,
  });

  @override
  Size get preferredSize => const Size.fromHeight(AppConstants.appHeaderHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final isDarkMode = themeProvider.isDarkMode;
        final labelWidth = (MediaQuery.sizeOf(context).width * 0.42).clamp(
          132.0,
          176.0,
        );
        final headerLabelAsset = isDarkMode
            ? AppImages.splashLightText
            : AppImages.splashLabelDark;

        return MoiAppHeader(
          height: AppConstants.appHeaderHeight,
          titleWidget: Image.asset(
            headerLabelAsset,
            width: labelWidth,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          actions: [
            MoiAppHeader.notificationButton(
              onTap: onNotificationsTap,
              tooltip: notificationsTooltip,
              unreadCount: unreadNotificationCount,
              badgeBorderColor: primary,
            ),
          ],
        );
      },
    );
  }
}
