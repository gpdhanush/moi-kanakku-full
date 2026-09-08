import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:tamil_pdf_shaper/tamil_pdf_shaper.dart';

class ExportService {
  static final NumberFormat _numberFormatter = NumberFormat('#,##,##,000.00');

  /// Export transactions to PDF and share
  static Future<void> exportTransactionsToPdf({
    required List<dynamic> transactions,
    required Map<String, dynamic> userDetails,
    String? fileName,
  }) async {
    try {
      if (transactions.isEmpty) {
        throw Exception('No transactions found to export');
      }

      // Ensure transactions are sorted by person name (first + last) ascending
      final sortedTransactions = List<dynamic>.from(transactions);
      sortedTransactions.sort((a, b) {
        String aFirst = a['person']?['firstName']?.toString() ?? '';
        String aLast = a['person']?['lastName']?.toString() ?? '';
        String bFirst = b['person']?['firstName']?.toString() ?? '';
        String bLast = b['person']?['lastName']?.toString() ?? '';
        final aName = ('$aFirst $aLast').trim().toLowerCase();
        final bName = ('$bFirst $bLast').trim().toLowerCase();
        return aName.compareTo(bName);
      });

      // Generate PDF using sorted list
      final pdf = await _generateTransactionsPdf(
        sortedTransactions,
        userDetails,
      );

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = fileName ?? "Moi_Kanakku_Export_$timestamp.pdf";

      // Share PDF
      await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
    } catch (e) {
      debugPrint('Error exporting transactions: $e');
      rethrow;
    }
  }

  /// Generate PDF with transactions data
  static Future<pw.Document> _generateTransactionsPdf(
    List<dynamic> transactions,
    Map<String, dynamic> userDetails,
  ) async {
    final pdf = pw.Document();

    final pw.Font tamilFont = await TamilPdfFont.load();
    final pw.TextStyle tamilTextStyle = pw.TextStyle(font: tamilFont);

    // Helper for shaping Tamil text
    String t(String text) => text.toTamilPdf;

    // Load logo with error handling
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load(AppImages.appLogoImage);
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Failed to load logo: $e');
      // Continue without logo
    }

    // Current timestamp
    final timestamp = DateFormat(
      'dd-MMM-yyyy hh:mm:ss a',
    ).format(DateTime.now());

    // User info
    final userName = userDetails['name']?.toString() ?? 'User';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(
          base: tamilFont,
          bold: tamilFont,
          italic: tamilFont,
          boldItalic: tamilFont,
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue, width: 2),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                children: [
                  if (logoImage != null) ...[
                    pw.Image(logoImage, width: 40, height: 40),
                    pw.SizedBox(width: 10),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          t('மொய் கணக்கு - பரிவர்த்தனை அறிக்கை'),
                          style: pw.TextStyle(
                            font: tamilFont,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          t('பயனர்: ') + userName,
                          style: pw.TextStyle(
                            font: tamilFont,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    timestamp,
                    style: tamilTextStyle.copyWith(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        t('மொத்த பரிவர்த்தனைகள்'),
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${transactions.length}',
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 14,
                          color: PdfColors.blue,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        t('வந்த மொய்'),
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '₹ ${_calculateTotalAmount(transactions, 'invest')}',
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 14,
                          color: PdfColors.green,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text(
                        t('செய்த மொய்'),
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '₹ ${_calculateTotalAmount(transactions, 'return')}',
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 14,
                          color: PdfColors.red,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Transactions Table (auto pagination + better alignment)
            pw.TableHelper.fromTextArray(
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.blue100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              headerStyle: pw.TextStyle(
                font: tamilFont,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: pw.TextStyle(font: tamilFont, fontSize: 9),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1),
              },
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignment: pw.Alignment.centerLeft,
              headers: [
                t('தேதி'),
                t('விழா பெயர்'),
                t('நபர்'),
                t('தொகை'),
                t('வகை'),
              ],
              data: transactions.map<List<String>>((transaction) {
                if (transaction == null || transaction is! Map) {
                  return ['-', '-', '-', '₹ 0', '-'];
                }

                final date = _formatTransactionDate(
                  transaction['transactionDate']?.toString(),
                );

                final functionName =
                    transaction['transactionFunctionName']?.toString() ?? '-';

                final person = transaction['person'];
                String personName = '-';
                if (person != null && person is Map) {
                  final firstName = person['firstName']?.toString() ?? '';
                  final lastName = person['lastName']?.toString() ?? '';
                  final fullName = [
                    firstName,
                    lastName,
                  ].where((e) => e.isNotEmpty).join(' ');
                  personName = fullName.isNotEmpty ? fullName : '-';
                }

                final amountRaw = transaction['amount']?.toString() ?? '0';
                final amount = double.tryParse(amountRaw) ?? 0;

                final typeRaw =
                    transaction['type']?.toString().toUpperCase() ?? '';
                final type = typeRaw == 'RETURN' ? t('செய்தது') : t('வந்தது');

                return [
                  date,
                  t(functionName),
                  t(personName),
                  '₹ ${_numberFormatter.format(amount)}',
                  type,
                ];
              }).toList(),
              cellAlignments: {
                3: pw.Alignment.centerRight, // amount right aligned
                4: pw.Alignment.center,
              },
              border: pw.TableBorder(
                bottom: const pw.BorderSide(color: PdfColors.grey300),
                horizontalInside: const pw.BorderSide(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
            ),

            // Footer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(logoImage, width: 20, height: 20),
                        pw.SizedBox(width: 5),
                      ],
                      pw.Text(
                        t('மொய் கணக்கு ஆப்'),
                        style: pw.TextStyle(
                          font: tamilFont,
                          fontSize: 10,
                          color: PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    t('உருவாக்கப்பட்ட தேதி: ') + timestamp,
                    style: pw.TextStyle(
                      font: tamilFont,
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Format transaction date
  static String _formatTransactionDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Calculate total amount by type
  static String _calculateTotalAmount(List<dynamic> transactions, String type) {
    double total = 0;
    for (var transaction in transactions) {
      if (transaction['type']?.toString().toLowerCase() == type.toLowerCase()) {
        final amount =
            double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
        total += amount;
      }
    }
    return _numberFormatter.format(total);
  }
}
