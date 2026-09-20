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
    const overflowTop = 26.0;

    return SizedBox(
      height: (isCenterAddLayout ? overflowTop : 0) + barHeight + bottomInset,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: isCenterAddLayout ? overflowTop : 0,
            bottom: 0,
            child: Material(
              color: barColor,
              elevation: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: barColor,
                  border: Border(top: BorderSide(color: primary, width: 2)),
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
          ),
          if (isCenterAddLayout)
            Positioned(
              top: 0,
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
                      boxShadow: const [],
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : Colors.black,
                        size: 26,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDotColor = isDark
        ? const Color(0xFFB9F863)
        : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: selected ? 72 : 40,
            height: selected ? 34 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? indicator : Colors.transparent,
              borderRadius: BorderRadius.circular(selected ? 18 : 12),
              boxShadow: const [],
            ),
            child: HugeIcon(
              icon: item.icon,
              color: selected ? active : inactive,
              size: selected ? 22 : 20,
              strokeWidth: selected ? 2.0 : 1.8,
            ),
          ),
          const SizedBox(height: 6),
          if (!selected)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              style: AppTypography.label.copyWith(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                height: 1.1,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              width: 8,
              height: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: activeDotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
