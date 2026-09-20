import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/index.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double? width;
  final FontWeight? fontWeight;
  final List<List<dynamic>>? icon;
  final bool showIcon;
  final bool isLoading;
  final Color? color;
  final Gradient? gradient;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.width,
    this.fontWeight,
    this.icon,
    this.showIcon = true,
    this.isLoading = false,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<List<dynamic>>? effectiveIcon = icon ??
        (showIcon ? HugeIcons.strokeRoundedFloppyDisk : null);

    final defaultGradient = isDark
        ? LinearGradient(
            colors: [
              primaryColor,
              AppColors.deepenAccent(primaryColor, amount: 0.25),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFF22C55E),
              Color(0xFF059669),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

    final shadowColor = isDark
        ? primaryColor.withValues(alpha: 0.22)
        : const Color(0xFF059669).withValues(alpha: 0.35);

    final contentColor = isDark ? AppColors.charcoal : Colors.white;

    return Container(
      width: width ?? double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: color,
        gradient: color == null ? (gradient ?? defaultGradient) : gradient,
        boxShadow: [
          BoxShadow(
            color: (color ?? shadowColor),
            blurRadius: 12,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: contentColor,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (effectiveIcon != null) ...[
                        HugeIcon(
                          icon: effectiveIcon,
                          color: contentColor,
                          size: 19,
                          strokeWidth: 2.0,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        title,
                        style: AppTextStyles.textButtonStyle.copyWith(
                          color: contentColor,
                          decoration: TextDecoration.none,
                          fontWeight: fontWeight ?? FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
