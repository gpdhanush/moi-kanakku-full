import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_utils/app_global/app_button_widget.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class AlertServices {
  BuildContext? get _ctx => navigatorKey.currentState?.overlay?.context;

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
    _showToast(
      message,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
    );
  }

  void successToast(String message) {
    final context = _ctx;
    _showToast(
      message,
      backgroundColor: context != null
          ? Theme.of(context).colorScheme.primary
          : Colors.blue,
      textColor: Colors.white,
    );
  }

  void toast(String message) {
    _showToast(
      message,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  void _showToast(
    String message, {
    required Color backgroundColor,
    required Color textColor,
  }) {
    // Don't show toast if message is empty, null, or contains "no record"/"no data"
    final trimmedMessage = message.trim().toLowerCase();
    if (trimmedMessage.isEmpty ||
        trimmedMessage.contains('no record') ||
        trimmedMessage.contains('no detail') ||
        trimmedMessage.contains('எதுவும் கிடைக்கவில்லை.') ||
        trimmedMessage.contains('கிடைக்கவில்லை')) {
      return;
    }

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 12.0,
      timeInSecForIosWeb: 4,
    );
  }

  Future<bool?> confirmAlert(BuildContext context, String content) {
    ThemeData theme = Theme.of(context);
    final languageProvider = context.read<LanguageProvider>();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            title: Text(
              languageProvider.tr('common.confirm'),
              style: theme.textTheme.bodyLarge?.copyWith(
                // fontSize: 22,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                fontFamily: "appFontFamily",
              ),
            ),
            content: Text(
              content,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: "appFontFamily",
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  languageProvider.tr('common.no'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    // fontSize: 16,
                    color: Colors.redAccent,
                    fontFamily: "appFontFamily",
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),

              // TextButton(
              //   onPressed: () {
              //     Navigator.of(context).pop(true);
              //   },
              //   child: Text(
              //     "ஆம்",
              //     style: theme.textTheme.bodySmall?.copyWith(
              //       // fontSize: 16,
              //       fontFamily: "appFontFamily",
              //       fontWeight: FontWeight.bold,
              //       decoration: TextDecoration.none,
              //       color: theme.primaryColor,
              //     ),
              //   ),
              // ),
              AppButton(
                width: 100,
                title: languageProvider.tr('common.yes'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
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
                  color: Colors.black.withValues(alpha: 0.18),
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
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.exit_to_app_rounded,
                    color: colorScheme.primary,
                    size: 29,
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
