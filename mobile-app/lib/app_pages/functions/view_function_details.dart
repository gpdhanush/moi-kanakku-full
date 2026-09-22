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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (dialogContext) {
        return Dialog.fullscreen(
          backgroundColor: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  constrained: true,
                  boundaryMargin: EdgeInsets.zero,
                  minScale: 1,
                  maxScale: 5,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? MoiNetworkImage(
                          url: imageUrl,
                          fit: BoxFit.contain,
                          memCacheWidth:
                              (MediaQuery.sizeOf(dialogContext).width *
                                      MediaQuery.devicePixelRatioOf(
                                        dialogContext,
                                      ))
                                  .round(),
                          memCacheHeight:
                              (MediaQuery.sizeOf(dialogContext).height *
                                      MediaQuery.devicePixelRatioOf(
                                        dialogContext,
                                      ))
                                  .round(),
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                AppImages.defaultImage,
                                fit: BoxFit.contain,
                              ),
                        )
                      : Image.asset(
                          AppImages.defaultImage,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(dialogContext).top + 12,
                right: 16,
                child: Material(
                  color: (isDark ? AppColors.darkSurface : Colors.black)
                      .withValues(alpha: 0.72),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: 'Close image',
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
            GestureDetector(
              onTap: onTap,
              child: InteractiveViewer(
                constrained: true,
                boundaryMargin: EdgeInsets.zero,
                clipBehavior: Clip.hardEdge,
                minScale: 1,
                maxScale: 4,
                child: SizedBox.expand(
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? MoiNetworkImage(
                          url: imageUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth:
                              (MediaQuery.sizeOf(context).width *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                AppImages.defaultImage,
                                fit: BoxFit.contain,
                              ),
                        )
                      : Image.asset(
                          AppImages.defaultImage,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.48),
                  shape: const CircleBorder(),
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
    final heroFg = isDark ? const Color(0xFFB8FFE8) : AppColors.white;
    final heroMuted = isDark
        ? const Color(0xFF7EE8C7)
        : heroFg.withValues(alpha: 0.78);

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.xlAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xlAll,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.xlAll,
            color: heroBg,
            border: isDark
                ? Border.all(color: const Color(0xFF4AF2B6), width: 1.4)
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentSoft.withValues(alpha: 0.18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: heroMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isLoading)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: heroFg,
                          strokeWidth: 2.4,
                        ),
                      )
                    else
                      Text(
                        amountText,
                        style: AppTypography.amountLarge.copyWith(
                          color: heroFg,
                          fontSize: 34,
                          letterSpacing: -0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (words.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        height: 1,
                        color: heroFg.withValues(alpha: 0.18),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        words,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          color: heroFg,
                          fontSize: 13,
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
