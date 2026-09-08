import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:moi/app_utils/app_global/app_functions.dart';
import 'package:moi/app_utils/app_global/date_formatter.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:open_file/open_file.dart';

class PdfExportService {
  static final NumberFormat _amountFormatter = NumberFormat('#,##,000.00');

  /// Export MOI list for a specific function as PDF
  /// Downloads directly to Downloads folder
  static Future<String?> exportMoiListToPdf({
    required List<dynamic> moiList,
    required Map<String, dynamic> functionData,
    required Function(String) onCompleted,
    required Function(String) onError,
  }) async {
    try {
      final pdf = pw.Document();

      // Load Tamil font if available - use lowercase to match pubspec.yaml
      // final appFontFamilyData = await _loadFont('TAU_KRIN');
      final englishFontData = await _loadFont('Roboto');
      final boldFontData = await _loadFont('RobotoBold');

      final appFontFamilyData = await rootBundle.load(
        'assets/fonts/NotoSansTamil.ttf',
      );
      final appFontFamily = pw.Font.ttf(appFontFamilyData);
      // Load app logo for promotion section
      pw.ImageProvider? logoImage;
      try {
        final logoData = await rootBundle.load(AppImages.appLogoImage);
        final logoBytes = logoData.buffer.asUint8List();
        if (logoBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(logoBytes);
          debugPrint('Successfully loaded logo (${logoBytes.length} bytes)');
        } else {
          debugPrint('Logo file is empty');
          logoImage = null;
        }
      } catch (e) {
        debugPrint('Could not load logo: $e');
        logoImage = null;
      }

      // Create font objects from loaded data
      // Fonts are automatically embedded when used in the document
      // pw.Font? appFontFamily;
      pw.Font? englishFont;
      pw.Font? boldFont;

      // try {
      //   if (appFontFamilyData != null) {
      //     appFontFamily = pw.Font.ttf(appFontFamilyData);
      //   }
      // } catch (e) {
      //   debugPrint('Failed to create Tamil font: $e');
      //   appFontFamily = null;
      // }

      try {
        if (englishFontData != null) {
          englishFont = pw.Font.ttf(englishFontData);
        }
      } catch (e) {
        debugPrint('Failed to create English font: $e');
        englishFont = null;
      }

      try {
        if (boldFontData != null) {
          boldFont = pw.Font.ttf(boldFontData);
        }
      } catch (e) {
        debugPrint('Failed to create bold font: $e');
        boldFont = null;
      }

      // Calculate totals
      double totalAmount = 0.0;
      int totalCount = moiList.length;
      for (var moi in moiList) {
        try {
          double amount = double.parse(moi['amount']?.toString() ?? '0');
          totalAmount += amount;
        } catch (e) {
          // Skip invalid amounts
        }
      }

      // Reverse the list order (opposite sort)
      final reversedMoiList = moiList.reversed.toList();

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          theme: pw.ThemeData.withFont(
            base: appFontFamily,
            bold: boldFont ?? pw.Font.helveticaBold(),
          ),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(
                functionData: functionData,
                appFontFamily: appFontFamily,
                englishFont: englishFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 24),

              // Summary Section
              _buildSummarySection(
                totalCount: totalCount,
                totalAmount: totalAmount,
                appFontFamily: appFontFamily,
                englishFont: englishFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 24),

              // MOI List Table
              _buildMoiTable(
                moiList: reversedMoiList,
                appFontFamily: appFontFamily,
                englishFont: englishFont,
                boldFont: boldFont,
              ),
              // App Promotion Section
              // Added at the end - will appear on the last page naturally
              pw.SizedBox(height: 24),
              _buildAppPromotion(
                logoImage: logoImage,
                englishFont: englishFont,
                boldFont: boldFont,
              ),
            ];
          },
          footer: (pw.Context context) {
            // Footer is rendered after page count is finalized
            // context.pagesCount is accurate at this point - no race conditions
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [
                    PdfColors.blue600,
                    PdfColors.blue700,
                    PdfColors.blue800,
                  ],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Moi Kanakku',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      font: boldFont ?? pw.Font.helveticaBold(),
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                      font: englishFont ?? pw.Font.helvetica(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Generate filename: functionName in lowercase with timestamp
      final functionName =
          functionData['functionName']?.toString() ?? 'function';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${functionName.toLowerCase().replaceAll(' ', '_')}_$timestamp.pdf';

      // Save to downloads folder
      if (Platform.isAndroid) {
        // Convert PDF bytes to base64 off the UI isolate (can be expensive for large PDFs)
        final base64Pdf = await Isolate.run(() => base64Encode(pdfBytes));

        // Use flutter_file_downloader to save to Downloads/Moi Kanakku/download folder
        FileDownloader.writeFile(
          content: base64Pdf,
          fileName: fileName,
          extension: 'pdf',
          subPath: 'Moi Kanakku',
          downloadDestination: DownloadDestinations.publicDownloads,
          onCompleted: (String savedPath) async {
            onCompleted(savedPath);
            // Open the PDF file after download
            await _openPdfFile(savedPath);
          },
          onError: (String error) {
            onError(error);
          },
        );
        return null; // Async operation, return handled via callbacks
      } else if (Platform.isIOS) {
        // For iOS, save to Documents/Downloads folder
        final documentsDir = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory(
          path.join(documentsDir.path, 'Downloads', 'Moi Kanakku'),
        );
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath = path.join(downloadsDir.path, '$fileName.pdf');
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        onCompleted(filePath);
        // Open the PDF file after download
        await _openPdfFile(filePath);
        return filePath;
      } else {
        throw Exception('Unsupported platform');
      }
    } catch (e) {
      onError('Failed to generate PDF: $e');
      return null;
    }
  }

  /// Build header section with modern design
  static pw.Widget _buildHeader({
    required Map<String, dynamic> functionData,
    required pw.Font? appFontFamily,
    required pw.Font? englishFont,
    required pw.Font? boldFont,
  }) {
    final functionName = (functionData['functionName']?.toString() ?? '')
        .trim();
    final functionDate = formatFunctionDate(
      functionData['functionDate']?.toString(),
    );
    final firstName = (functionData['firstName']?.toString() ?? '').trim();
    final secondName = (functionData['secondName']?.toString() ?? '').trim();

    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue700, PdfColors.blue800],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Festival-based Moi List',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              font: appFontFamily ?? pw.Font.helvetica(),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Festival Name',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.blue700,
                          font: appFontFamily ?? pw.Font.helvetica(),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        _safeTitleCase(functionName),
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                          font: englishFont ?? pw.Font.helvetica(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Date',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.blue700,
                          font: appFontFamily ?? pw.Font.helvetica(),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        functionDate,
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                          font: englishFont ?? pw.Font.helvetica(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (firstName.isNotEmpty || secondName.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Name: $firstName${secondName.isNotEmpty ? ' - $secondName' : ''}',
                style: pw.TextStyle(
                  fontSize: 13,
                  color: PdfColors.blue700,
                  font: appFontFamily ?? pw.Font.helvetica(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build summary section with modern design
  static pw.Widget _buildSummarySection({
    required int totalCount,
    required double totalAmount,
    required pw.Font? appFontFamily,
    required pw.Font? englishFont,
    required pw.Font? boldFont,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.blue50, PdfColors.blue100],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.blue300, width: 1.5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Total Count',
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey700,
                    font: appFontFamily ?? pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  totalCount.toString(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                    font: boldFont ?? pw.Font.helveticaBold(),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.green50, PdfColors.green100],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.green300, width: 1.5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Total Amount',
                  style: pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey700,
                    font: appFontFamily ?? pw.Font.helvetica(),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '₹ ${_amountFormatter.format(totalAmount)}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                    font: boldFont ?? pw.Font.helveticaBold(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build MOI table
  static pw.Widget _buildMoiTable({
    required List<dynamic> moiList,
    required pw.Font? appFontFamily,
    required pw.Font? englishFont,
    required pw.Font? boldFont,
  }) {
    if (moiList.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.Text(
            'No Moi Records',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
              font: appFontFamily ?? pw.Font.helvetica(),
            ),
          ),
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          verticalInside: pw.BorderSide(color: PdfColors.grey300, width: 1),
          horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.0), // S.No column
          1: const pw.FlexColumnWidth(1.8), // City
          2: const pw.FlexColumnWidth(2.5), // Name (firstName - secondName)
          3: const pw.FlexColumnWidth(1.8), // Occupation
          4: const pw.FlexColumnWidth(2.0), // Remarks
          5: const pw.FlexColumnWidth(2), // Amount
        },
        children: [
          // Header row
          pw.TableRow(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [PdfColors.blue600, PdfColors.blue700],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            children: [
              _buildTableCell(
                'No',
                appFontFamily,
                appFontFamily,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                'City',
                appFontFamily,
                appFontFamily,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                'Name',
                appFontFamily,
                appFontFamily,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                'Occupation',
                appFontFamily,
                appFontFamily,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                'Remarks',
                appFontFamily,
                appFontFamily,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
              _buildTableCell(
                'Amount (₹)',
                appFontFamily,
                appFontFamily,
                isHeader: true,
                alignment: pw.Alignment.center,
              ),
            ],
          ),
          // Data rows
          ...moiList.asMap().entries.map((entry) {
            final index = entry.key;
            final moi = entry.value;
            final firstName = moi['firstName']?.toString() ?? '';
            final secondName = moi['secondName']?.toString() ?? '';
            final cityName = moi['cityName']?.toString() ?? '-';
            final occupation = moi['occupation']?.toString() ?? '-';
            final remarks = moi['remarks']?.toString() ?? '-';
            final amount = moi['amount']?.toString() ?? '0';

            // Combine firstName and secondName
            String fullName = firstName;
            if (secondName.isNotEmpty) {
              fullName = firstName.isEmpty
                  ? secondName
                  : '$firstName - $secondName';
            }
            if (fullName.isEmpty) {
              fullName = '-';
            }

            double amountValue = 0.0;
            try {
              amountValue = double.parse(amount);
            } catch (e) {
              // Keep as 0
            }

            // Alternate row colors for better readability
            final isEven = index % 2 == 0;

            return pw.TableRow(
              decoration: isEven
                  ? null
                  : pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _buildTableCell(
                  '${index + 1}',
                  englishFont,
                  boldFont,
                  alignment: pw.Alignment.center,
                ),
                _buildTableCell(
                  cityName,
                  appFontFamily,
                  boldFont,
                  alignment: pw.Alignment.centerLeft,
                ),
                _buildTableCell(
                  fullName,
                  appFontFamily,
                  boldFont,
                  alignment: pw.Alignment.centerLeft,
                ),
                _buildTableCell(
                  occupation,
                  appFontFamily,
                  boldFont,
                  alignment: pw.Alignment.centerLeft,
                ),
                _buildTableCell(
                  remarks,
                  appFontFamily,
                  boldFont,
                  alignment: pw.Alignment.centerLeft,
                ),
                _buildTableCell(
                  '₹ ${_amountFormatter.format(amountValue)}',
                  englishFont,
                  boldFont,
                  alignment: pw.Alignment.centerRight,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Build app promotion section for the last page
  static pw.Widget _buildAppPromotion({
    required pw.ImageProvider? logoImage,
    required pw.Font? englishFont,
    required pw.Font? boldFont,
  }) {
    return pw.Align(
      alignment: pw.Alignment.center,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            colors: [PdfColors.blue50, PdfColors.blue100],
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
          ),
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: PdfColors.blue300, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // App Logo
            if (logoImage != null) ...[
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(12),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColors.grey400,
                      blurRadius: 8,
                      offset: const PdfPoint(0, 2),
                    ),
                  ],
                ),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(height: 16),
            ],
            pw.Text(
              'Download Our App',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
                font: boldFont ?? pw.Font.helveticaBold(),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Moi Kanakku - Manage your events, functions, and gifts easily!',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 13,
                color: PdfColors.grey800,
                font: englishFont ?? pw.Font.helvetica(),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.blue600, PdfColors.blue700],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Get it on Google Play Store',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  font: englishFont ?? pw.Font.helvetica(),
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            // Clickable Play Store link
            pw.Link(
              destination:
                  'https://play.google.com/store/apps/details?id=com.renzo.moi',
              child: pw.Text(
                'https://play.google.com/store/apps/details?id=com.renzo.moi',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.blue700,
                  decoration: pw.TextDecoration.underline,
                  font: englishFont ?? pw.Font.helvetica(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build table cell with alignment support and vertical middle alignment
  static pw.Widget _buildTableCell(
    String text,
    pw.Font? normalFont,
    pw.Font? boldFont, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    // Determine horizontal alignment value
    double xAlignment = -1.0; // Default to left
    if (alignment == pw.Alignment.center) {
      xAlignment = 0.0;
    } else if (alignment == pw.Alignment.centerRight) {
      xAlignment = 1.0;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      // Use Align to ensure both horizontal and vertical center alignment
      child: pw.Align(
        alignment: pw.Alignment(
          xAlignment,
          0,
        ), // 0 for vertical center (middle)
        child: pw.Text(
          text,
          textAlign: alignment == pw.Alignment.center
              ? pw.TextAlign.center
              : alignment == pw.Alignment.centerRight
              ? pw.TextAlign.right
              : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: isHeader ? 12 : 11,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isHeader ? PdfColors.white : PdfColors.grey900,
            font: isHeader && boldFont != null
                ? boldFont
                : normalFont ?? pw.Font.helvetica(),
          ),
        ),
      ),
    );
  }

  /// Safely convert string to title case, handling empty strings and null values
  static String _safeTitleCase(String? text) {
    if (text == null || text.trim().isEmpty) {
      return '-';
    }
    try {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return '-';
      return trimmed.toTitleCase();
    } catch (e) {
      debugPrint('Error converting to title case: $e');
      return text.trim().isNotEmpty ? text.trim() : '-';
    }
  }

  /// Open PDF file using available PDF viewer app
  /// Uses open_file package which handles FileProvider automatically on Android
  static Future<void> _openPdfFile(String filePath) async {
    try {
      // Remove file:// prefix if present
      String cleanPath = filePath;
      if (filePath.startsWith('file://')) {
        cleanPath = filePath.replaceFirst('file://', '');
      }

      // Check if file exists
      final file = File(cleanPath);
      if (!await file.exists()) {
        debugPrint('PDF file does not exist: $cleanPath');
        return;
      }

      // Use open_file package which handles FileProvider automatically
      final result = await OpenFile.open(cleanPath);

      if (result.type != ResultType.done) {
        debugPrint('Failed to open PDF: ${result.message}');
      }
    } catch (e) {
      debugPrint('Error opening PDF file: $e');
      // Silently fail - user can manually open the file from Downloads
    }
  }

  /// Load font from assets
  /// Note: Font file names must match exactly as in pubspec.yaml
  /// Tries both lowercase and uppercase extensions for compatibility
  static Future<ByteData?> _loadFont(String fontName) async {
    try {
      String fontPath = 'assets/fonts/';
      List<String> possiblePaths = [];

      switch (fontName) {
        case 'TAU_KRIN':
          // Try uppercase extension first (actual file name), then lowercase
          possiblePaths = ['TAU_KRIN.TTF', 'TAU_KRIN.ttf'];
          break;
        case 'Roboto':
          possiblePaths = ['Roboto.ttf'];
          break;
        case 'RobotoBold':
          possiblePaths = ['Roboto-Bold.ttf'];
          break;
        default:
          return null;
      }

      // Try each possible path
      Exception? lastError;
      for (String path in possiblePaths) {
        try {
          final fullPath = fontPath + path;
          final fontData = await rootBundle.load(fullPath);
          if (fontData.lengthInBytes > 0) {
            debugPrint(
              'Successfully loaded font $fontName from $fullPath (${fontData.lengthInBytes} bytes)',
            );
            return fontData;
          }
        } catch (e) {
          // Store error but don't print yet - only print if all attempts fail
          lastError = e is Exception ? e : Exception(e.toString());
          // Try next path
          continue;
        }
      }

      // All paths failed - only now print the error
      debugPrint(
        'Failed to load font $fontName from any path: $possiblePaths${lastError != null ? ' - $lastError' : ''}',
      );
      return null;
    } catch (e) {
      // Font loading failed - return null to use fallback font
      debugPrint('Failed to load font $fontName: $e');
      return null;
    }
  }
}
