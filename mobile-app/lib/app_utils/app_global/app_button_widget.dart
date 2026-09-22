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
  final Color? textColor;
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
    this.textColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<List<dynamic>>? effectiveIcon =
        icon ?? (showIcon ? HugeIcons.strokeRoundedFloppyDisk : null);

    final lightButtonColor = Theme.of(context).colorScheme.primary;
    final defaultGradient = isDark
        ? LinearGradient(
            colors: [
              primaryColor,
              AppColors.deepenAccent(primaryColor, amount: 0.25),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : null;

    final effectiveBackgroundColor =
        color ?? (isDark ? null : lightButtonColor);
    final effectiveGradient = color == null && isDark
        ? gradient ?? defaultGradient
        : gradient;
    final shadowColor = isDark
        ? primaryColor.withValues(alpha: 0.22)
        : lightButtonColor.withValues(alpha: 0.18);

    final contentColor =
        textColor ?? (isDark ? AppColors.charcoal : AppColors.white);
    const radius = 5.0;

    return Container(
      width: width ?? double.infinity,
      height: isDark ? 50 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: effectiveBackgroundColor,
        gradient: effectiveGradient,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: (color ?? shadowColor),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
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
