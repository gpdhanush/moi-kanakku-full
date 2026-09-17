import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/export_service.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<dynamic> _transactions = [];
  List<dynamic> _filtered = [];
  bool _isLoading = true;

  bool get _isReceived => widget.type == 'INVEST';
  bool get _isGiven => widget.type == 'RETURN';
  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  Color get _accent =>
      _isReceived ? AppColors.moiReceived : AppColors.moiGiven;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadTransactions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _applySearch(_searchController.text);
    });
  }

  void _applySearch(String value) {
    if (!mounted) return;

    final query = value.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filtered = List<dynamic>.from(_transactions));
      return;
    }

    setState(() {
      _filtered = _transactions.where((t) {
        final first = t['person']?['firstName']?.toString() ?? '';
        final last = t['person']?['lastName']?.toString() ??
            t['person']?['secondName']?.toString() ??
            '';
        final personName = '$first $last'.toLowerCase();
        final city = t['person']?['city']?.toString().toLowerCase() ?? '';
        final mobile = t['person']?['mobile']?.toString().toLowerCase() ?? '';
        final amount = t['amount']?.toString().toLowerCase() ?? '';
        final notes = t['notes']?.toString().toLowerCase() ?? '';
        final date = t['transactionDate']?.toString().toLowerCase() ?? '';
        final functionName = _functionName(t).toLowerCase();

        return personName.contains(query) ||
            city.contains(query) ||
            mobile.contains(query) ||
            amount.contains(query) ||
            notes.contains(query) ||
            date.contains(query) ||
            functionName.contains(query);
      }).toList();
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
            _isLoading = false;
          });
          _applySearch(_searchController.text);
        } else {
          setState(() {
            _transactions = [];
            _filtered = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        setState(() {
          _transactions = [];
          _filtered = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatAmount(double amt) {
    if (amt == 0) return '0';
    final formatter = NumberFormat('#,##,##0');
    return formatter.format(amt);
  }

  String _functionName(dynamic t) {
    final isCustom =
        t['isCustom'] == true ||
        t['isCustom']?.toString().toLowerCase() == 'true' ||
        t['isCustom']?.toString() == '1';
    final custom = t['customFunction']?.toString().trim() ?? '';
    final name = t['transactionFunctionName']?.toString().trim() ?? '';
    if (isCustom && custom.isNotEmpty) return custom;
    if (name.isNotEmpty) return name;
    if (custom.isNotEmpty) return custom;
    return '-';
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
        transactions: _isSearching ? _filtered : _transactions,
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
    final title = _isReceived
        ? languageProvider.tr('moi.moiIn')
        : _isGiven
        ? languageProvider.tr('moi.moiOut')
        : languageProvider.tr('moi.title');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _MoiFlowHeader(
        title: title.toUpperCase(),
        onBack: () => Navigator.pop(context),
        onExport: _exportPdf,
        exportTooltip: languageProvider.tr('home.exportData'),
      ),
      body: _isLoading
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
                    controller: _searchController,
                    hintText: languageProvider.tr('transactionList.search'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: _buildList(languageProvider)),
              ],
            ),
    );
  }

  Widget _buildList(LanguageProvider languageProvider) {
    if (_filtered.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: MoiEmptyState(
              title: languageProvider.tr('transactionList.empty'),
              subtitle: _isSearching
                  ? languageProvider.tr('transactionList.emptyHint')
                  : (_isReceived
                        ? languageProvider.tr('transactions.addReceived')
                        : _isGiven
                        ? languageProvider.tr('transactions.addGiven')
                        : languageProvider.tr('transactions.emptyHint')),
              icon: _isSearching
                  ? HugeIcons.strokeRoundedSearchRemove
                  : HugeIcons.strokeRoundedInvoice01,
              accentColor: _accent,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: _accent,
      onRefresh: _loadTransactions,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        itemCount: _filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = _filtered[index];
          final type = t['type']?.toString().toUpperCase() ?? '';
          final isInvest = type == 'INVEST';
          final amount =
              double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
          final first =
              t['person']?['firstName']?.toString().trim() ?? '';
          final last =
              t['person']?['lastName']?.toString().trim() ??
              t['person']?['secondName']?.toString().trim() ??
              '';
          final personName = '$first $last'.trim();
          final functionName = _functionName(t);

          return MoiInvoiceListTile.moiFlow(
            isReceived: isInvest,
            title: personName.isEmpty
                ? languageProvider.tr('common.noData')
                : personName,
            subtitle: functionName.toUpperCase(),
            amount: '₹${_formatAmount(amount)}',
            onTap: () {
              Navigator.pushNamed(
                context,
                'transaction-detail-view',
                arguments: t,
              );
            },
          );
        },
      ),
    );
  }
}

class _MoiFlowHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onExport;
  final String exportTooltip;

  const _MoiFlowHeader({
    required this.title,
    required this.onBack,
    required this.onExport,
    required this.exportTooltip,
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
              AppColors.deepenAccent(primary, amount: 0.35),
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
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -18,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
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
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.sectionTitle.copyWith(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
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
