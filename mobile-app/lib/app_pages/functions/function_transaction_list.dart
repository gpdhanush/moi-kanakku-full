import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_services/export_service.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class FunctionTransactionList extends StatefulWidget {
  final dynamic functionData;
  const FunctionTransactionList({super.key, required this.functionData});

  @override
  State<FunctionTransactionList> createState() =>
      _FunctionTransactionListState();
}

class _FunctionTransactionListState extends State<FunctionTransactionList> {
  final TransactionServices transactionServices = TransactionServices();
  final SecureStorageService storage = SecureStorageService();
  final AlertServices alertServices = AlertServices();
  static final NumberFormat _formatter = NumberFormat('#,##,##,000.00');

  List<dynamic> transactionList = [];
  List<dynamic> searchHistory = [];
  bool isLoading = true;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  String get _functionName {
    final name = widget.functionData['functionName']?.toString().trim() ?? '';
    return name.isEmpty ? '—' : name;
  }

  String get _functionDateSubtitle {
    final raw = widget.functionData['functionDate']?.toString();
    final formatted = formatFunctionDateWithDay(raw);
    return formatted.isEmpty ? '' : formatted.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    searchController.addListener(searchListener);
  }

  @override
  void dispose() {
    searchController.removeListener(searchListener);
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void searchListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      search(searchController.text);
    });
  }

  void search(String value) {
    if (!mounted) return;

    final filteredList = value.isEmpty
        ? transactionList
        : transactionList.where((element) {
            final personName =
                "${element['person']?['firstName']?.toString() ?? ''} ${element['person']?['lastName']?.toString() ?? ''}"
                    .toLowerCase();
            final date =
                element['transactionDate']?.toString().toLowerCase() ?? '';
            final notes = element['notes']?.toString().toLowerCase() ?? '';
            final city =
                element['person']?['city']?.toString().toLowerCase() ?? '';
            final amount = element['amount']?.toString().toLowerCase() ?? '';
            final input = value.toLowerCase();

            return personName.contains(input) ||
                date.contains(input) ||
                notes.contains(input) ||
                city.contains(input) ||
                amount.contains(input);
          }).toList();

    setState(() {
      searchHistory = filteredList;
    });
  }

  Future<void> _exportFunctionTransactionsPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final user = await storage.get(AppVariables.userInformation);

      if (!mounted) return;
      Navigator.pop(context);

      if (user == null) {
        alertServices.errorToast(
          context.read<LanguageProvider>().tr(
            'transactionList.userDetailsNotFound',
          ),
        );
        return;
      }

      final functionName =
          widget.functionData['functionName']?.toString().replaceAll(
                RegExp(r'[^a-zA-Z0-9]'),
                '_',
              ) ??
              'Transactions';
      final fileName = "Moi_${functionName}_Transactions.pdf";

      await ExportService.exportTransactionsToPdf(
        transactions: transactionList,
        userDetails: user,
        fileName: fileName,
      );

      if (mounted) {
        alertServices.successToast(
          context.read<LanguageProvider>().tr(
            'transactionList.exportedSuccessfully',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      debugPrint('Error exporting transactions: $e');
      alertServices.errorToast(
        context.read<LanguageProvider>().tr('transactionList.exportError'),
      );
    }
  }

  Future<void> _loadTransactions({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final user = await storage.get(AppVariables.userInformation);
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      String userId = user['id'].toString();
      String functionId = widget.functionData['id'].toString();

      final response = await transactionServices.listTransactions({
        "userId": userId,
        "transactionFunctionId": functionId,
      });

      if (mounted) {
        if (response != null && response['responseType'] == "S") {
          List transactions = response['responseValue'] ?? [];
          final query = searchController.text;

          setState(() {
            transactionList = transactions;
            searchHistory = query.isEmpty
                ? transactions
                : transactions.where((element) {
                    final personName =
                        "${element['person']?['firstName']?.toString() ?? ''} ${element['person']?['lastName']?.toString() ?? ''}"
                            .toLowerCase();
                    final date =
                        element['transactionDate']?.toString().toLowerCase() ??
                            '';
                    final notes =
                        element['notes']?.toString().toLowerCase() ?? '';
                    final city =
                        element['person']?['city']?.toString().toLowerCase() ??
                            '';
                    final amount =
                        element['amount']?.toString().toLowerCase() ?? '';
                    final input = query.toLowerCase();
                    return personName.contains(input) ||
                        date.contains(input) ||
                        notes.contains(input) ||
                        city.contains(input) ||
                        amount.contains(input);
                  }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            transactionList = [];
            searchHistory = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      printContent("Error loading transactions: $e");
      if (mounted) {
        setState(() {
          transactionList = [];
          searchHistory = [];
          isLoading = false;
        });
      }
    }
  }

  String _formatAmount(double amount) {
    if (amount == 0) return "0.00";
    return _formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _FunctionListHeader(
        title: _functionName.toUpperCase(),
        subtitle: _functionDateSubtitle,
        exportTooltip: languageProvider.tr('transactionList.exportPdf'),
        onBack: () => Navigator.pop(context),
        onExport: _exportFunctionTransactionsPdf,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.sm,
                    AppSpacing.page,
                    0,
                  ),
                  child: SearchWidget(
                    controller: searchController,
                    hintText: languageProvider.tr('transactionList.search'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: searchHistory.isEmpty
                      ? CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: MoiEmptyState(
                                title: languageProvider.tr(
                                  'transactionList.empty',
                                ),
                                subtitle: languageProvider.tr(
                                  'transactionList.emptyHint',
                                ),
                                icon: HugeIcons.strokeRoundedInvoice01,
                                accentColor: primary,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            0,
                            AppSpacing.page,
                            24,
                          ),
                          itemCount: searchHistory.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final tx = searchHistory[index];
                            final type =
                                tx['type']?.toString().toUpperCase() ?? '';
                            final isInvest = type == 'INVEST';
                            final amount =
                                double.tryParse(
                                      tx['amount']?.toString() ?? '0',
                                    ) ??
                                    0.0;
                            final first =
                                tx['person']?['firstName']?.toString().trim() ??
                                '';
                            final last =
                                tx['person']?['lastName']?.toString().trim() ??
                                tx['person']?['secondName']
                                    ?.toString()
                                    .trim() ??
                                '';
                            final personName = '$first $last'.trim();
                            final city =
                                tx['person']?['city']?.toString().trim() ?? '';
                            final location =
                                tx['person']?['location']?.toString().trim() ??
                                '';
                            final place = city.isNotEmpty
                                ? city
                                : location;

                            return MoiInvoiceListTile.moiFlow(
                              isReceived: isInvest,
                              title: personName.isEmpty
                                  ? languageProvider.tr(
                                      'transactionList.unknown',
                                    )
                                  : personName,
                              subtitle: place.toUpperCase(),
                              amount: '₹${_formatAmount(amount)}',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  'transaction-detail-view',
                                  arguments: tx,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _FunctionListHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String exportTooltip;
  final VoidCallback onBack;
  final VoidCallback onExport;

  const _FunctionListHeader({
    required this.title,
    required this.subtitle,
    required this.exportTooltip,
    required this.onBack,
    required this.onExport,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Center(
            child: Tooltip(
              message: exportTooltip,
              child: Material(
                color: Colors.white.withValues(alpha: 0.14),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onExport,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPdf02,
                        color: Colors.white,
                        size: 20,
                        strokeWidth: 1.9,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
