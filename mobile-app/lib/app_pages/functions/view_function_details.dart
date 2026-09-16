import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

      final response = await transactionServices.listTransactions({
        "userId": userId,
        "transactionFunctionId": functionId,
      });

      if (mounted) {
        if (response != null && response['responseType'] == "S") {
          List transactionList = response['responseValue'] ?? [];

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
            } catch (_) {}
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
          appBar: _DetailsAppHeader(
            title: functionName.toUpperCase(),
            subtitle: functionDate,
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
                _HeroImage(
                  imageUrl: _detailImageUrl,
                  onTap: _showFullImage,
                ),
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
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailsSection(
                  primary: primary,
                  sectionTitle:
                      languageProvider.tr('functionDetails.title'),
                  nameLabel:
                      languageProvider.tr('functionDetails.functionName'),
                  dateLabel:
                      languageProvider.tr('functionDetails.functionDate'),
                  locationLabel:
                      languageProvider.tr('functionDetails.location'),
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
                top: MediaQuery.paddingOf(dialogContext).top + 8,
                right: 16,
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
        );
      },
    );
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

class _HeroImage extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _HeroImage({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.soft,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
                    )
                  : Image.asset(AppImages.defaultImage, fit: BoxFit.cover),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedZoomInArea,
                    color: Colors.white,
                    size: 16,
                    strokeWidth: 1.8,
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
    final deep = Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!;
    final soft = Color.lerp(primary, Colors.white, 0.22)!;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, soft, deep],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.32),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
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
    final rows = <({
      List<List<dynamic>> icon,
      String label,
      String value,
      int maxLines,
    })>[
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
  final bool showDivider;

  const _DetailTile({
    required this.primary,
    required this.hugeIcon,
    required this.label,
    required this.value,
    this.maxLines = 2,
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
                        color: AppColors.textPrimary,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(height: 1, color: Color(0xffF4F4F5)),
          ),
      ],
    );
  }
}
