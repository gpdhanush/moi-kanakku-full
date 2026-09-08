import 'package:flutter/material.dart';

class DrawerWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final GestureTapCallback onTab;
  final bool isLogout;

  const DrawerWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTab,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isLogout ? Colors.redAccent : colorScheme.primary;
    final textColor = isLogout ? Colors.redAccent : colorScheme.onSurface;
    final accentColor = isLogout ? Colors.redAccent : colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTab,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
