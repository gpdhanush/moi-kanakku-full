import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_themes/app_custom_themes.dart';
import 'package:moi/app_themes/app_typography.dart';

import 'mic_icon_widget.dart';
import 'field_label.dart';

/// Shared text form field used across the app.
class TextFormWidget extends StatelessWidget {
  static const double _radius = 12;
  static const double _fieldIconSize = 20;

  final String title;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<List<dynamic>>? prefixIcon;
  final Color? iconColor;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onFieldSubmitted;
  final bool required;
  final bool? readOnly;
  final bool? autofocus;
  final bool? enableMic;
  final GestureTapCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool? suffixIconTrue;
  final List<List<dynamic>>? suffixIcon;
  final String? suffixText;
  final String? prefixText;
  final VoidCallback? suffixIconOnPressed;
  final String? helperText;
  final String? errorText;
  final TextStyle? helperStyle;
  final bool? obscureText;
  final bool? enabled;
  final bool? autocorrect;
  final bool? enableSuggestions;
  final String? obscuringCharacter;
  final String? counterText;
  final int? errorMaxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? initialValue;
  final TextCapitalization? textCapitalization;
  final int? maxLines;
  final int? minLines;
  final InputDecoration? decoration;
  final AutovalidateMode? autovalidateMode;

  const TextFormWidget({
    super.key,
    required this.title,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.iconColor,
    this.controller,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    required this.required,
    this.readOnly,
    this.autofocus,
    this.onTap,
    this.inputFormatters,
    this.suffixIconTrue,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.suffixIconOnPressed,
    this.helperText,
    this.errorText,
    this.helperStyle,
    this.obscureText,
    this.enabled,
    this.autocorrect,
    this.enableSuggestions,
    this.obscuringCharacter,
    this.counterText,
    this.errorMaxLines,
    this.maxLength,
    this.minLines,
    this.onChanged,
    this.focusNode,
    this.initialValue,
    this.textCapitalization,
    this.maxLines,
    this.decoration,
    this.enableMic = false,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: title, required: required),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines ?? 1,
          minLines: minLines ?? 1,
          initialValue: initialValue,
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          textInputAction: textInputAction ?? TextInputAction.next,
          maxLength: maxLength,
          obscureText: obscureText ?? false,
          scrollPadding: EdgeInsets.zero,
          obscuringCharacter: obscuringCharacter ?? '●',
          autofocus: autofocus ?? false,
          autovalidateMode:
              autovalidateMode ?? AutovalidateMode.onUserInteraction,
          validator: validator,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          readOnly: readOnly ?? false,
          enabled: enabled,
          autocorrect: autocorrect ?? true,
          enableSuggestions: enableSuggestions ?? true,
          onSaved: onSaved,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            overflow: TextOverflow.clip,
          ),
          decoration: decoration ?? customDecoration(context),
        ),
      ],
    );
  }

  /// Shared theme used by text fields and dropdown menus.
  static InputDecorationTheme commonInputDecorationTheme(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(_radius);
    final borderSide = BorderSide(color: colors.border);

    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? colors.surfaceVariant : colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      isDense: true,
      constraints: const BoxConstraints(minHeight: 52),
      hintStyle: AppTextStyles.customHintStyle.copyWith(
        color: colors.textSecondary.withValues(alpha: 0.9),
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colors.error, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colors.border.withValues(alpha: 0.5)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: colors.error),
      ),
    );
  }

  Widget _fieldIcon(List<List<dynamic>> icon, Color tint) {
    return IconTheme(
      data: IconThemeData(size: _fieldIconSize, color: tint),
      child: SizedBox(
        width: _fieldIconSize,
        height: _fieldIconSize,
        child: HugeIcon(
          icon: icon,
          size: _fieldIconSize,
          color: tint,
          strokeWidth: 1.5,
        ),
      ),
    );
  }

  InputDecoration customDecoration(BuildContext context) {
    final base = TextFormWidget.commonInputDecorationTheme(context);
    final iconTint = iconColor ?? AppColors.textPrimary.withValues(alpha: 0.8);

    return InputDecoration(
      prefixText: prefixText,
      hintText: hintText ?? title,
      counterText: counterText ?? '',
      errorMaxLines: errorMaxLines ?? 2,
      helperText: helperText,
      errorText: errorText,
      alignLabelWithHint: true,
      filled: base.filled,
      fillColor: base.fillColor,
      contentPadding: base.contentPadding,
      isDense: base.isDense,
      suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: _fieldIcon(prefixIcon!, iconTint),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minHeight: 30, minWidth: 36),
      suffixIcon: getSuffix(controller, context),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 11,
        fontWeight: FontWeight.normal,
      ),
      hintStyle: base.hintStyle,
      border: base.border,
      enabledBorder: base.enabledBorder,
      focusedBorder: base.focusedBorder,
      focusedErrorBorder: base.focusedErrorBorder,
      disabledBorder: base.disabledBorder,
      errorBorder: base.errorBorder,
    );
  }

  Widget? getSuffix(TextEditingController? ctrl, BuildContext context) {
    final iconTint = iconColor ?? AppColors.textPrimary.withValues(alpha: 0.75);

    if (suffixIconTrue == true) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          height: 28,
          width: 28,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: _fieldIcon(suffixIcon!, iconTint),
            onPressed: suffixIconOnPressed,
          ),
        ),
      );
    }
    if (enableMic == true) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: MicIconWidget(
          onSubmit: (value) {
            ctrl?.text = value;
          },
        ),
      );
    }
    return null;
  }
}
