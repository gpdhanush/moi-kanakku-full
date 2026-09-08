import 'package:flutter/material.dart';

/// A small widget that renders the title of a form field along with an
/// optional asterisk when the field is required.  Both text inputs and
/// dropdowns use the same styling so we keep it in one place.
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const FieldLabel({super.key, required this.text, required this.required});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        text: text,
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ]
            : [],
      ),
    );
  }
}
