import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_themes/app_custom_themes.dart';

import 'mic_icon_widget.dart';
import 'field_label.dart';

/// A custom text form field widget with optional microphone input
class TextFormWidget extends StatelessWidget {
  final String title;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
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
  final IconData? suffixIcon;
  final String? suffixText;
  final String? prefixText;
  final VoidCallback? suffixIconOnPressed;
  final String? helperText;
  final String? errorText;
  final TextStyle? helperStyle;
  final bool? obscureText;
  final bool? enabled;
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
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // label for the field (shared with dropdown)
        FieldLabel(text: title, required: required),
        const SizedBox(height: 4),
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
          obscuringCharacter: obscuringCharacter ?? '*',
          autofocus: autofocus ?? false,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: validator,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          readOnly: readOnly ?? false,
          enabled: enabled,
          onSaved: onSaved,
          onTap: onTap,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            overflow: TextOverflow.clip,
            fontFamily: "englishFont",
            // fontFamily: theme.textTheme.bodySmall?.fontFamily,
          ),
          decoration: decoration ?? customDecoration(context),
        ),
      ],
    );
  }

  /// Returns a custom decoration for the text form field
  /// Shared theme used by text fields and dropdown menus so they look consistent.
  ///
  /// This method centralizes the `InputDecorationTheme` properties that both
  /// widgets rely on.  When the design needs tweaking, update this helper and
  /// both widgets will follow.
  static InputDecorationTheme commonInputDecorationTheme(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
      isDense: true,
      constraints: const BoxConstraints(minHeight: 48),
      hintStyle: AppTextStyles.customHintStyle,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  InputDecoration customDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final base = TextFormWidget.commonInputDecorationTheme(context);

    return InputDecoration(
      prefixText: prefixText,
      hintText: hintText ?? title,
      counterText: counterText ?? '',
      errorMaxLines: errorMaxLines ?? 1,
      helperText: helperText,
      alignLabelWithHint: true,
      filled: base.filled,
      fillColor: base.fillColor,
      contentPadding: base.contentPadding,
      isDense: base.isDense,
      suffixIconConstraints: const BoxConstraints(minWidth: 5, minHeight: 2),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: colorScheme.primary)
          : null,
      prefixIconConstraints: const BoxConstraints(minHeight: 10, minWidth: 40),
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

  /// Returns the appropriate suffix widget for the text form field
  Widget? getSuffix(TextEditingController? ctrl, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (suffixIconTrue == true) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          height: 25,
          width: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            icon: Icon(suffixIcon, size: 22, color: colorScheme.primary),
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
