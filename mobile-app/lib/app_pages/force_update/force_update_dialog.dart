import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_pages/force_update/rotating_settings_icon.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_global/play_store_launcher.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class ForceUpdateDialog {
  static Future<void> show(
    BuildContext context, {
    required String currentVersion,
    required String minVersion,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              FlutterExitApp.exitApp();
            }
          },
          child: _ForceUpdateDialogBody(
            currentVersion: currentVersion,
            minVersion: minVersion,
          ),
        );
      },
    );
  }
}

class _ForceUpdateDialogBody extends StatelessWidget {
  final String currentVersion;
  final String minVersion;

  const _ForceUpdateDialogBody({
    required this.currentVersion,
    required this.minVersion,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotatingSettingsIcon(
              color: colorScheme.primary,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 18),
            Text(
              languageProvider.tr('forceUpdate.title'),
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              languageProvider.tr('forceUpdate.description'),
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.tr('forceUpdate.whatsNewTitle'),
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    languageProvider.tr('forceUpdate.whatsNew'),
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildVersionRow(
                    label: languageProvider.tr('forceUpdate.currentVersion'),
                    value: currentVersion,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildVersionRow(
                    label: languageProvider.tr('forceUpdate.requiredVersion'),
                    value: minVersion,
                    colorScheme: colorScheme,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: openAppPlayStoreListing,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 20,
                  strokeWidth: 1.8,
                ),
                label: Text(languageProvider.tr('forceUpdate.updateApp')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: FlutterExitApp.exitApp,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedLogout01,
                  size: 20,
                  strokeWidth: 1.8,
                ),
                label: Text(languageProvider.tr('forceUpdate.exitApp')),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.label.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}
