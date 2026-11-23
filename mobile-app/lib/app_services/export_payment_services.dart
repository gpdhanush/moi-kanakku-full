import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/connection.dart';

String _amountLabel(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

/// A paid PDF export plan: single (1 export, ₹19), pack5 (5 exports, ₹49)
/// or lifetime (unlimited, ₹499). Prices come from the backend.
class ExportPlan {
  /// Sent back on submit; null for the legacy single-price setup.
  final String? id;

  /// PDF exports the plan buys; null means unlimited (lifetime).
  final int? exports;
  final double amount;
  final String? upiUri;

  const ExportPlan({
    required this.id,
    required this.exports,
    required this.amount,
    this.upiUri,
  });

  bool get isLifetime => exports == null;
  String get amountLabel => _amountLabel(amount);

  static ExportPlan? fromJson(dynamic json) {
    if (json is! Map) return null;
    final id = json['id']?.toString().trim() ?? '';
    final amount = double.tryParse(json['amount']?.toString() ?? '');
    if (id.isEmpty || amount == null || amount <= 0) return null;
    final lifetime = json['lifetime'] == true || json['exports'] == null;
    return ExportPlan(
      id: id,
      exports: lifetime ? null : int.tryParse(json['exports'].toString()),
      amount: amount,
      upiUri: ExportPaymentStatus._nonEmpty(json['upiUri']),
    );
  }
}

/// Paid PDF export: payee details, the user's payment status and submission.
class ExportPaymentStatus {
  /// none | pending | approved | rejected | exhausted (paid exports used up)
  final String status;
  final bool canExport;

  /// The user has an approved lifetime plan: unlimited exports.
  final bool lifetime;

  /// Paid PDF exports the user can still make.
  final int remainingExports;

  /// Exports the last approved pack granted (for "{left} of {total}").
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

  /// Plans the user can pay for, in display order.
  final List<ExportPlan> plans;

  /// Plan id preselected in the picker.
  final String? defaultPlanId;

  const ExportPaymentStatus({
    required this.status,
    required this.canExport,
    this.lifetime = false,
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
    this.plans = const [],
    this.defaultPlanId,
  });

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isExhausted => status == 'exhausted';

  String get amountLabel => _amountLabel(amount);

  /// Plans to offer. Falls back to the legacy single price (no plan id) when
  /// the backend sends no plans.
  List<ExportPlan> get availablePlans => plans.isNotEmpty
      ? plans
      : [
          ExportPlan(
            id: null,
            exports: exportsPerPayment,
            amount: amount,
            upiUri: upiUri,
          ),
        ];

  ExportPlan get defaultPlan {
    final options = availablePlans;
    return options.firstWhere(
      (plan) => plan.id == defaultPlanId,
      orElse: () => options.first,
    );
  }

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
      lifetime: value['lifetime'] == true,
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
      plans: payment['plans'] is List
          ? (payment['plans'] as List)
                .map(ExportPlan.fromJson)
                .whereType<ExportPlan>()
                .toList(growable: false)
          : const [],
      defaultPlanId: _nonEmpty(payment['defaultPlan']),
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
    String? planId,
    bool showLoading = true,
  }) async {
    final response = await connection.postData(
      '$appBaseUri/export-payments/submit',
      {'upiTxnId': upiTxnId, 'plan': ?planId},
      useToken: true,
      showLoading: showLoading,
    );
    return ExportPaymentStatus.fromResponse(response);
  }
}
