import 'package:flutter/material.dart';
import 'package:moi/app_themes/index.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final double? width;
  final FontWeight? fontWeight;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.width,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: width ?? double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: AppColors.charcoal.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              title,
              style: AppTextStyles.textButtonStyle.copyWith(
                color: colors.onPrimary,
                decoration: TextDecoration.none,
                fontWeight: fontWeight ?? FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
