import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_services/export_service.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_widgets/app_no_data_found.dart';
import 'package:moi/app_utils/app_widgets/moi_list_item.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class AllTransactionsPage extends StatefulWidget {
  /// type can be 'INVEST' or 'RETURN' or any other value for all
  final String type;
  const AllTransactionsPage({super.key, required this.type});

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  final TransactionServices _txServices = TransactionServices();
  final SecureStorageService _storage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();

  List<dynamic> _transactions = [];
  List<dynamic> _searchHistory = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  void _performSearch(String value) {
    if (!mounted) return;
    final filtered = value.isEmpty
        ? _transactions
        : _transactions.where((element) {
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
      _searchHistory = filtered;
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final user = await _storage.get(AppVariables.userInformation);
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final userId = user['id'].toString();
      final response = await _txServices.listTransactions({
        "userId": userId,
      }, showLoading: false);
      if (mounted) {
        if (response != null && response['responseType'] == 'S') {
          List list = response['responseValue'] ?? [];
          if (widget.type == 'INVEST' || widget.type == 'RETURN') {
            list = list.where((t) {
              final tType = t['type']?.toString().toUpperCase() ?? '';
              return tType == widget.type;
            }).toList();
          }
          setState(() {
            _transactions = list;
            _searchHistory = list;
            _isLoading = false;
          });
        } else {
          setState(() {
            _transactions = [];
            _searchHistory = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        setState(() {
          _transactions = [];
          _searchHistory = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatAmount(double amt) {
    if (amt == 0) return '0.00';
    final formatter = NumberFormat('#,##,##0.00');
    return formatter.format(amt);
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

  double _totalAmount() {
    return _transactions.fold(0.0, (total, transaction) {
      return total +
          (double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0);
    });
  }

  Future<void> _exportPdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final user = await _storage.get(AppVariables.userInformation);
      if (!mounted) return;
      Navigator.pop(context);

      if (user == null) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('home.userDetailsNotFound'),
        );
        return;
      }
      await ExportService.exportTransactionsToPdf(
        transactions: _transactions,
        userDetails: user,
      );
      if (mounted) {
        _alertServices.successToast(
          context.read<LanguageProvider>().tr('home.exportedSuccessfully'),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error exporting: $e');
      _alertServices.errorToast(
        context.read<LanguageProvider>().tr('home.exportError'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.type == 'INVEST'
        ? languageProvider.tr('transactions.newInvest')
        : widget.type == 'RETURN'
        ? languageProvider.tr('transactions.newReturn')
        : languageProvider.tr('moi.title');

    return Scaffold(
      appBar: AppBarWidget(
        title: title,
        action: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Colors.white,
            ),
            onPressed: _exportPdf,
            tooltip: languageProvider.tr('home.exportData'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummary(colorScheme, isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: SizedBox(
                    height: 52,
                    child: SearchWidget(
                      controller: _searchController,
                      hintText: languageProvider.tr('transactions.search'),
                    ),
                  ),
                ),
                Expanded(
                  child: _searchHistory.isEmpty
                      ? const Center(child: AppNoDataFound(showSecond: false))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _searchHistory.length,
                          itemBuilder: (context, index) {
                            final t = _searchHistory[index];
                            final type =
                                t['type']?.toString().toUpperCase() ?? '';
                            final isInvest = type == 'INVEST';
                            final amount =
                                double.tryParse(
                                  t['amount']?.toString() ?? '0',
                                ) ??
                                0;
                            final personName =
                                "${t['person']?['firstName'] ?? ''} ${t['person']?['lastName'] ?? ''}"
                                    .trim();
                            final date = _formatDate(
                              t['transactionDate']?.toString(),
                            );

                            final accent = isInvest
                                ? Colors.green
                                : Colors.redAccent;

                            return MoiListItem(
                              accentColor: accent,
                              title: personName.isEmpty
                                  ? languageProvider.tr('common.noData')
                                  : personName,
                              subtitle: date,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  'transaction-detail-view',
                                  arguments: t,
                                );
                              },
                              trailing: Text(
                                '₹ ${_formatAmount(amount)}',
                                style: TextStyle(
                                  color: accent,
                                  fontFamily: 'Arimo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummary(ColorScheme colorScheme, bool isDark) {
    final languageProvider = context.read<LanguageProvider>();
    final total = _totalAmount();
    final label = widget.type == 'INVEST'
        ? languageProvider.tr('home.totalBalance')
        : widget.type == 'RETURN'
        ? languageProvider.tr('home.totalBalance')
        : languageProvider.tr('transactions.title');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹ ${_formatAmount(total)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_transactions.length} records',
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
