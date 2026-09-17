import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

class MoiBottomNavItem {
  final List<List<dynamic>> icon;
  final String label;

  const MoiBottomNavItem({required this.icon, required this.label});
}

/// Floating pill bottom nav — matches the reference screenshot.
class MoiBottomNavBar extends StatelessWidget {
  /// Fixed height of the white pill content.
  static const double barHeight = 62;

  /// Side gap from screen edges.
  static const double sideInset = 16;

  /// Gap under the pill (above home indicator / screen edge).
  static const double bottomGap = 16;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MoiBottomNavItem> items;

  const MoiBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Space pages / FABs should leave clear above the floating bar.
  static double clearanceOf(BuildContext context) {
    return barHeight + bottomGap + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: clearanceOf(context),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            sideInset,
            0,
            sideInset,
            bottomInset + bottomGap,
          ),
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff09090B).withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xff09090B).withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
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
                ),
              ),
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
    // Inactive: muted blue-gray like the reference.
    final inactive = const Color(0xff7B8494);
    final color = selected ? primary : inactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1, end: selected ? 1.06 : 1),
            duration: const Duration(milliseconds: 220),
            curve: selected ? Curves.easeOutBack : Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: HugeIcon(
              key: ValueKey<bool>(selected),
              icon: item.icon,
              color: color,
              size: 22,
              strokeWidth: selected ? 2.0 : 1.7,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
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
