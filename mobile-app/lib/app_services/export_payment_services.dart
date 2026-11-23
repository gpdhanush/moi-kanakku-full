import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/connection.dart';

/// Paid PDF export: payee details, the user's payment status and submission.
class ExportPaymentStatus {
  /// none | pending | approved | rejected | exhausted (paid exports used up)
  final String status;
  final bool canExport;

  /// Paid PDF exports the user can still make.
  final int remainingExports;

  /// Exports one approved payment buys (3 by default).
  final int exportsPerPayment;
  final bool paymentConfigured;
  final String upiId;
  final String payeeName;
  final double amount;
  final String? upiUri;

  /// Admin-uploaded QR image; shown instead of the generated QR when set.
  final String? qrImageUrl;
  final String? latestTxnId;
  final String latestRemarks;

  const ExportPaymentStatus({
    required this.status,
    required this.canExport,
    this.remainingExports = 0,
    this.exportsPerPayment = 3,
    required this.paymentConfigured,
    required this.upiId,
    required this.payeeName,
    required this.amount,
    required this.upiUri,
    this.qrImageUrl,
    required this.latestTxnId,
    required this.latestRemarks,
  });

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isExhausted => status == 'exhausted';

  String get amountLabel => amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toStringAsFixed(2);

  static String? _nonEmpty(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static ExportPaymentStatus? fromResponse(dynamic response) {
    if (response is! Map || response['responseType'] != 'S') return null;
    final value = response['responseValue'];
    if (value is! Map) return null;
    final payment = value['payment'] is Map ? value['payment'] as Map : {};
    final latest = value['latest'] is Map ? value['latest'] as Map : null;
    return ExportPaymentStatus(
      status: value['status']?.toString() ?? 'none',
      canExport: value['canExport'] == true,
      remainingExports:
          int.tryParse(value['remainingExports']?.toString() ?? '') ?? 0,
      exportsPerPayment:
          int.tryParse(value['exportsPerPayment']?.toString() ?? '') ?? 3,
      paymentConfigured: payment['configured'] == true,
      upiId: payment['upiId']?.toString() ?? '',
      payeeName: payment['payeeName']?.toString() ?? '',
      amount: double.tryParse(payment['amount']?.toString() ?? '') ?? 49,
      upiUri: _nonEmpty(payment['upiUri']),
      qrImageUrl: _nonEmpty(payment['qrImageUrl']),
      latestTxnId: latest?['upiTxnId']?.toString(),
      latestRemarks: latest?['adminRemarks']?.toString() ?? '',
    );
  }
}

class ExportPaymentServices {
  final Connection connection = Connection();

  /// UPI reference numbers (UTR) are 12 digits.
  static final RegExp txnIdPattern = RegExp(r'^\d{12}$');

  Future<ExportPaymentStatus?> getStatus({bool showLoading = true}) async {
    final response = await connection.getData(
      '$appBaseUri/export-payments/status',
      useToken: true,
      showLoading: showLoading,
    );
    return ExportPaymentStatus.fromResponse(response);
  }

  /// Spends one paid export. Returns null (server message toasted) when none are left.
  Future<ExportPaymentStatus?> consume({bool showLoading = false}) async {
    final response = await connection.postData(
      '$appBaseUri/export-payments/consume',
      const <String, dynamic>{},
      useToken: true,
      showLoading: showLoading,
    );
    return ExportPaymentStatus.fromResponse(response);
  }

  Future<ExportPaymentStatus?> submit(
    String upiTxnId, {
    bool showLoading = true,
  }) async {
    final response = await connection.postData(
      '$appBaseUri/export-payments/submit',
      {'upiTxnId': upiTxnId},
      useToken: true,
      showLoading: showLoading,
    );
    return ExportPaymentStatus.fromResponse(response);
  }
}
