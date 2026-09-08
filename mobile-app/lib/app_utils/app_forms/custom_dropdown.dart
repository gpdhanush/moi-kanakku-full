import 'package:flutter/material.dart';

import 'field_label.dart';
import 'mic_icon_widget.dart';
import 'text_form_widgets.dart';

/// A custom dropdown widget that allows selection from a list of entries
class CustomDropdown extends StatefulWidget {
  final List<DropdownMenuEntry<dynamic>> dropdownMenuEntries;
  final ValueChanged<dynamic>? onSelected;
  final bool required;

  /// whether filtering/searching is enabled when the menu is open
  final bool? search;

  final String title;
  final dynamic initialSelection;

  /// prefix icon to show inside the anchor, same as [TextFormWidget]
  final IconData? prefixIcon;
  final Color? iconColor;

  /// whether the dropdown arrow (the toggle button) should be displayed.
  ///
  /// Useful when the widget is the last field in a sequence and you want a
  /// cleaner look without the arrow, or when you supply your own custom
  /// trigger elsewhere.
  final bool showArrow;

  /// show a generic suffix icon to the left of the dropdown arrow
  final bool? suffixIconTrue;
  final IconData? suffixIcon;
  final VoidCallback? suffixIconOnPressed;

  /// if true a microphone icon is shown (and [onMicSubmit] is called with
  /// whatever string the microphone returns).  This is roughly analogous to
  /// the behavior in [TextFormWidget].
  final bool enableMic;
  final ValueChanged<String>? onMicSubmit;

  /// optional controller for the underlying text field. If not provided we
  /// create and dispose our own.
  final TextEditingController? controller;

  /// text shown when the current search string doesn't match any entry.
  final String notFoundText;

  const CustomDropdown({
    super.key,
    required this.dropdownMenuEntries,
    this.onSelected,
    required this.required,
    required this.title,
    this.search = false,
    this.initialSelection,
    this.prefixIcon,
    this.iconColor,
    this.suffixIconTrue,
    this.suffixIcon,
    this.suffixIconOnPressed,
    this.showArrow = false,
    this.enableMic = false,
    this.onMicSubmit,
    this.controller,
    this.notFoundText = 'Not matched',
  });

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.search == true) {
      _ctrl.addListener(_onTextChanged);
    }
    // initialize error state based on initial text
    _onTextChanged();
  }

  @override
  void dispose() {
    if (widget.search == true) {
      _ctrl.removeListener(_onTextChanged);
    }
    if (widget.controller == null) {
      _ctrl.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    final text = _ctrl.text.trim().toLowerCase();
    if (text.isEmpty || widget.search != true) {
      if (_errorText != null) {
        setState(() {
          _errorText = null;
        });
      }
      return;
    }
    final hasMatch = widget.dropdownMenuEntries.any((entry) {
      final label = entry.label.toString().toLowerCase();
      return label.contains(text);
    });
    if (!hasMatch && _errorText != widget.notFoundText) {
      setState(() {
        _errorText = widget.notFoundText;
      });
    } else if (hasMatch && _errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // label for the dropdown (shared with text field)
        FieldLabel(text: widget.title, required: widget.required),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            // Ensure every entry has a backgroundColor that highlights with
            // primary/0.1 when it becomes focused.  We perform a shallow map so
            // callers can continue to supply their own style (e.g. for icons,
            // disabled state, etc.) and we just merge our highlight logic.
            final Color highlightColor = theme.colorScheme.primary.withValues(
              alpha: 0.3,
            );

            final styledEntries = widget.dropdownMenuEntries.map((entry) {
              final ButtonStyle? baseStyle = entry.style;

              final WidgetStateProperty<Color?> highlightBg =
                  WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.focused)) {
                      return highlightColor;
                    }
                    return baseStyle?.backgroundColor?.resolve(states);
                  });

              final ButtonStyle mergedStyle = (baseStyle ?? const ButtonStyle())
                  .merge(ButtonStyle(backgroundColor: highlightBg));

              return DropdownMenuEntry<dynamic>(
                value: entry.value,
                label: entry.label,
                labelWidget: entry.labelWidget,
                leadingIcon: entry.leadingIcon,
                trailingIcon: entry.trailingIcon,
                enabled: entry.enabled,
                style: mergedStyle,
              );
            }).toList();

            return DropdownMenu(
              width: constraints.maxWidth,
              expandedInsets: EdgeInsets.zero,
              menuHeight: MediaQuery.of(context).size.width / 1.5,
              dropdownMenuEntries: styledEntries,
              enabled: true,
              onSelected: widget.onSelected,
              hintText: null,
              initialSelection: widget.initialSelection,
              enableFilter: widget.search ?? false,
              enableSearch: widget.search ?? false,
              requestFocusOnTap: widget.search ?? false,
              controller: _ctrl,
              leadingIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: widget.iconColor ?? theme.colorScheme.primary,
                    )
                  : null,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.clip,
                fontFamily: theme.textTheme.bodyMedium?.fontFamily,
              ),
              inputDecorationTheme: TextFormWidget.commonInputDecorationTheme(
                context,
              ),
              decorationBuilder: (context, controller) {
                // start with something similar to the default implementation
                InputDecoration decoration = InputDecoration(
                  // labelText: title,
                  hintText: widget.title,
                  helperText: null,
                  errorText: null,
                  isDense: true,
                  // contentPadding: const EdgeInsets.symmetric(
                  //   horizontal: 1,
                  //   vertical: 1,
                  // ),
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: widget.iconColor ?? theme.colorScheme.primary,
                        )
                      : null,
                );

                // build any extra icons that should appear before the arrow
                final List<Widget> extraIcons = [];
                if (widget.suffixIconTrue == true &&
                    widget.suffixIcon != null) {
                  extraIcons.add(
                    IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.adaptivePlatformDensity,
                      icon: Icon(
                        widget.suffixIcon!,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: widget.suffixIconOnPressed,
                    ),
                  );
                }
                if (widget.enableMic == true) {
                  extraIcons.add(
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: MicIconWidget(
                        onSubmit: (value) {
                          if (widget.onMicSubmit != null) {
                            widget.onMicSubmit!(value);
                          }
                        },
                      ),
                    ),
                  );
                }
                if (widget.search == true) {
                  // additional padding already added earlier when building
                  // icon for search, so nothing to do here
                }

                // arrow icon that toggles the menu (can be hidden)
                if (widget.showArrow) {
                  Widget arrow = IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    icon: Icon(
                      controller.isOpen
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                    ),
                    onPressed: () {
                      // open/close regardless of enabled state; DropdownMenu
                      // will handle disabling internally
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                  );
                  extraIcons.add(arrow);
                }

                if (extraIcons.isNotEmpty) {
                  decoration = decoration.copyWith(
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: extraIcons,
                    ),
                  );
                }

                // display error text if our controller flagged a missing match
                if (_errorText != null) {
                  decoration = decoration.copyWith(errorText: _errorText);
                }

                return decoration.applyDefaults(
                  TextFormWidget.commonInputDecorationTheme(context),
                );
              },
              menuStyle: MenuStyle(
                backgroundColor: const WidgetStatePropertyAll(Colors.white),
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                elevation: const WidgetStatePropertyAll(15),
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
            );
          },
        ),
      ],
    );
  }
}
