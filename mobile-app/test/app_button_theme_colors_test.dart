import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_themes/app_themes.dart';
import 'package:moi/app_utils/app_global/app_button_widget.dart';

void main() {
  testWidgets('AppButton has accessible light-mode button contrast', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: Scaffold(
          body: Center(
            child: AppButton(title: 'Continue', onPressed: () {}),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Continue'));
    expect(text.style?.color, AppColors.white);
    expect(
      (AppColors.white.computeLuminance() + 0.05) /
          (AppColors.lightButtonPrimary.computeLuminance() + 0.05),
      greaterThanOrEqualTo(4.5),
    );
    final theme = AppThemes.lightTheme;
    expect(
      theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.lightButtonPrimary,
    );
    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.lightButtonPrimary,
    );
  });

  testWidgets('AppButton retains dark-mode styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.darkTheme,
        home: Scaffold(
          body: Center(
            child: AppButton(title: 'Continue', onPressed: () {}),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Continue'));
    expect(text.style?.color, AppColors.charcoal);
    final theme = AppThemes.darkTheme;
    expect(
      theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.primary,
    );
    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
      AppColors.primary,
    );
  });
}
