import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

/// Tailwind-style drawer row: soft surface, ring border, theme accent.
class DrawerWidget extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String title;
  final GestureTapCallback onTab;
  final bool isLogout;

  const DrawerWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTab,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = isLogout ? AppColors.moiGiven : primary;
    final surface = isLogout ? AppColors.moiGivenSoft : colors.surface;
    final border = isLogout
        ? AppColors.moiGiven.withValues(alpha: 0.22)
        : colors.border;
    final titleColor = isLogout ? AppColors.moiGiven : colors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTab,
        borderRadius: BorderRadius.circular(12),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff09090B).withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.14),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: icon,
                    color: accent,
                    size: 18,
                    strokeWidth: 1.9,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: isLogout
                      ? AppColors.moiGiven.withValues(alpha: 0.55)
                      : const Color(0xffA1A1AA), // zinc-400
                  size: 16,
                  strokeWidth: 1.9,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
