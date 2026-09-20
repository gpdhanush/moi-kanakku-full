import 'package:flutter/material.dart';
import 'package:moi/app_themes/index.dart';

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Color? color;

  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        color ?? (isDark ? const Color(0xFF2A2F35) : const Color(0xFFE9ECE6));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class AppSkeletonListTile extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;

  const AppSkeletonListTile({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppColors.of(context).surface;
    final border = AppColors.of(context).border;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showAvatar)
            AppSkeleton(
              width: 52,
              height: 52,
              radius: 16,
              color: isDark ? const Color(0xFF2F343A) : const Color(0xFFE8EDE6),
            )
          else
            const SizedBox(width: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(
                  width: 140,
                  height: 14,
                  radius: 8,
                  color: isDark
                      ? const Color(0xFF323A40)
                      : const Color(0xFFE6EAE4),
                ),
                const SizedBox(height: 10),
                AppSkeleton(
                  width: 180,
                  height: 12,
                  radius: 8,
                  color: isDark
                      ? const Color(0xFF2B3137)
                      : const Color(0xFFE4E8E2),
                ),
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            AppSkeleton(
              width: 70,
              height: 26,
              radius: 10,
              color: isDark ? const Color(0xFF2E3539) : const Color(0xFFE9EEE3),
            ),
          ],
        ],
      ),
    );
  }
}

class AppSkeletonBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const AppSkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppSkeleton(
      width: width,
      height: height,
      radius: radius,
      color: isDark ? const Color(0xFF2B3137) : const Color(0xFFE7EAE5),
    );
  }
}
