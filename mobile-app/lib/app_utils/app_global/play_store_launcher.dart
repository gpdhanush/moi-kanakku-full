import 'dart:io' show Platform;

import 'package:moi/app_configs/app_variables.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openAppPlayStoreListing() async {
  final packageId = appPackageName;

  if (Platform.isAndroid) {
    final marketUri = Uri.parse('market://details?id=$packageId');
    try {
      final openedInPlayStore = await launchUrl(
        marketUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (openedInPlayStore) return;
    } catch (_) {}
  }

  final playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$packageId',
  );

  await launchUrl(
    playStoreUri,
    mode: LaunchMode.externalNonBrowserApplication,
  );
}
