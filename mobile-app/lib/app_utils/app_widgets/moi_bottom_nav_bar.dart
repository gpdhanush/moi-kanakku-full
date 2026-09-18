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

  /// Width reserved under the Paytm-style center FAB.
  static const double centerFabSlotWidth = 74;

  /// Kept for callers that previously padded above the floating pill.
  static const double bottomGap = 0;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MoiBottomNavItem> items;

  /// Optional Paytm-style center action rendered above the bar.
  final Widget? centerFab;

  const MoiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerFab,
  });

  /// Space pages / FABs should leave clear above the bottom bar.
  static double clearanceOf(BuildContext context) {
    final fabExtra = centerFabSlotWidth > 0 ? 28.0 : 0.0;
    return barHeight + MediaQuery.viewPaddingOf(context).bottom + fabExtra;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final barColor = isDark ? AppColors.surface : AppColors.white;
    final useFabSlot = centerFab != null && items.length == 4;

    final bar = Material(
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
              color: primary.withValues(alpha: 0.08),
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
            child: useFabSlot
                ? _buildWithCenterSlot(primary)
                : _buildEvenRow(primary),
          ),
        ),
      ),
    );

    if (centerFab == null) return bar;

    return SizedBox(
      height: barHeight + bottomInset + 30,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: bar,
          ),
          Positioned(
            bottom: bottomInset + barHeight - 30,
            child: centerFab!,
          ),
        ],
      ),
    );
  }

  Widget _buildEvenRow(Color primary) {
    return Row(
      children: List.generate(items.length, (index) {
        return Expanded(
          child: _MoiBottomNavTile(
            item: items[index],
            selected: index == currentIndex,
            primary: primary,
            onTap: () => onTap(index),
          ),
        );
      }),
    );
  }

  /// Layout: [0][1] · FAB gap · [2][3] — keeps the FAB truly centered.
  Widget _buildWithCenterSlot(Color primary) {
    Widget tab(int index) {
      return Expanded(
        child: _MoiBottomNavTile(
          item: items[index],
          selected: index == currentIndex,
          primary: primary,
          onTap: () => onTap(index),
        ),
      );
    }

    return Row(
      children: [
        tab(0),
        tab(1),
        const SizedBox(width: centerFabSlotWidth),
        tab(2),
        tab(3),
      ],
    );
  }
}

class _MoiBottomNavTile extends StatelessWidget {
  final MoiBottomNavItem item;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _MoiBottomNavTile({
    required this.item,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = AppColors.textSecondary;
    final color = selected ? primary : inactive;

    return InkWell(
      onTap: onTap,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
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
                  ? primary.withValues(alpha: 0.10)
                  : Colors.transparent,
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
              fontSize: 11,
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
