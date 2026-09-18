import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

class MoiBottomNavItem {
  final List<List<dynamic>> icon;
  final String label;

  const MoiBottomNavItem({required this.icon, required this.label});
}

/// Full-width bottom menu bar for the main app shell.
class MoiBottomNavBar extends StatelessWidget {
  /// Content height of the menu row (excluding system bottom inset).
  static const double barHeight = 76;

  /// Kept for callers that previously padded above the floating pill.
  static const double bottomGap = 0;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MoiBottomNavItem> items;

  const MoiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Space pages / FABs should leave clear above the bottom bar.
  static double clearanceOf(BuildContext context) {
    return barHeight + MediaQuery.viewPaddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    // Scaffold consumes MediaQuery.padding for bottomNavigationBar, so use
    // viewPadding to keep clear of the system gesture / home indicator.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: colors.surface,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.border,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.charcoal.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SizedBox(
            height: barHeight,
            width: double.infinity,
            child: Row(
              children: List.generate(items.length, (index) {
                return Expanded(
                  child: _MoiBottomNavTile(
                    item: items[index],
                    selected: index == currentIndex,
                    active: colors.iconActive,
                    inactive: colors.iconDefault,
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoiBottomNavTile extends StatelessWidget {
  final MoiBottomNavItem item;
  final bool selected;
  final Color active;
  final Color inactive;
  final VoidCallback onTap;

  const _MoiBottomNavTile({
    required this.item,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? active : inactive;

    return InkWell(
      onTap: onTap,
      splashColor: active.withValues(alpha: 0.08),
      highlightColor: active.withValues(alpha: 0.04),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? active.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: HugeIcon(
              icon: item.icon,
              color: color,
              size: 24,
              strokeWidth: selected ? 2.0 : 1.7,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: AppTypography.label.copyWith(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.1,
              height: 1.1,
            ),
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
