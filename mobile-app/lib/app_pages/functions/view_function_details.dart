import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class ViewFunctionDetails extends StatefulWidget {
  final List data;
  const ViewFunctionDetails({super.key, required this.data});

  @override
  State<ViewFunctionDetails> createState() => _ViewFunctionDetailsState();
}

class _ViewFunctionDetailsState extends State<ViewFunctionDetails> {
  String functionDate = "";
  String? _detailImageUrl;
  double totalAmountReceived = 0.0;
  bool isLoadingAmount = false;
  final TransactionServices transactionServices = TransactionServices();
  final SecureStorageService storage = SecureStorageService();
  static final NumberFormat _formatter = NumberFormat('#,##,000.00');

  @override
  void initState() {
    super.initState();
    _initializeFunctionDate();
    _calculateAmountReceived();
  }

  // Initialize the function date with proper formatting (DD-MMM-YYYY)
  void _initializeFunctionDate() {
    functionDate = formatFunctionDate(
      widget.data[0]['functionDate']?.toString(),
    );
    final imageUrl = widget.data[0]['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      _detailImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '$appImageUrl/$imageUrl';
    }
    if (functionDate.isNotEmpty) {
      try {
        final parsed = DateFormat("dd-MMM-yyyy").parse(functionDate).toLocal();
        functionDate = DateFormat(
          "dd-MMM-yyyy, EEEE",
          'en',
        ).format(parsed).toString().toUpperCase();
      } catch (_) {}
    }
    setState(() {});
  }

  // Calculate total amount received for this function using transactions API
  Future<void> _calculateAmountReceived() async {
    if (!mounted) return;

    setState(() {
      isLoadingAmount = true;
    });

    try {
      final user = await storage.get(AppVariables.userInformation);
      if (user == null) {
        setState(() {
          totalAmountReceived = 0.0;
          isLoadingAmount = false;
        });
        return;
      }

      String userId = user['id'].toString();
      String functionId = widget.data[0]['id'].toString();

      final response = await transactionServices.listTransactions({
        "userId": userId,
        "transactionFunctionId": functionId,
      });

      if (mounted) {
        if (response != null && response['responseType'] == "S") {
          List transactionList = response['responseValue'] ?? [];

          // Calculate sum of invest and return amounts
          double investTotal = 0.0;
          double returnTotal = 0.0;

          for (var transaction in transactionList) {
            try {
              String type = transaction['type']?.toString().toUpperCase() ?? '';
              double amount = double.parse(
                transaction['amount']?.toString() ?? '0',
              );

              if (type == 'INVEST') {
                investTotal += amount;
              } else if (type == 'RETURN') {
                returnTotal += amount;
              }
            } catch (e) {
              // Skip invalid amounts
            }
          }

          setState(() {
            totalAmountReceived = investTotal + returnTotal;
            isLoadingAmount = false;
          });
        } else {
          setState(() {
            totalAmountReceived = 0.0;
            isLoadingAmount = false;
          });
        }
      }
    } catch (e) {
      printContent("Error calculating amount: $e");
      if (mounted) {
        setState(() {
          totalAmountReceived = 0.0;
          isLoadingAmount = false;
        });
      }
    }
  }

  // Format number for display
  String _formatAmount(double amount) {
    if (amount == 0) {
      return "0.00";
    }
    return _formatter.format(amount);
  }

  String _amountInWords(double amount) {
    final value = amount.round();
    if (value == 0) return 'Zero Rupees Only';
    return '${_numberToWords(value)} Rupees Only';
  }

  String _numberToWords(int value) {
    const ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String belowThousand(int number) {
      final words = <String>[];
      if (number >= 100) {
        words.add('${ones[number ~/ 100]} Hundred');
        number %= 100;
      }
      if (number >= 20) {
        words.add(tens[number ~/ 10]);
        number %= 10;
      }
      if (number > 0) words.add(ones[number]);
      return words.join(' ');
    }

    final words = <String>[];
    if (value >= 10000000) {
      words.add('${belowThousand(value ~/ 10000000)} Crore');
    }
    var remainder = value % 10000000;
    if (remainder >= 100000) {
      words.add('${belowThousand(remainder ~/ 100000)} Lakh');
      remainder %= 100000;
    }
    if (remainder >= 1000) {
      words.add('${belowThousand(remainder ~/ 1000)} Thousand');
      remainder %= 1000;
    }
    if (remainder > 0) words.add(belowThousand(remainder));
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          appBar: AppBarWidget(
            title: languageProvider.tr('functionDetails.title'),
            action: const [],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildFunctionImage(),
                const SizedBox(height: 18),
                _buildAmountReceivedCard(
                  Theme.of(context).colorScheme.primary,
                  isDark,
                  languageProvider,
                ),
                const SizedBox(height: 18),
                _buildDetailsSection(colorScheme, isDark, languageProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the amount received card with a clear currency label.
  Widget _buildAmountReceivedCard(
    Color color,
    bool isDark,
    LanguageProvider languageProvider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(color: color.withValues(alpha: 0.9)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            "function-transaction-list",
            arguments: widget.data[0],
          );
        },
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.tr(
                        'functionDetails.totalAmountReceived',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (isLoadingAmount)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: color,
                          strokeWidth: 2.5,
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '₹ ${_formatAmount(totalAmountReceived)}',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: color,
                              fontFamily: 'Arimo',
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 3),
                    Text(
                      _amountInWords(totalAmountReceived),
                      style: TextStyle(
                        color: color.withValues(alpha: 0.78),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionImage() {
    final imageUrl = _detailImageUrl;
    return GestureDetector(
      onTap: _showFullImage,
      child: SizedBox(
        width: double.infinity,
        height: 220,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
              )
            : Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
      ),
    );
  }

  void _showFullImage() {
    final imageUrl = _detailImageUrl;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(AppImages.defaultImage),
                        )
                      : Image.asset(AppImages.defaultImage),
                ),
              ),
              Positioned(
                top: 20,
                right: 16,
                child: IconButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                  iconSize: 28,
                  tooltip: 'Close',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build the details section with modern cards
  Widget _buildDetailsSection(
    ColorScheme colorScheme,
    bool isDark,
    LanguageProvider languageProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailCard(
          icon: Icons.celebration_outlined,
          label: languageProvider.tr('functionDetails.functionName'),
          value: widget.data[0]['functionName'].toString(),
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildDetailCard(
          icon: Icons.calendar_month_outlined,
          label: languageProvider.tr('functionDetails.functionDate'),
          value: functionDate,
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildDetailCard(
          icon: Icons.location_city_outlined,
          label: languageProvider.tr('functionDetails.location'),
          value: widget.data[0]['location'] ?? "",
          colorScheme: colorScheme,
          isDark: isDark,
        ),
        if (widget.data[0]['notes'] != null &&
            widget.data[0]['notes'].toString().trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailCard(
            icon: Icons.note_alt_outlined,
            label: languageProvider.tr('functionDetails.notes'),
            value: widget.data[0]['notes'] ?? "-",
            colorScheme: colorScheme,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  // Create a modern detail card widget
  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final displayValue = value.trim().isEmpty ? "-" : value;
    final hasValue = value.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey[850]! : Colors.white).withValues(
          alpha: isDark ? 0.82 : 0.72,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : AppColors.blackLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: hasValue
                        ? colorScheme.primary
                        : (isDark ? Colors.grey[600] : AppColors.fontGrey),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.dashSpace,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final dashPath = _dashPath(path, dashLength, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path path, double dashLength, double dashSpace) {
    final dashPath = Path();
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + dashSpace;
      }
    }

    return dashPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
