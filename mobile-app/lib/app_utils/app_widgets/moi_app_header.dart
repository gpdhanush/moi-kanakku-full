import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Reusable gradient app header for Home, Function, Overview, Feedbacks, More
/// and other flow screens. Pass different params for each page variation.
class MoiAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double height;
  final double titleFontSize;

  /// Optional accent for decorative circle + bottom strip (flow screens).
  final Color? accent;

  const MoiAppHeader({
    super.key,
    this.title = '',
    this.subtitle,
    this.titleWidget,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.height = 72,
    this.titleFontSize = 16,
    this.accent,
  });

  @override
  Size get preferredSize {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    return Size.fromHeight(hasSubtitle ? height + 12 : height);
  }

  /// Circular frosted action button used in header actions / leading.
  static Widget circleButton({
    required Widget child,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 42, height: 42, child: Center(child: child)),
      ),
    );

    if (tooltip == null || tooltip.isEmpty) return button;
    return Tooltip(message: tooltip, child: button);
  }

  /// Notifications action with optional unread badge.
  static Widget notificationButton({
    required VoidCallback onTap,
    required String tooltip,
    required int unreadCount,
    required Color badgeBorderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Center(
        child: circleButton(
          tooltip: tooltip,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: Colors.white,
                size: 22,
                strokeWidth: 1.9,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    height: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 3.5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffFF4D4F),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeBorderColor, width: 1.5),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final accentColor = accent;

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      centerTitle: true,
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
              AppColors.deepenAccent(primary, amount: 0.35),
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: accentColor != null ? 36 : 48,
              child: Container(
                width: accentColor != null ? 72 : 90,
                height: accentColor != null ? 72 : 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor != null
                      ? accentColor.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            if (accentColor != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.12),
                        accentColor,
                        accentColor.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
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
      leadingWidth: 54,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: circleButton(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: Colors.white,
                    size: 22,
                    strokeWidth: 1.9,
                  ),
                ),
              ),
            )
          : const SizedBox(width: 54),
      title: titleWidget ??
          (hasSubtitle
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle.copyWith(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: titleFontSize >= 18 ? -0.3 : -0.2,
                    height: titleFontSize >= 18 ? 1.1 : null,
                  ),
                )),
      actions: actions ?? const [SizedBox(width: 54)],
    );
  }
}
