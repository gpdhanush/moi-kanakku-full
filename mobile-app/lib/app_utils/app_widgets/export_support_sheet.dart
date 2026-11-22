import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'package:moi/app_utils/app_global/alert_services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:moi/app_configs/app_logs.dart';

/// Shows the support options used instead of generating an export PDF.
Future<void> showExportSupportSheet({
  required BuildContext context,
  required LanguageProvider languageProvider,
}) {
  return showMoiActionSheet(
    context: context,
    title: languageProvider.tr('more.contactAdmin'),
    subtitle: languageProvider.tr('more.exportSupportMessage'),
    actions: [
      ActionSheetItem(
        hugeIcon: HugeIcons.strokeRoundedCall,
        title: languageProvider.tr('contacts.call'),
        onPressed: (sheetContext) async {
          Navigator.of(sheetContext).pop();
          await _launchContactAction(
            context,
            Uri(scheme: 'tel', path: '+917845456609'),
            languageProvider.tr('contacts.callUnavailable'),
          );
        },
      ),
      ActionSheetItem(
        hugeIcon: HugeIcons.strokeRoundedWhatsapp,
        title: languageProvider.tr('contacts.whatsapp'),
        onPressed: (sheetContext) async {
          Navigator.of(sheetContext).pop();
          await _launchContactAction(
            context,
            Uri(
              scheme: 'whatsapp',
              host: 'send',
              queryParameters: {
                'phone': '917845456609',
                'text': languageProvider.tr('contacts.whatsappMessage'),
              },
            ),
            languageProvider.tr('contacts.whatsappNotInstalled'),
          );
        },
      ),
      ActionSheetItem(
        title: languageProvider.tr('common.cancel'),
        isCancel: true,
        onPressed: (sheetContext) async {
          Navigator.of(sheetContext).pop();
        },
      ),
    ],
  );
}

Future<void> _launchContactAction(
  BuildContext context,
  Uri uri,
  String failureMessage,
) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AlertServices().errorToast(failureMessage);
    }
  } on PlatformException catch (error, stackTrace) {
    printDirect('Admin contact action failed: ${error.code}');
    debugPrintStack(stackTrace: stackTrace);
    if (context.mounted) {
      AlertServices().errorToast(failureMessage);
    }
  }
}
