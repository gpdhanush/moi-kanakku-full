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
  static const double barHeight = 72;

  /// Kept for callers that previously padded above the floating pill.
  static const double bottomGap = 0;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MoiBottomNavItem> items;
  final VoidCallback? onAddTap;

  const MoiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onAddTap,
  });

  /// Space pages / FABs should leave clear above the bottom bar.
  static double clearanceOf(BuildContext context) {
    return barHeight + MediaQuery.viewPaddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final barColor = isDark ? AppColors.surface : AppColors.white;
    final colors = AppColors.of(context);

    final isCenterAddLayout = onAddTap != null && items.length == 4;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Material(
          color: barColor,
          elevation: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: barColor,
              border: Border(
                top: BorderSide(
                  color: primary,
                  width: 2,
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
                child: isCenterAddLayout
                    ? Row(
                        children: [
                          Expanded(
                            child: _MoiBottomNavTile(
                              item: items[0],
                              selected: currentIndex == 0,
                              active: colors.iconActive,
                              inactive: colors.iconDefault,
                              indicator: colors.moiReceivedSoft,
                              onTap: () => onTap(0),
                            ),
                          ),
                          Expanded(
                            child: _MoiBottomNavTile(
                              item: items[1],
                              selected: currentIndex == 1,
                              active: colors.iconActive,
                              inactive: colors.iconDefault,
                              indicator: colors.moiReceivedSoft,
                              onTap: () => onTap(1),
                            ),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                          Expanded(
                            child: _MoiBottomNavTile(
                              item: items[2],
                              selected: currentIndex == 2,
                              active: colors.iconActive,
                              inactive: colors.iconDefault,
                              indicator: colors.moiReceivedSoft,
                              onTap: () => onTap(2),
                            ),
                          ),
                          Expanded(
                            child: _MoiBottomNavTile(
                              item: items[3],
                              selected: currentIndex == 3,
                              active: colors.iconActive,
                              inactive: colors.iconDefault,
                              indicator: colors.moiReceivedSoft,
                              onTap: () => onTap(3),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: List.generate(items.length, (index) {
                          return Expanded(
                            child: _MoiBottomNavTile(
                              item: items[index],
                              selected: index == currentIndex,
                              active: colors.iconActive,
                              inactive: colors.iconDefault,
                              indicator: colors.moiReceivedSoft,
                              onTap: () => onTap(index),
                            ),
                          );
                        }),
                      ),
              ),
            ),
          ),
        ),
        if (isCenterAddLayout)
          Positioned(
            top: -26,
            child: Material(
              color: Colors.transparent,
              elevation: 0,
              child: InkWell(
                onTap: onAddTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.38),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAdd01,
                      color: Colors.white,
                      size: 26,
                      strokeWidth: 2.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MoiBottomNavTile extends StatelessWidget {
  final MoiBottomNavItem item;
  final bool selected;
  final Color active;
  final Color inactive;
  final Color indicator;
  final VoidCallback onTap;

  const _MoiBottomNavTile({
    required this.item,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.indicator,
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
            width: 48,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? indicator : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: HugeIcon(
              icon: item.icon,
              color: color,
              size: 22,
              strokeWidth: selected ? 2.0 : 1.7,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: AppTypography.label.copyWith(
              color: color,
              fontSize: 10.5,
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
