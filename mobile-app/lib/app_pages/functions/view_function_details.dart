import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';
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

  void _initializeFunctionDate() {
    final rawDate = widget.data[0]['functionDate']?.toString();
    functionDate = formatFunctionDateWithDay(rawDate);
    if (functionDate.isNotEmpty) {
      functionDate = functionDate.toUpperCase();
    }
    final imageUrl = widget.data[0]['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      _detailImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : '$appImageUrl/$imageUrl';
    }
    setState(() {});
  }

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

      final response = await transactionServices.getTransactionStats({
        "userId": userId,
        "transactionFunctionId": functionId,
      }, showLoading: false);

      if (mounted) {
        if (response != null && response['responseType'] == "S") {
          final stats = response['responseValue'];
          final investTotal =
              double.tryParse(
                stats is Map ? (stats['investTotal']?.toString() ?? '0') : '0',
              ) ??
              0.0;
          final returnTotal =
              double.tryParse(
                stats is Map ? (stats['returnTotal']?.toString() ?? '0') : '0',
              ) ??
              0.0;

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

  String _formatAmount(double amount) {
    if (amount == 0) return "0.00";
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
    final primary = Theme.of(context).colorScheme.primary;
    final functionName =
        widget.data[0]['functionName']?.toString().trim() ?? '-';
    final location = widget.data[0]['location']?.toString().trim() ?? '';
    final notes = widget.data[0]['notes']?.toString().trim() ?? '';

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiAppHeader(
            title: functionName.toUpperCase(),
            // subtitle: functionDate,
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.sm,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroImage(imageUrl: _detailImageUrl, onTap: _showFullImage),
                const SizedBox(height: AppSpacing.md),
                _AmountCard(
                      primary: primary,
                      label: languageProvider.tr(
                        'functionDetails.totalAmountReceived',
                      ),
                      amountText: '₹ ${_formatAmount(totalAmountReceived)}',
                      words: _amountInWords(totalAmountReceived),
                      isLoading: isLoadingAmount,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          "function-transaction-list",
                          arguments: widget.data[0],
                        );
                      },
                    )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.08, end: 0, duration: 420.ms),
                const SizedBox(height: AppSpacing.md),
                _DetailsSection(
                  primary: primary,
                  sectionTitle: languageProvider.tr('functionDetails.title'),
                  nameLabel: languageProvider.tr(
                    'functionDetails.functionName',
                  ),
                  dateLabel: languageProvider.tr(
                    'functionDetails.functionDate',
                  ),
                  locationLabel: languageProvider.tr(
                    'functionDetails.location',
                  ),
                  notesLabel: languageProvider.tr('functionDetails.notes'),
                  name: functionName,
                  date: functionDate,
                  location: location,
                  notes: notes,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullImage() {
    final imageUrl = _detailImageUrl;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(dialogContext).top + 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4,
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? MoiNetworkImage(
                              url: imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(AppImages.defaultImage),
                            )
                          : Image.asset(AppImages.defaultImage),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        color: Colors.white,
                        size: 22,
                        strokeWidth: 1.9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _HeroImage({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF101B18) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF26352E) : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl != null && imageUrl!.isNotEmpty
                  ? MoiNetworkImage(
                      url: imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        AppImages.defaultImage,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.42),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedZoomInArea,
                        color: Colors.white,
                        size: 18,
                        strokeWidth: 1.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final Color primary;
  final String label;
  final String amountText;
  final String words;
  final bool isLoading;
  final VoidCallback onTap;

  const _AmountCard({
    required this.primary,
    required this.label,
    required this.amountText,
    required this.words,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroBg = isDark ? const Color(0xFF071B18) : const Color(0xFF0E6A5E);
    final heroSoft = isDark ? const Color(0xFF0D312A) : const Color(0xFF145C4C);

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [heroBg, heroSoft, const Color(0xFF0A4F45)],
              ),
              boxShadow: [
                BoxShadow(
                  color: heroBg.withValues(alpha: 0.32),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: heroBg.withValues(alpha: 0.12),
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
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                Positioned(
                  right: 30,
                  bottom: -28,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isLoading)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      else
                        Text(
                          amountText,
                          style: AppTypography.amountLarge.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                            letterSpacing: -0.7,
                          ),
                        ),
                      if (words.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          words,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
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

class _DetailsSection extends StatelessWidget {
  final Color primary;
  final String sectionTitle;
  final String nameLabel;
  final String dateLabel;
  final String locationLabel;
  final String notesLabel;
  final String name;
  final String date;
  final String location;
  final String notes;

  const _DetailsSection({
    required this.primary,
    required this.sectionTitle,
    required this.nameLabel,
    required this.dateLabel,
    required this.locationLabel,
    required this.notesLabel,
    required this.name,
    required this.date,
    required this.location,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotes = notes.isNotEmpty;
    final rows =
        <
          ({List<List<dynamic>> icon, String label, String value, int maxLines})
        >[
          (
            icon: HugeIcons.strokeRoundedWedding,
            label: nameLabel,
            value: name.isEmpty ? '—' : name.toUpperCase(),
            maxLines: 2,
          ),
          (
            icon: HugeIcons.strokeRoundedCalendar01,
            label: dateLabel,
            value: date.isEmpty ? '—' : date.toUpperCase(),
            maxLines: 2,
          ),
          (
            icon: HugeIcons.strokeRoundedLocation01,
            label: locationLabel,
            value: location.isEmpty ? '—' : location.toUpperCase(),
            maxLines: 2,
          ),
          if (hasNotes)
            (
              icon: HugeIcons.strokeRoundedNote,
              label: notesLabel,
              value: notes.toUpperCase(),
              maxLines: 5,
            ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoiInfoSectionLabel(title: sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        MoiInfoCard(
          children: [
            for (var i = 0; i < rows.length; i++)
              MoiInfoTile(
                icon: rows[i].icon,
                title: rows[i].label,
                subtitle: rows[i].value,
                showChevron: false,
                showDivider: i < rows.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}
