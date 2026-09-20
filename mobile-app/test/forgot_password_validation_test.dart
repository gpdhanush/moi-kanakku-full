import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_pages/users/forgot_password/forgot_password.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('forgot password email field does not validate on first tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: const MaterialApp(home: ForgotPassword()),
      ),
    );

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.autovalidateMode, AutovalidateMode.disabled);
  });
}
