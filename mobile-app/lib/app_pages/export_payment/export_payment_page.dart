import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/export_payment_services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thrown by [useExportCredit] when no paid exports are left; the server's
/// message has already been shown, so callers just stop the export quietly.
class ExportLimitReachedException implements Exception {
  const ExportLimitReachedException();
}

/// Returns true when the signed-in user has paid PDF exports left.
///
/// Each approved payment buys a fixed number of exports (3 by default). When
/// none are left, opens [ExportPaymentPage] (QR code, transaction ID, review
/// status) and returns true only if the user leaves it with exports available.
Future<bool> ensureExportUnlocked(BuildContext context) async {
  final status = await ExportPaymentServices().getStatus();
  if (status?.canExport == true) return true;
  if (!context.mounted) return false;

  final unlocked = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => ExportPaymentPage(initialStatus: status)),
  );
  return unlocked == true;
}

/// Spends one paid export. Call after the PDF is built, before it is saved or
/// shared. Throws [ExportLimitReachedException] when none are left.
Future<void> useExportCredit() async {
  final status = await ExportPaymentServices().consume();
  if (status == null) throw const ExportLimitReachedException();
  final context = navigatorKey.currentState?.overlay?.context;
  final template =
      context?.read<LanguageProvider>().tr('exportPayment.exportsLeftToast') ??
      'PDF exports left: {left} of {total}';
  AlertServices().successToast(
    template
        .replaceAll('{left}', '${status.remainingExports}')
        .replaceAll('{total}', '${status.exportsPerPayment}'),
  );
}

class ExportPaymentPage extends StatefulWidget {
  final ExportPaymentStatus? initialStatus;

  const ExportPaymentPage({super.key, this.initialStatus});

  @override
  State<ExportPaymentPage> createState() => _ExportPaymentPageState();
}

class _ExportPaymentPageState extends State<ExportPaymentPage> {
  final ExportPaymentServices _services = ExportPaymentServices();
  final AlertServices _alerts = AlertServices();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txnController = TextEditingController();

  ExportPaymentStatus? _status;
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    if (_status == null) _refresh();
  }

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final status = await _services.getStatus(showLoading: false);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (status != null) _status = status;
    });
  }

  Future<void> _submit(LanguageProvider lang) async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final status = await _services.submit(
      _txnController.text.trim(),
      showLoading: false,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (status != null) {
      _txnController.clear();
      setState(() => _status = status);
      _alerts.successToast(lang.tr('exportPayment.submitted'));
    }
  }

  Future<void> _openUpiApp(LanguageProvider lang) async {
    final uri = _status?.upiUri;
    if (uri == null) return;
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(uri),
        mode: LaunchMode.externalApplication,
      );
    } on PlatformException {
      launched = false;
    }
    if (!launched) {
      _alerts.errorToast(lang.tr('exportPayment.upiAppUnavailable'));
    }
  }

  Future<void> _copyUpiId(LanguageProvider lang) async {
    final upiId = _status?.upiId ?? '';
    if (upiId.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: upiId));
    _alerts.successToast(lang.tr('exportPayment.copied'));
  }

  String? _validateTxn(String? value, LanguageProvider lang) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return lang.tr('exportPayment.txnRequired');
    if (!ExportPaymentServices.txnIdPattern.hasMatch(text)) {
      return lang.tr('exportPayment.txnInvalid');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final status = _status;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MoiAppHeader(
        title: lang.tr('exportPayment.title'),
        showBack: true,
        onBack: () => Navigator.pop(context, status?.canExport == true),
      ),
      body: SafeArea(
        top: false,
        child: _loading && status == null
            ? const Center(child: CircularProgressIndicator())
            : status == null
            ? _ErrorState(
                message: lang.tr('exportPayment.loadFailed'),
                retryLabel: lang.tr('exportPayment.retry'),
                onRetry: _refresh,
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  children: _buildContent(context, lang, status),
                ),
              ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    LanguageProvider lang,
    ExportPaymentStatus status,
  ) {
    final primary = Theme.of(context).colorScheme.primary;

    if (status.canExport) {
      return [
        _StatusCard(
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          color: AppColors.lightSuccess,
          title: lang.tr('exportPayment.approvedTitle'),
          message: _withCounts(
            lang.tr('exportPayment.approvedMessage'),
            status,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          title: lang.tr('exportPayment.continueExport'),
          onPressed: () => Navigator.pop(context, true),
        ),
      ];
    }

    if (status.isPending) {
      return [
        _StatusCard(
          icon: HugeIcons.strokeRoundedClock01,
          color: AppColors.saffronGold,
          title: lang.tr('exportPayment.pendingTitle'),
          message: lang.tr('exportPayment.pendingMessage'),
          detailLabel: lang.tr('exportPayment.submittedTxn'),
          detail: status.latestTxnId,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          title: lang.tr('exportPayment.refresh'),
          isLoading: _loading,
          onPressed: _refresh,
        ),
        _helpLink(lang),
      ];
    }

    if (!status.paymentConfigured ||
        (status.upiUri == null && status.qrImageUrl == null)) {
      return [
        _StatusCard(
          icon: HugeIcons.strokeRoundedAlert02,
          color: AppColors.saffronGold,
          title: lang.tr('exportPayment.title'),
          message: lang.tr('exportPayment.unavailable'),
        ),
        _helpLink(lang),
      ];
    }

    return [
      if (status.isExhausted) ...[
        _StatusCard(
          icon: HugeIcons.strokeRoundedPdf02,
          color: AppColors.saffronGold,
          title: lang.tr('exportPayment.exhaustedTitle'),
          message: _withCounts(
            lang.tr('exportPayment.exhaustedMessage'),
            status,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (status.isRejected) ...[
        _StatusCard(
          icon: HugeIcons.strokeRoundedCancelCircle,
          color: Theme.of(context).colorScheme.error,
          title: lang.tr('exportPayment.rejectedTitle'),
          message: lang.tr('exportPayment.rejectedMessage'),
          detailLabel: status.latestRemarks.isNotEmpty
              ? lang.tr('exportPayment.reason')
              : null,
          detail: status.latestRemarks.isNotEmpty ? status.latestRemarks : null,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      Text(
        lang
            .tr('exportPayment.subtitle')
            .replaceAll('{amount}', status.amountLabel)
            .replaceAll('{count}', '${status.exportsPerPayment}'),
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
      _QrCard(
        status: status,
        primary: primary,
        scanLabel: lang.tr('exportPayment.scanToPay'),
        upiLabel: lang.tr('exportPayment.upiId'),
        onCopy: () => _copyUpiId(lang),
      ),
      if (status.upiUri != null) ...[
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _openUpiApp(lang),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedSmartPhone01,
            color: primary,
            size: 18,
          ),
          label: Text(lang.tr('exportPayment.payWithApp')),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Form(
        key: _formKey,
        child: TextFormField(
          controller: _txnController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _validateTxn(value, lang),
          onFieldSubmitted: (_) => _submit(lang),
          decoration: InputDecoration(
            labelText: lang.tr('exportPayment.txnLabel'),
            hintText: lang.tr('exportPayment.txnHint'),
            helperText: lang.tr('exportPayment.txnHelp'),
            helperMaxLines: 3,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton(
        title: lang.tr('exportPayment.submit'),
        isLoading: _submitting,
        onPressed: () => _submit(lang),
      ),
      _helpLink(lang),
    ];
  }

  String _withCounts(String text, ExportPaymentStatus status) => text
      .replaceAll('{left}', '${status.remainingExports}')
      .replaceAll('{total}', '${status.exportsPerPayment}');

  Widget _helpLink(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Center(
        child: TextButton(
          onPressed: () =>
              showExportSupportSheet(context: context, languageProvider: lang),
          child: Text(lang.tr('exportPayment.needHelp')),
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final ExportPaymentStatus status;
  final Color primary;
  final String scanLabel;
  final String upiLabel;
  final VoidCallback onCopy;

  const _QrCard({
    required this.status,
    required this.primary,
    required this.scanLabel,
    required this.upiLabel,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            '₹ ${status.amountLabel}',
            style: AppTypography.amountLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          if (status.payeeName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              status.payeeName,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // QR stays dark-on-white in both themes so every UPI scanner reads it.
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _QrImage(status: status, semanticsLabel: scanLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            scanLabel,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          if (status.upiId.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '$upiLabel: ${status.upiId}',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCopy01,
                      color: primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Admin-uploaded QR image when set (falls back to the generated QR if it
/// fails to load), otherwise a QR generated from the UPI payment link.
class _QrImage extends StatelessWidget {
  static const double size = 220;
  final ExportPaymentStatus status;
  final String semanticsLabel;

  const _QrImage({required this.status, required this.semanticsLabel});

  Widget _generated() {
    final uri = status.upiUri;
    if (uri == null) {
      return const SizedBox(
        width: size,
        height: size,
        child: Center(child: Icon(Icons.qr_code_2, size: 64)),
      );
    }
    return QrImageView(
      data: uri,
      size: size,
      backgroundColor: Colors.white,
      semanticsLabel: semanticsLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = status.qrImageUrl;
    if (imageUrl == null) return _generated();
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SizedBox(
                width: size,
                height: size,
                child: Center(child: CircularProgressIndicator()),
              ),
        errorBuilder: (context, error, stackTrace) => _generated(),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final String title;
  final String message;
  final String? detailLabel;
  final String? detail;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.detailLabel,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: color, size: 26),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detailLabel == null ? detail! : '$detailLabel: $detail',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
