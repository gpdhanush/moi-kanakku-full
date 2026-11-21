import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_pages/more/more_page.dart';
import 'package:moi/app_themes/theme_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Export opens admin contact options instead of exporting', (
    tester,
  ) async {
    final themeProvider = ThemeProvider();
    final languageProvider = LanguageProvider();

    await tester.runAsync(() async {
      await languageProvider.ensureReady();
      await themeProvider.ensureLoaded();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
        ],
        child: const MaterialApp(home: MorePage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(languageProvider.tr('more.export')));
    await tester.pumpAndSettle();

    expect(find.text(languageProvider.tr('more.contactAdmin')), findsOneWidget);
    expect(
      find.text(languageProvider.tr('more.exportSupportMessage')),
      findsOneWidget,
    );
    expect(find.text(languageProvider.tr('contacts.call')), findsOneWidget);
    expect(find.text(languageProvider.tr('contacts.whatsapp')), findsOneWidget);
    expect(find.text(languageProvider.tr('common.cancel')), findsOneWidget);
  });
}
