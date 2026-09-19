import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_services/app_alert_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/moi_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppAlertData {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? videoUrl;
  final String? ctaLabel;
  final String? ctaUrl;

  const AppAlertData({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.videoUrl,
    this.ctaLabel,
    this.ctaUrl,
  });

  factory AppAlertData.fromJson(Map<String, dynamic> json) {
    return AppAlertData(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: (json['content'] ?? json['body'])?.toString() ?? '',
      imageUrl: _nullableString(json['imageUrl'] ?? json['image_url']),
      videoUrl: _nullableString(json['videoUrl'] ?? json['video_url']),
      ctaLabel: _nullableString(json['ctaLabel'] ?? json['cta_label']),
      ctaUrl: _nullableString(json['ctaUrl'] ?? json['cta_url']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }
}

class AppAlertDialog {
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final response = await AppAlertServices().getActiveAlert();
      if (response == null || response['responseType'] != 'S') return;

      final value = response['responseValue'];
      if (value is! Map) return;

      final alert = AppAlertData.fromJson(Map<String, dynamic>.from(value));
      if (alert.id.isEmpty || alert.title.isEmpty) return;
      if (!context.mounted) return;

      await show(context, alert: alert);
    } catch (e) {
      debugPrint('App alert check failed: $e');
    }
  }

  static Future<void> show(
    BuildContext context, {
    required AppAlertData alert,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _AppAlertDialogBody(alert: alert),
    );
  }
}

class _AppAlertDialogBody extends StatefulWidget {
  final AppAlertData alert;

  const _AppAlertDialogBody({required this.alert});

  @override
  State<_AppAlertDialogBody> createState() => _AppAlertDialogBodyState();
}

class _AppAlertDialogBodyState extends State<_AppAlertDialogBody> {
  final AppAlertServices _services = AppAlertServices();
  bool _busy = false;

  String _resolveMediaUrl(String? path) {
    final value = path?.trim() ?? '';
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    return '$appImageUrl/${value.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Future<void> _submit(String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _services.recordAction(
        alertId: widget.alert.id,
        action: action,
        remindHours: action == 'remind_later' ? 24 : null,
      );
    } catch (e) {
      debugPrint('App alert action failed: $e');
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _openUrl(String? rawUrl) async {
    final url = _resolveMediaUrl(rawUrl);
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final language = context.read<LanguageProvider>();
    final imageUrl = _resolveMediaUrl(widget.alert.imageUrl);
    final hasVideo = (widget.alert.videoUrl ?? '').trim().isNotEmpty;
    final hasCta = (widget.alert.ctaUrl ?? '').trim().isNotEmpty;
    final ctaLabel = (widget.alert.ctaLabel ?? '').trim().isNotEmpty
        ? widget.alert.ctaLabel!.trim()
        : language.tr('appAlert.learnMore');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedNotification01,
                    size: 22,
                    color: colorScheme.primary,
                    strokeWidth: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.alert.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.alert.content,
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
                if (imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: AppRadius.mdAll,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: MoiNetworkImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, error, stackTrace) => Container(
                          color: colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedImage01,
                            size: 28,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasVideo) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _openUrl(widget.alert.videoUrl),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPlayCircle,
                        size: 18,
                        strokeWidth: 1.8,
                      ),
                      label: Text(language.tr('appAlert.watchVideo')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasCta) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _openUrl(widget.alert.ctaUrl),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(ctaLabel),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : () => _submit('dont_show'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(language.tr('appAlert.dontShowAgain')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _submit('remind_later'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(language.tr('appAlert.remindLater')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
