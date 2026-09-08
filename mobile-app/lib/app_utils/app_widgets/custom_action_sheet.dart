import 'package:adaptive_action_sheet/adaptive_action_sheet.dart';
import 'package:flutter/material.dart';

/// Reusable action sheet item model
class ActionSheetItem {
  final IconData icon;
  final String title;
  final Color color;
  final Future<void> Function(BuildContext) onPressed;

  ActionSheetItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onPressed,
  });
}

/// Show custom styled action sheet with consistent design
void showCustomActionSheet({
  required BuildContext context,
  required String title,
  required List<ActionSheetItem> actions,
  Color? titleColor,
}) {
  showAdaptiveActionSheet(
    context: context,
    androidBorderRadius: 10,
    actions: actions
        .map(
          (item) => _buildActionSheetItem(
            context: context,
            icon: item.icon,
            title: item.title,
            color: item.color,
            onPressed: item.onPressed,
          ),
        )
        .toList(),
  );
}

/// Helper method to build individual action sheet items
BottomSheetAction _buildActionSheetItem({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Color color,
  required Future<void> Function(BuildContext) onPressed,
}) {
  return BottomSheetAction(
    leading: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
    title: Text(
      title,
      style: TextStyle(
        fontFamily: "appFontFamily",
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: color == Colors.redAccent ? color : Colors.black87,
      ),
    ),
    onPressed: onPressed,
  );
}
