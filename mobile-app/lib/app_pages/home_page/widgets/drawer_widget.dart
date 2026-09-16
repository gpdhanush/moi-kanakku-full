import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

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
    final iconColor = isLogout ? AppColors.moiGiven : AppColors.primary;
    final textColor = isLogout ? AppColors.moiGiven : AppColors.textPrimary;
    final accentColor = isLogout ? AppColors.moiGiven : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTab,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: iconColor,
                  size: 20,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                size: 18,
                strokeWidth: 1.8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
