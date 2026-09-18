import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_pages/force_update/rotating_settings_icon.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

/// Soft, premium upgrade prompt aligned with [ForceUpdateDialog].
class ModernUpgradeAlert extends UpgradeAlert {
  ModernUpgradeAlert({
    super.key,
    required Upgrader upgrader,
    super.child,
    super.shouldPopScope,
    super.showIgnore = false,
    super.showLater = false,
    super.showReleaseNotes = true,
    super.barrierDismissible = false,
    super.onIgnore,
    super.onLater,
    super.onUpdate,
  }) : super(
          upgrader: upgrader,
          dialogStyle: UpgradeDialogStyle.material,
        );

  @override
  UpgradeAlertState createState() => _ModernUpgradeAlertState();
}

class _ModernUpgradeAlertState extends UpgradeAlertState {
  @override
  Widget alertDialog(
    Key? key,
    String title,
    String message,
    String? releaseNotes,
    BuildContext context,
    bool cupertino,
    UpgraderMessages messages,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();
    final isBlocked = widget.upgrader.blocked();
    final showIgnore = isBlocked ? false : widget.showIgnore;
    final showLater = isBlocked ? false : widget.showLater;
    final prompt = widget.showPrompt
        ? (messages.message(UpgraderMessage.prompt) ?? '')
        : '';
    final updateLabel =
        messages.message(UpgraderMessage.buttonTitleUpdate) ?? 'Update';
    final laterLabel =
        messages.message(UpgraderMessage.buttonTitleLater) ?? 'Later';
    final ignoreLabel =
        messages.message(UpgraderMessage.buttonTitleIgnore) ?? 'Ignore';
    final notesLabel = languageProvider.tr('forceUpdate.whatsNewTitle');
    final fallbackWhatsNew = languageProvider.tr('forceUpdate.whatsNew');
    final notesContent =
        (releaseNotes != null && releaseNotes.trim().isNotEmpty)
            ? releaseNotes.trim()
            : fallbackWhatsNew;

    return Dialog(
      key: key,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.card,
        ),
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
                title,
                key: const Key('upgrader.dialog.title'),
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.36,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          height: 1.5,
                          color: colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      if (prompt.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          prompt,
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
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
                              notesLabel,
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notesContent,
                              style: AppTypography.body.copyWith(
                                fontSize: 13,
                                height: 1.4,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      onUserUpdated(context, !widget.upgrader.blocked()),
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload01,
                    size: 20,
                    strokeWidth: 1.8,
                  ),
                  label: Text(updateLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (showLater) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onUserLater(context, true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.28),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(laterLabel),
                  ),
                ),
              ],
              if (showIgnore) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => onUserIgnored(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                  child: Text(ignoreLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
