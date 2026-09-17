import 'package:flutter/material.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_themes/app_typography.dart';

/// Shared field label with optional red required asterisk.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel({super.key, required this.text, required this.required});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTypography.label.copyWith(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: AppTypography.label.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                  ),
                ),
              ]
            : const [],
      ),
    );
  }
}
