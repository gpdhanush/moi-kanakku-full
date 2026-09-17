import 'package:flutter/material.dart';
import 'package:moi/app_utils/app_widgets/moi_app_header.dart';

/// Shared modern app bar for Moi Received / Given flow screens.
/// Thin wrapper around [MoiAppHeader] with accent strip + back button.
class MoiFlowAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color accent;
  final VoidCallback onBack;
  final String? subtitle;
  final List<Widget>? actions;

  const MoiFlowAppHeader({
    super.key,
    required this.title,
    required this.accent,
    required this.onBack,
    this.subtitle,
    this.actions,
  });

  @override
  Size get preferredSize {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    return Size.fromHeight(hasSubtitle ? 84 : 72);
  }

  @override
  Widget build(BuildContext context) {
    return MoiAppHeader(
      title: title,
      subtitle: subtitle,
      showBack: true,
      onBack: onBack,
      actions: actions,
      accent: accent,
    );
  }
}
