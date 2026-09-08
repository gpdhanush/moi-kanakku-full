import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_images.dart';
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
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  String _clean(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
    return text.toString().toTitleCase();
  }

  bool _isCustom(dynamic value) {
    if (value == true) return true;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  String _formatAmount(dynamic value) {
    final raw = _clean(value, fallback: '0');
    final parsed = num.tryParse(raw);
    if (parsed == null) return raw;
    return NumberFormat('#,##0.00').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    printContent(widget.transaction.toString());
    final functionName = _clean(widget.transaction['transactionFunctionName']);
    final transactionDate = _formatDate(
      widget.transaction['transactionDate']?.toString(),
    );
    final type = _clean(widget.transaction['type']);
    final amount = _formatAmount(widget.transaction['amount']);
    final isCustom = _isCustom(widget.transaction['isCustom']);
    final customFunction = _clean(widget.transaction['customFunction']);
    final isInvest = type.toLowerCase() == 'invest';
    final accentColor = isInvest ? Colors.green.shade700 : Colors.red.shade700;
    final person = widget.transaction['person'] is Map
        ? Map<String, dynamic>.from(widget.transaction['person'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      appBar: AppBarWidget(
        title: languageProvider.tr('transactions.details'),
        action: [],
      ),
      body: Column(
        children: [
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1 — Function + Amount card
                    _buildFunctionHeaderCard(
                      context,
                      functionName: functionName,
                      amount: amount,
                      isCustom: isCustom,
                      customFunction: customFunction,
                      colorScheme: colorScheme,
                      accentColor: accentColor,
                      transactionLabel: languageProvider.tr(
                        isInvest ? 'moi.moiIn' : 'moi.moiOut',
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Section 2 — Function details
                    _buildSectionCard(
                      context,
                      title: languageProvider.tr('functionDetails.title'),
                      colorScheme: colorScheme,
                      children: [
                        _buildInfoRow(
                          languageProvider.tr('moi.moiType'),
                          languageProvider.tr(
                            isInvest ? 'moi.moiIn' : 'moi.moiOut',
                          ),
                        ),
                        _buildInfoRow(
                          languageProvider.tr('transactions.date'),
                          transactionDate,
                        ),
                        _buildInfoRow(
                          languageProvider.tr('transactions.functionName'),
                          functionName,
                        ),
                        // _buildInfoRow(
                        //   languageProvider.tr('transactions.amount'),
                        //   amount,
                        //   isAmount: true,
                        //   accentColor: accentColor,
                        // ),
                        if (isCustom)
                          _buildInfoRow(
                            languageProvider.tr('transactions.customFunction'),
                            customFunction,
                          ),
                        if (widget.transaction['itemName'] != null)
                          _buildInfoRow(
                            languageProvider.tr('transactions.thing'),
                            _clean(widget.transaction['itemName']),
                          ),
                        if (widget.transaction['notes'] != null)
                          _buildInfoRow(
                            languageProvider.tr('transactions.notes'),
                            _clean(
                              widget.transaction['notes']
                                  .toString()
                                  .toTitleCase(),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Section 3 — Person details
                    _buildSectionCard(
                      context,
                      title: languageProvider.tr('profile.personalInformation'),
                      colorScheme: colorScheme,
                      children: [
                        _buildInfoRow(
                          languageProvider.tr('transactions.firstName'),
                          '${_clean(person['firstName'])} - ${_clean(person['lastName'])}',
                        ),
                        _buildInfoRow(
                          languageProvider.tr('transactions.city'),
                          _clean(person['city']),
                        ),
                        _buildInfoRow(
                          languageProvider.tr('transactions.mobile'),
                          _clean(person['mobile']),
                        ),

                        _buildInfoRow(
                          languageProvider.tr('transactions.occupation'),
                          _clean(person['occupation']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildShareButton(
              context,
              functionName: isCustom ? customFunction : functionName,
              amount: amount,
              transactionDate: transactionDate,
              type: type,
              isCustom: isCustom,
              customFunction: customFunction,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionHeaderCard(
    BuildContext context, {
    required String functionName,
    required String amount,
    required bool isCustom,
    required String customFunction,
    required ColorScheme colorScheme,
    required Color accentColor,
    required String transactionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCustom ? Icons.auto_awesome_outlined : Icons.event_outlined,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isCustom ? customFunction : functionName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              transactionLabel,
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '₹ $amount',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFamily: 'Arimo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isAmount = false,
    Color? accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value.trim().isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: isAmount ? 16 : 12,
                fontWeight: isAmount ? FontWeight.w800 : FontWeight.w500,
                color: isAmount
                    ? (accentColor ?? Theme.of(context).colorScheme.primary)
                    : Theme.of(context).colorScheme.onSurface,
                fontFamily: isAmount ? 'amountFont' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(
    BuildContext context, {
    required String functionName,
    required String amount,
    required String transactionDate,
    required String type,
    required bool isCustom,
    required String customFunction,
  }) {
    final languageProvider = context.read<LanguageProvider>();
    return AppButton(
      title: languageProvider.tr('transactionList.exportPdf'),
      onPressed: _isLoadingPdf ? () {} : () => _sharePdf(context),
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
      ).toLowerCase().replaceAll(' ', '-');
      final city = _clean(
        widget.transaction['person']?['city'],
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
