import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

class AlertServices {
  BuildContext? get _ctx =>
      navigatorKey.currentContext ?? navigatorKey.currentState?.overlay?.context;

  String _tr(String key, String fallback) {
    final context = _ctx;
    if (context == null) return fallback;
    return context.read<LanguageProvider>().tr(key);
  }

  Future<void> showLoading([String? title, String? successMessage]) async {
    final context = _ctx;
    if (context != null) {
      ThemeData theme = Theme.of(context);
      final colorScheme = Theme.of(context).colorScheme;

      EasyLoading.instance
        ..loadingStyle = EasyLoadingStyle.custom
        ..indicatorType = EasyLoadingIndicatorType.pulse
        ..indicatorColor = colorScheme.primary
        ..progressColor = colorScheme.primary
        ..backgroundColor = Colors.white
        ..textColor = colorScheme.primary
        ..toastPosition = EasyLoadingToastPosition.center
        ..animationStyle = EasyLoadingAnimationStyle.scale
        ..dismissOnTap = false
        ..userInteractions = false
        ..maskType = EasyLoadingMaskType.black
        ..textStyle = theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        );
    }

    await EasyLoading.show(
      status: title ?? _tr('common.loading', 'Loading...'),
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );
  }

  /// Hides the loading indicator and optionally shows a success message
  Future<void> hideLoading([String? successMessage]) async {
    await EasyLoading.dismiss();
    if (successMessage != null) {
      successToast(successMessage);
    }
  }

  void errorToast(String message) {
    _showToast(message);
  }

  void successToast(String message) {
    _showToast(message);
  }

  void toast(String message) {
    _showToast(message);
  }

  void _showToast(String message) {
    // Don't show toast if message is empty, null, or contains "no record"/"no data"
    final trimmedMessage = message.trim().toLowerCase();
    if (trimmedMessage.isEmpty ||
        trimmedMessage.contains('no record') ||
        trimmedMessage.contains('no detail') ||
        trimmedMessage.contains('எதுவும் கிடைக்கவில்லை.') ||
        trimmedMessage.contains('கிடைக்கவில்லை')) {
      return;
    }

    final context = _ctx;
    if (context == null || !context.mounted) return;

    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.maybeOf(context) ??
        (navigatorKey.currentState != null
            ? ScaffoldMessenger.maybeOf(navigatorKey.currentState!.context)
            : null);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<bool?> confirmAlert(BuildContext context, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageProvider = context.read<LanguageProvider>();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedInformationCircle,
                    size: 30,
                    color: colorScheme.primary,
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  languageProvider.tr('common.confirm'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(languageProvider.tr('common.no')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(languageProvider.tr('common.yes')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> confirmExitSheet(BuildContext context, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(minHeight: 300),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout01,
                    size: 20,
                    color: colorScheme.primary,
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  languageProvider.tr('common.confirm'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: colorScheme.outline.withValues(alpha: 0.35),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(languageProvider.tr('common.no')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(languageProvider.tr('common.yes')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
