import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_pages/export_payment/export_payment_page.dart';
import 'package:moi/app_services/export_payment_services.dart';
import 'package:moi/app_themes/theme_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _plans = [
  ExportPlan(
    id: 'single',
    exports: 1,
    amount: 19,
    upiUri: 'upi://pay?pa=payee@bank&am=19.00&cu=INR',
  ),
  ExportPlan(
    id: 'pack5',
    exports: 5,
    amount: 49,
    upiUri: 'upi://pay?pa=payee@bank&am=49.00&cu=INR',
  ),
  ExportPlan(
    id: 'lifetime',
    exports: null,
    amount: 499,
    upiUri: 'upi://pay?pa=payee@bank&am=499.00&cu=INR',
  ),
];

ExportPaymentStatus _status(
  String status, {
  String remarks = '',
  bool lifetime = false,
}) {
  return ExportPaymentStatus(
    status: status,
    canExport: status == 'approved',
    lifetime: lifetime,
    plans: _plans,
    defaultPlanId: 'pack5',
    remainingExports: status == 'approved' ? 2 : 0,
    exportsPerPayment: 3,
    paymentConfigured: true,
    upiId: 'payee@bank',
    payeeName: 'Moi Kanakku',
    amount: 49,
    upiUri: 'upi://pay?pa=payee@bank&pn=Moi%20Kanakku&am=49.00&cu=INR',
    latestTxnId: status == 'none' ? null : '123456789012',
    latestRemarks: remarks,
  );
}

void main() {
  late ThemeProvider themeProvider;
  late LanguageProvider languageProvider;

  Future<void> pumpPage(WidgetTester tester, ExportPaymentStatus status) async {
    themeProvider = ThemeProvider();
    languageProvider = LanguageProvider();
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
        child: MaterialApp(home: ExportPaymentPage(initialStatus: status)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('parses status response from the backend', () {
    final parsed = ExportPaymentStatus.fromResponse({
      'responseType': 'S',
      'responseValue': {
        'status': 'rejected',
        'canExport': false,
        'remainingExports': 0,
        'exportsPerPayment': 3,
        'latest': {'upiTxnId': '123456789012', 'adminRemarks': 'Not found'},
        'payment': {
          'configured': true,
          'upiId': 'payee@bank',
          'payeeName': 'Moi',
          'amount': 49,
          'upiUri': 'upi://pay?pa=payee@bank',
          'defaultPlan': 'pack5',
          'plans': [
            {'id': 'single', 'exports': 1, 'amount': 19, 'upiUri': 'u1'},
            {'id': 'pack5', 'exports': 5, 'amount': 49, 'upiUri': 'u5'},
            {
              'id': 'lifetime',
              'exports': null,
              'lifetime': true,
              'amount': 499,
              'upiUri': 'ul',
            },
          ],
        },
      },
    });
    expect(parsed?.plans.map((p) => p.id), ['single', 'pack5', 'lifetime']);
    expect(parsed?.plans.last.isLifetime, isTrue);
    expect(parsed?.plans.first.exports, 1);
    expect(parsed?.defaultPlan.id, 'pack5');
    expect(parsed?.isRejected, isTrue);
    expect(parsed?.latestRemarks, 'Not found');
    expect(parsed?.amountLabel, '49');
    expect(ExportPaymentStatus.fromResponse({'responseType': 'F'}), isNull);
  });

  test('falls back to the legacy single price when no plans are sent', () {
    final parsed = ExportPaymentStatus.fromResponse({
      'responseType': 'S',
      'responseValue': {
        'status': 'none',
        'payment': {'configured': true, 'amount': 49, 'upiUri': 'legacy'},
      },
    });
    expect(parsed?.availablePlans, hasLength(1));
    expect(parsed?.defaultPlan.id, isNull);
    expect(parsed?.defaultPlan.upiUri, 'legacy');
  });

  test('accepts only 12-digit UPI transaction IDs', () {
    expect(ExportPaymentServices.txnIdPattern.hasMatch('123456789012'), isTrue);
    expect(ExportPaymentServices.txnIdPattern.hasMatch('12345678901'), isFalse);
    expect(
      ExportPaymentServices.txnIdPattern.hasMatch('12345678901A'),
      isFalse,
    );
  });

  testWidgets('unpaid user sees QR code and transaction ID validation', (
    tester,
  ) async {
    await pumpPage(tester, _status('none'));

    expect(find.byType(QrImageView), findsOneWidget);
    final submit = find.text(languageProvider.tr('exportPayment.submit'));
    await tester.scrollUntilVisible(
      submit,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.text(languageProvider.tr('exportPayment.txnInvalid')),
      findsOneWidget,
    );
  });

  testWidgets('picking a plan updates the price and the QR code', (
    tester,
  ) async {
    await pumpPage(tester, _status('none'));

    Finder qrFor(int plan) =>
        find.byKey(ValueKey<String>(_plans[plan].upiUri!));
    expect(find.text('₹ 49'), findsOneWidget);
    expect(qrFor(1), findsOneWidget);

    await tester.tap(find.text(languageProvider.tr('exportPayment.planOne')));
    await tester.pumpAndSettle();
    expect(find.text('₹ 19'), findsOneWidget);
    expect(qrFor(0), findsOneWidget);

    await tester.tap(
      find.text(languageProvider.tr('exportPayment.planLifetime')),
    );
    await tester.pumpAndSettle();
    expect(find.text('₹ 499'), findsOneWidget);
    expect(qrFor(2), findsOneWidget);
    expect(
      find.text(
        languageProvider
            .tr('exportPayment.subtitleLifetime')
            .replaceAll('{amount}', '499'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('lifetime user sees the lifetime message', (tester) async {
    await pumpPage(tester, _status('approved', lifetime: true));

    expect(
      find.text(languageProvider.tr('exportPayment.lifetimeMessage')),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('pending user sees review state without the form', (
    tester,
  ) async {
    await pumpPage(tester, _status('pending'));

    expect(
      find.text(languageProvider.tr('exportPayment.pendingTitle')),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('rejected user sees the reason and can pay again', (
    tester,
  ) async {
    await pumpPage(tester, _status('rejected', remarks: 'UTR not found'));

    expect(
      find.text(languageProvider.tr('exportPayment.rejectedTitle')),
      findsOneWidget,
    );
    expect(find.textContaining('UTR not found'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('approved user can continue to export', (tester) async {
    await pumpPage(tester, _status('approved'));

    expect(
      find.text(
        languageProvider
            .tr('exportPayment.approvedMessage')
            .replaceAll('{left}', '2')
            .replaceAll('{total}', '3'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(languageProvider.tr('exportPayment.continueExport')),
      findsOneWidget,
    );
  });

  testWidgets('uploaded QR image replaces the generated QR', (tester) async {
    const status = ExportPaymentStatus(
      status: 'none',
      canExport: false,
      paymentConfigured: true,
      upiId: '',
      payeeName: '',
      amount: 49,
      upiUri: null,
      qrImageUrl: 'https://example.com/uploads/export-payment/qr.png',
      latestTxnId: null,
      latestRemarks: '',
    );
    await pumpPage(tester, status);

    expect(find.byType(Image), findsWidgets);
    expect(find.byType(QrImageView), findsNothing);
    expect(
      find.text(languageProvider.tr('exportPayment.payWithApp')),
      findsNothing,
    );
    expect(
      find.text(languageProvider.tr('exportPayment.unavailable')),
      findsNothing,
    );
  });

  testWidgets('user who used all exports is asked to pay again', (
    tester,
  ) async {
    await pumpPage(tester, _status('exhausted'));

    expect(
      find.text(languageProvider.tr('exportPayment.exhaustedTitle')),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('{total}'), findsNothing);
  });
}
