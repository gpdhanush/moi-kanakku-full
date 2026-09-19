import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_pages/settings_page/settings_menus_panel.dart';
import 'package:moi/app_themes/theme_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('dark mode toggle is exposed in More settings', (tester) async {
    final themeProvider = ThemeProvider();
    final languageProvider = LanguageProvider();

    await languageProvider.ensureReady();
    await themeProvider.ensureLoaded();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: languageProvider),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsMenusPanel())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dark mode'), findsOneWidget);

    final switches = tester.widgetList<Switch>(find.byType(Switch));
    expect(switches.length, greaterThanOrEqualTo(2));

    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();

    expect(themeProvider.isDarkMode, isTrue);
  });
}
