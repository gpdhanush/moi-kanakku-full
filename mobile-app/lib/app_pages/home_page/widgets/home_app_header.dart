import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_utils/app_widgets/moi_app_header.dart';

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
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final labelWidth =
        (MediaQuery.sizeOf(context).width * 0.42).clamp(132.0, 176.0);

    return MoiAppHeader(
      height: 72,
      titleWidget: Image.asset(
        AppImages.splashLightText,
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
  }
}
