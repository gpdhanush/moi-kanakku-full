import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';

/// Reusable app header for Home, Function, Overview, Feedbacks, More
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
    this.height = AppConstants.appHeaderHeight,
    this.titleFontSize = 18,
    this.accent,
  });

  @override
  Size get preferredSize {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    return Size.fromHeight(hasSubtitle ? height + 12 : height);
  }

  /// Circular action button used in header actions / leading.
  static Widget circleButton({
    required Widget child,
    required VoidCallback onTap,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        final colors = AppColors.of(context);
        final button = Material(
          color: backgroundColor ?? colors.textPrimary.withValues(alpha: 0.06),
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
      },
    );
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
        child: Builder(
          builder: (context) {
            final iconColor = AppColors.of(context).textPrimary;
            return circleButton(
              tooltip: tooltip,
              onTap: onTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    color: iconColor,
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
                          border: Border.all(
                            color: badgeBorderColor,
                            width: 1.5,
                          ),
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
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    final titleColor = isDark ? colors.textPrimary : const Color(0xFF102A2A);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final bgColor = isDark ? AppColors.darkSurface : const Color(0xFFF8FAF5);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8E5);
    final headerAccent = isDark ? AppColors.accent : const Color(0xFF16A34A);

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Stack(
          children: [
            // One very subtle abstract curved shape in the corner
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: headerAccent.withValues(alpha: isDark ? 0.12 : 0.05),
                ),
              ),
            ),
            // Thin green gradient accent line
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.accent,
                            AppColors.accentDark,
                            AppColors.accent,
                          ]
                        : const [
                            Color(0xFF16A34A),
                            Color(0xFF087443),
                            Color(0xFF16A34A),
                          ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      leadingWidth: 54,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: circleButton(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  backgroundColor: Colors.transparent,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                    strokeWidth: 1.9,
                  ),
                ),
              ),
            )
          : const SizedBox(width: 54),
      title:
          titleWidget ??
          (hasSubtitle
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.toTitleCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
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
                        color: subtitleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Text(
                  title.toTitleCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    color: titleColor,
                    fontSize: titleFontSize >= 18 ? titleFontSize : 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                )),
      actions: actions ?? const [SizedBox(width: 54)],
    );
  }
}

/// Banner style app header matching the recommended design specification.
/// Warm off-white #F8FAF5 background, dark teal #102A2A 22-24px semibold title,
/// #64748B secondary text, thin green gradient accent line (#16A34A to #087443),
/// one subtle abstract curved corner shape, and clean #E2E8E5 border (no heavy shadows).
class MoiBannerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double height;

  const MoiBannerHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.actions,
    this.height = 84,
  });

  @override
  Size get preferredSize {
    const topPadding = 24.0;
    return Size.fromHeight(height + topPadding);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.paddingOf(context).top;
    final totalHeight = height + topPadding;

    final bgColor = isDark ? AppColors.darkSurface : const Color(0xFFF8FAF5);
    final titleColor = isDark ? Colors.white : const Color(0xFF102A2A);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8E5);
    final headerAccent = isDark ? AppColors.accent : const Color(0xFF16A34A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Container(
        height: totalHeight,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Stack(
          children: [
            // One very subtle abstract curved shape in the corner
            Positioned(
              top: -32,
              right: -24,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: headerAccent.withValues(alpha: isDark ? 0.12 : 0.05),
                ),
              ),
            ),
            // Right gift box artwork + foliage
            Positioned(
              right: 12,
              bottom: 6,
              child: _buildHeaderGraphic(isDark),
            ),
            // Keep the light green accent and use the lime brand accent in dark mode.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.accent,
                            AppColors.accentDark,
                            AppColors.accent,
                          ]
                        : const [
                            Color(0xFF16A34A),
                            Color(0xFF087443),
                            Color(0xFF16A34A),
                          ],
                  ),
                ),
              ),
            ),
            // Main content layout (Back button if showBack, Title, Subtitle)
            Positioned.fill(
              top: topPadding,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (showBack) ...[
                      MoiAppHeader.circleButton(
                        onTap: onBack ?? () => Navigator.maybePop(context),
                        backgroundColor: Colors.transparent,
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                          strokeWidth: 1.9,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: showBack
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: showBack
                                ? TextAlign.left
                                : TextAlign.center,
                            style: AppTypography.sectionTitle.copyWith(
                              color: titleColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: showBack
                                  ? TextAlign.left
                                  : TextAlign.center,
                              style: AppTypography.body.copyWith(
                                color: subtitleColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    else
                      const SizedBox(width: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderGraphic(bool isDark) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Background green glow circle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(
                0xFF16A34A,
              ).withValues(alpha: isDark ? 0.15 : 0.08),
            ),
          ),
          // Top right foliage leaf 1
          Positioned(
            top: 4,
            right: 2,
            child: Transform.rotate(
              angle: 0.3,
              child: Icon(
                Icons.eco_rounded,
                size: 26,
                color: isDark
                    ? const Color(0xFF4ADE80)
                    : const Color(0xFF16A34A),
              ),
            ),
          ),
          // Bottom right foliage leaf 2
          Positioned(
            bottom: 6,
            right: 14,
            child: Transform.rotate(
              angle: -0.4,
              child: Icon(
                Icons.eco_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF087443),
              ),
            ),
          ),
          // 3D Gift Box
          Positioned(
            left: 8,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8E5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vertical ribbon
                  Container(
                    width: 8,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Horizontal ribbon
                  Container(
                    width: 44,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Top Bow Center Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF087443),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
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
