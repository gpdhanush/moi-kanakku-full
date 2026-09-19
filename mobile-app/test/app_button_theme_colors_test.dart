import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_utils/app_global/app_button_widget.dart';

void main() {
  testWidgets('AppButton text stays charcoal on lime in light mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: AppButton(title: 'Continue', onPressed: () {}),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Continue'));
    expect(text.style?.color, AppColors.charcoal);
  });

  testWidgets('AppButton text stays charcoal on lime in dark mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: AppButton(title: 'Continue', onPressed: () {}),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Continue'));
    expect(text.style?.color, AppColors.charcoal);
  });
}
