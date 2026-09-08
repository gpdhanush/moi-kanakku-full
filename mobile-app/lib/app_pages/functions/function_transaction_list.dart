import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_services/export_service.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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
  double totalInvest = 0.0;
  double totalReturn = 0.0;

  // Search
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

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

  // Listener for search input changes with debouncing
  void searchListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      search(searchController.text);
    });
  }

  // Filters the transaction list based on the search input
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
            final amount = element['amount']?.toString().toLowerCase() ?? '';
            final input = value.toLowerCase();

            return personName.contains(input) ||
                date.contains(input) ||
                notes.contains(input) ||
                amount.contains(input);
          }).toList();

    setState(() {
      searchHistory = filteredList;
    });
  }

  // Export function transactions to PDF
  Future<void> _exportFunctionTransactionsPdf() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Get user details
      final user = await storage.get(AppVariables.userInformation);

      if (!mounted) return;
      Navigator.pop(context); // Hide loading

      if (user == null) {
        alertServices.errorToast(
          context.read<LanguageProvider>().tr(
            'transactionList.userDetailsNotFound',
          ),
        );
        return;
      }

      // Use ExportService to export
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

  Future<void> _loadTransactions() async {
    setState(() => isLoading = true);

    try {
      final user = await storage.get(AppVariables.userInformation);
      if (user == null) {
        setState(() => isLoading = false);
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

          // Calculate totals
          double invest = 0.0;
          double returnAmt = 0.0;

          for (var transaction in transactions) {
            try {
              String type = transaction['type']?.toString().toUpperCase() ?? '';
              double amount = double.parse(
                transaction['amount']?.toString() ?? '0',
              );

              if (type == 'INVEST') {
                invest += amount;
              } else if (type == 'RETURN') {
                returnAmt += amount;
              }
            } catch (e) {
              // Skip invalid amounts
            }
          }

          setState(() {
            transactionList = transactions;
            searchHistory = transactions;
            totalInvest = invest;
            totalReturn = returnAmt;
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

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;
    // final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBarWidget(
        title:
            widget.functionData['functionName']?.toString() ??
            context.read<LanguageProvider>().tr('transactionList.title'),
        action: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () => _exportFunctionTransactionsPdf(),
            tooltip: context.read<LanguageProvider>().tr(
              'transactionList.exportPdf',
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // _buildSummaryHeader(
                //   Theme.of(context).colorScheme,
                //   Theme.of(context).brightness == Brightness.dark,
                // ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: SizedBox(
                    height: 52,
                    child: SearchWidget(
                      controller: searchController,
                      hintText: context.read<LanguageProvider>().tr(
                        'transactionList.search',
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: searchHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.read<LanguageProvider>().tr(
                                  'transactionList.empty',
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildTransactionList(
                          Theme.of(context).colorScheme,
                          Theme.of(context).brightness == Brightness.dark,
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTransactionList(ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: searchHistory.length,
      itemBuilder: (context, index) {
        final transaction = searchHistory[index];
        return _buildTransactionCard(transaction, colorScheme, isDark);
      },
    );
  }

  Widget _buildTransactionCard(
    dynamic transaction,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final type = transaction['type']?.toString().toUpperCase() ?? '';
    final isInvest = type == 'INVEST';
    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
    final personName =
        "${transaction['person']?['firstName']?.toString() ?? ''} ${transaction['person']?['lastName']?.toString().toTitleCase() ?? ''}"
            .trim();
    final date = _formatDate(transaction['transactionDate']?.toString());
    final notes = transaction['notes']?.toString() ?? '';

    final color = isInvest ? Colors.green : Colors.redAccent;
    // final icon = isInvest
    //     ? Icons.arrow_downward_outlined
    //     : Icons.arrow_upward_outlined;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pushNamed(
            context,
            'transaction-detail-view',
            arguments: transaction,
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 13, 14, 13),
          child: Row(
            children: [
              /// MODERN CIRCLE ICON
              // Container(
              //   width: 42,
              //   height: 42,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     color: color.withAlpha(30),
              //   ),
              //   child: Icon(icon, color: color, size: 21),
              // ),

              // const SizedBox(width: 5),

              /// DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personName.isEmpty
                          ? context.read<LanguageProvider>().tr(
                              'transactionList.unknown',
                            )
                          : personName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 12,
                          color: color.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontFamily: 'englishFont',
                          ),
                        ),
                      ],
                    ),

                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              /// AMOUNT SECTION
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 4,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: color.withAlpha(30),
                  //     border: Border.all(color: color.withAlpha(100)),
                  //     borderRadius: BorderRadius.circular(50),
                  //   ),
                  //   child: Text(
                  //     isInvest ? 'வந்த மொய்' : 'செய்த மொய்',
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //       color: color,
                  //       fontWeight: FontWeight.normal,
                  //       fontSize: 9,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  Text(
                    '₹ ${_formatAmount(amount)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontFamily: 'Arimo',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
