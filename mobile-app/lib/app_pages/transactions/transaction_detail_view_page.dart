import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';

class TransactionDetailViewPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailViewPage({super.key, required this.transaction});

  @override
  State<TransactionDetailViewPage> createState() =>
      _TransactionDetailViewPageState();
}

class _TransactionDetailViewPageState extends State<TransactionDetailViewPage> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isLoadingPdf = false;

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return formatFunctionDateWithDay(iso);
    } catch (_) {
      try {
        return DateFormat('dd-MMM-yyyy').format(DateTime.parse(iso).toLocal());
      } catch (_) {
        return iso;
      }
    }
  }

  String _clean(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text.toTitleCase();
  }

  bool _isCustom(dynamic value) {
    if (value == true) return true;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  String _formatAmount(dynamic value) {
    final raw = value?.toString().trim() ?? '0';
    final parsed = num.tryParse(raw);
    if (parsed == null) return raw;
    return NumberFormat('#,##0.00').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    final functionName = _clean(widget.transaction['transactionFunctionName']);
    final transactionDate = _formatDate(
      widget.transaction['transactionDate']?.toString(),
    );
    final typeRaw = widget.transaction['type']?.toString().toUpperCase() ?? '';
    final isInvest = typeRaw == 'INVEST';
    final amount = _formatAmount(widget.transaction['amount']);
    final isCustom = _isCustom(widget.transaction['isCustom']);
    final customFunction = _clean(widget.transaction['customFunction']);
    final accent = isInvest ? AppColors.moiReceived : AppColors.moiGiven;
    final typeLabel = languageProvider.tr(
      isInvest ? 'moi.moiIn' : 'moi.moiOut',
    );

    final person = widget.transaction['person'] is Map
        ? Map<String, dynamic>.from(widget.transaction['person'] as Map)
        : <String, dynamic>{};
    final firstName = _clean(person['firstName']);
    final lastName = _clean(person['lastName']);
    final personName = '$firstName $lastName'.trim();
    final displayName = personName.isEmpty ? functionName : personName;
    final headerTitle = (displayName.isEmpty ? '-' : displayName).toUpperCase();

    final itemName = _clean(widget.transaction['itemName']);
    final notes = _clean(widget.transaction['notes']);
    final city = _clean(person['city']);
    final mobile = _clean(person['mobile']);
    final occupation = _clean(person['occupation']);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _DetailsAppHeader(
        title: headerTitle,
        subtitle: '',
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AmountHeaderCard(
                      accent: accent,
                      amountText: '₹ $amount',
                      functionLabel: isCustom
                          ? customFunction
                          : functionName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailsSection(
                      primary: primary,
                      sectionTitle: languageProvider.tr(
                        'functionDetails.title',
                      ),
                      rows: [
                        (
                          icon: isInvest
                              ? HugeIcons.strokeRoundedMoneyReceive01
                              : HugeIcons.strokeRoundedMoneySend01,
                          label: languageProvider.tr('moi.moiType'),
                          value: typeLabel.toUpperCase(),
                          maxLines: 1,
                          valueColor: accent,
                        ),
                        (
                          icon: HugeIcons.strokeRoundedCalendar01,
                          label: languageProvider.tr('transactions.date'),
                          value: transactionDate.isEmpty
                              ? '—'
                              : transactionDate.toUpperCase(),
                          maxLines: 2,
                          valueColor: null,
                        ),
                        (
                          icon: HugeIcons.strokeRoundedWedding,
                          label: languageProvider.tr(
                            'transactions.functionName',
                          ),
                          value: functionName.isEmpty
                              ? '—'
                              : functionName.toUpperCase(),
                          maxLines: 2,
                          valueColor: null,
                        ),
                        if (isCustom)
                          (
                            icon: HugeIcons.strokeRoundedSparkles,
                            label: languageProvider.tr(
                              'transactions.customFunction',
                            ),
                            value: customFunction.isEmpty
                                ? '—'
                                : customFunction.toUpperCase(),
                            maxLines: 2,
                            valueColor: null,
                          ),
                        if (itemName.isNotEmpty)
                          (
                            icon: HugeIcons.strokeRoundedGift,
                            label: languageProvider.tr('transactions.thing'),
                            value: itemName.toUpperCase(),
                            maxLines: 2,
                            valueColor: null,
                          ),
                        if (notes.isNotEmpty)
                          (
                            icon: HugeIcons.strokeRoundedNote,
                            label: languageProvider.tr('transactions.notes'),
                            value: notes.toUpperCase(),
                            maxLines: 5,
                            valueColor: null,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailsSection(
                      primary: primary,
                      sectionTitle: languageProvider.tr(
                        'profile.personalInformation',
                      ),
                      rows: [
                        (
                          icon: HugeIcons.strokeRoundedUser,
                          label: languageProvider.tr('transactions.name'),
                          value: personName.isEmpty
                              ? '—'
                              : personName.toUpperCase(),
                          maxLines: 2,
                          valueColor: null,
                        ),
                        (
                          icon: HugeIcons.strokeRoundedLocation01,
                          label: languageProvider.tr('transactions.city'),
                          value: city.isEmpty ? '—' : city.toUpperCase(),
                          maxLines: 2,
                          valueColor: null,
                        ),
                        (
                          icon: HugeIcons.strokeRoundedCall,
                          label: languageProvider.tr('transactions.mobile'),
                          value: mobile.isEmpty ? '—' : mobile,
                          maxLines: 1,
                          valueColor: null,
                        ),
                        (
                          icon: HugeIcons.strokeRoundedBriefcase01,
                          label: languageProvider.tr(
                            'transactions.occupation',
                          ),
                          value: occupation.isEmpty
                              ? '—'
                              : occupation.toUpperCase(),
                          maxLines: 2,
                          valueColor: null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: _ExportButton(
                title: languageProvider.tr('transactionList.exportPdf'),
                isLoading: _isLoadingPdf,
                onPressed: () => _sharePdf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    if (_isLoadingPdf) return;
    setState(() => _isLoadingPdf = true);

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );

      if (imageBytes == null) {
        if (mounted) setState(() => _isLoadingPdf = false);
        return;
      }

      final pdf = pw.Document();
      final image = pw.MemoryImage(imageBytes);
      final logoBytes = await rootBundle.load(AppImages.appLogoImage);
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            final timestamp = DateFormat(
              'dd-MMM-yyyy hh:mm:ss a',
            ).format(DateTime.now()).toUpperCase();
            return pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, height: 16),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      'Generated in Moi Kanakku app',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.indigo),
                    ),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  timestamp,
                  style: pw.TextStyle(fontSize: 5, color: PdfColors.grey),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final firstName = _clean(
        widget.transaction['person']?['firstName'],
        fallback: 'person',
      ).toLowerCase().replaceAll(' ', '-');
      final city = _clean(
        widget.transaction['person']?['city'],
        fallback: 'city',
      ).toLowerCase().replaceAll(' ', '-');
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = '$firstName-$city-$timestamp.pdf';

      if (mounted) setState(() => _isLoadingPdf = false);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) setState(() => _isLoadingPdf = false);
      printContent('Error generating PDF: $e');
    }
  }
}

class _DetailsAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  const _DetailsAppHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: preferredSize.height,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: isDark ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              Color.lerp(primary, const Color(0xff0A3D8F), 0.35)!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      leadingWidth: 54,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: Colors.white,
                    size: 22,
                    strokeWidth: 1.9,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
      actions: const [SizedBox(width: 54)],
    );
  }
}

class _AmountHeaderCard extends StatelessWidget {
  final Color accent;
  final String amountText;
  final String functionLabel;

  const _AmountHeaderCard({
    required this.accent,
    required this.amountText,
    required this.functionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final deep = Color.lerp(accent, const Color(0xff0A3D8F), 0.18)!;
    final soft = Color.lerp(accent, Colors.white, 0.22)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, soft, deep],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            right: 36,
            bottom: -28,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    amountText,
                    textAlign: TextAlign.center,
                    style: AppTypography.amountLarge.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      letterSpacing: -0.7,
                    ),
                  ),
                  if (functionLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      functionLabel.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef _DetailRow = ({
  List<List<dynamic>> icon,
  String label,
  String value,
  int maxLines,
  Color? valueColor,
});

class _DetailsSection extends StatelessWidget {
  final Color primary;
  final String sectionTitle;
  final List<_DetailRow> rows;

  const _DetailsSection({
    required this.primary,
    required this.sectionTitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                _DetailTile(
                  primary: primary,
                  hugeIcon: rows[i].icon,
                  label: rows[i].label,
                  value: rows[i].value,
                  maxLines: rows[i].maxLines,
                  valueColor: rows[i].valueColor,
                  showDivider: i < rows.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final Color primary;
  final List<List<dynamic>> hugeIcon;
  final String label;
  final String value;
  final int maxLines;
  final Color? valueColor;
  final bool showDivider;

  const _DetailTile({
    required this.primary,
    required this.hugeIcon,
    required this.label,
    required this.value,
    this.maxLines = 2,
    this.valueColor,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: hugeIcon,
                  color: primary,
                  size: 17,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: valueColor ?? AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 62,
            endIndent: 14,
            color: Color(0xffF4F4F5),
          ),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final String title;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.title,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedPdf02,
                        color: Colors.white,
                        size: 18,
                        strokeWidth: 1.9,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: AppTypography.label.copyWith(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
