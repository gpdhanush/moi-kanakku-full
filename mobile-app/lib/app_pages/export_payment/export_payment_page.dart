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
/// The user buys a plan: 1 export (₹19), 5 exports (₹49) or lifetime (₹499,
/// unlimited). When none are left, opens [ExportPaymentPage] (QR code, transaction ID, review
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
  // Lifetime exports are not counted, so there is nothing to report.
  if (status.lifetime) return;
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

/// First 12-digit UPI transaction ID (UTR) in [text], ignoring spaces and
/// dashes inside it; null when there is none.
@visibleForTesting
String? extractUpiTxnId(String? text) {
  if (text == null) return null;
  final compact = text.replaceAll(RegExp(r'(?<=\d)[\s-]+(?=\d)'), '');
  final match = RegExp(r'(?<!\d)\d{12}(?!\d)').firstMatch(compact);
  return match?.group(0);
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
  String? _selectedPlanId;
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

  /// The plan the user picked, else the backend's default plan.
  ExportPlan _planFor(ExportPaymentStatus status) {
    final selected = _selectedPlanId;
    if (selected != null) {
      for (final plan in status.availablePlans) {
        if (plan.id == selected) return plan;
      }
    }
    return status.defaultPlan;
  }

  Future<void> _submit(LanguageProvider lang) async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final current = _status;
    final status = await _services.submit(
      _txnController.text.trim(),
      planId: current == null ? null : _planFor(current).id,
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
    final current = _status;
    final uri = current == null ? null : _planFor(current).upiUri;
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

  /// Pastes a UPI transaction ID from the clipboard. Picks the first
  /// 12-digit number, so a copied line like "UPI Ref No: 1234 5678 9012" works.
  Future<void> _pasteTxn(LanguageProvider lang) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final txnId = extractUpiTxnId(data?.text);
    if (txnId == null) {
      _alerts.errorToast(lang.tr('exportPayment.pasteEmpty'));
      return;
    }
    _txnController.value = TextEditingValue(
      text: txnId,
      selection: TextSelection.collapsed(offset: txnId.length),
    );
    _formKey.currentState?.validate();
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
          message: status.lifetime
              ? lang.tr('exportPayment.lifetimeMessage')
              : _withCounts(lang.tr('exportPayment.approvedMessage'), status),
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

    final plan = _planFor(status);
    if (!status.paymentConfigured ||
        (plan.upiUri == null && status.qrImageUrl == null)) {
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
        lang.tr('exportPayment.choosePlan'),
        style: AppTypography.label.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      _PlanPicker(
        plans: status.availablePlans,
        selected: plan,
        lang: lang,
        onSelected: (picked) => setState(() => _selectedPlanId = picked.id),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        _planSubtitle(lang, plan),
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
      const SizedBox(height: AppSpacing.md),
      _QrCard(
        status: status,
        plan: plan,
        primary: primary,
        scanLabel: lang.tr('exportPayment.scanToPay'),
        upiLabel: lang.tr('exportPayment.upiId'),
        onCopy: () => _copyUpiId(lang),
      ),
      if (plan.upiUri != null) ...[
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
        child: TextFormWidget(
          title: lang.tr('exportPayment.txnLabel'),
          hintText: lang.tr('exportPayment.txnHint'),
          controller: _txnController,
          required: true,
          prefixIcon: HugeIcons.strokeRoundedInvoice01,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autocorrect: false,
          enableSuggestions: false,
          validator: (value) => _validateTxn(value, lang),
          onFieldSubmitted: (_) => _submit(lang),
          suffixIconTrue: true,
          suffixIcon: HugeIcons.strokeRoundedClipboardPaste,
          suffixIconTooltip: lang.tr('exportPayment.pasteTxn'),
          suffixIconOnPressed: () => _pasteTxn(lang),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        lang.tr('exportPayment.txnHelp'),
        style: AppTypography.label.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
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

  String _planSubtitle(LanguageProvider lang, ExportPlan plan) {
    final key = plan.isLifetime
        ? 'exportPayment.subtitleLifetime'
        : plan.exports == 1
        ? 'exportPayment.subtitleOne'
        : 'exportPayment.subtitle';
    return lang
        .tr(key)
        .replaceAll('{amount}', plan.amountLabel)
        .replaceAll('{count}', '${plan.exports ?? ''}');
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

/// Selectable list of export plans; the chosen one drives the QR and amount.
class _PlanPicker extends StatelessWidget {
  final List<ExportPlan> plans;
  final ExportPlan selected;
  final LanguageProvider lang;
  final ValueChanged<ExportPlan> onSelected;

  const _PlanPicker({
    required this.plans,
    required this.selected,
    required this.lang,
    required this.onSelected,
  });

  String _title(ExportPlan plan) {
    if (plan.isLifetime) return lang.tr('exportPayment.planLifetime');
    if (plan.exports == 1) return lang.tr('exportPayment.planOne');
    return lang
        .tr('exportPayment.planMany')
        .replaceAll('{count}', '${plan.exports}');
  }

  String _caption(ExportPlan plan) {
    if (plan.isLifetime) return lang.tr('exportPayment.planLifetimeCaption');
    final count = plan.exports ?? 1;
    final each = plan.amount / (count < 1 ? 1 : count);
    final label = each == each.roundToDouble()
        ? each.toStringAsFixed(0)
        : each.toStringAsFixed(1);
    return lang.tr('exportPayment.planPerExport').replaceAll('{amount}', label);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        for (final plan in plans) ...[
          _PlanTile(
            title: _title(plan),
            caption: _caption(plan),
            price: '₹${plan.amountLabel}',
            badge: plan.isLifetime ? lang.tr('exportPayment.bestValue') : null,
            selected: plan.id == selected.id,
            primary: primary,
            onTap: () => onSelected(plan),
          ),
          if (plan != plans.last) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _PlanTile extends StatelessWidget {
  final String title;
  final String caption;
  final String price;
  final String? badge;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  const _PlanTile({
    required this.title,
    required this.caption,
    required this.price,
    required this.badge,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? primary : AppColors.borderSubtle,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? primary : AppColors.textMuted,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.saffronGold.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: AppTypography.label.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  price,
                  style: AppTypography.label.copyWith(
                    color: selected ? primary : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final ExportPaymentStatus status;
  final ExportPlan plan;
  final Color primary;
  final String scanLabel;
  final String upiLabel;
  final VoidCallback onCopy;

  const _QrCard({
    required this.status,
    required this.plan,
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
            '₹ ${plan.amountLabel}',
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
            child: _QrImage(
              status: status,
              upiUri: plan.upiUri,
              semanticsLabel: scanLabel,
            ),
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
  final String? upiUri;
  final String semanticsLabel;

  const _QrImage({
    required this.status,
    required this.upiUri,
    required this.semanticsLabel,
  });

  Widget _generated() {
    final uri = upiUri;
    if (uri == null) {
      return const SizedBox(
        width: size,
        height: size,
        child: Center(child: Icon(Icons.qr_code_2, size: 64)),
      );
    }
    return QrImageView(
      key: ValueKey(uri),
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
