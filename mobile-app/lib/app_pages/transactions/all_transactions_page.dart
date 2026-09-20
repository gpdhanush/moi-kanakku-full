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
  static const int _pageSize = 30;

  final TransactionServices _txServices = TransactionServices();
  final SecureStorageService _storage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PaginatedListState<Map<String, dynamic>> _paging = PaginatedListState(
    pageSize: _pageSize,
  );
  Timer? _debounce;
  String? _userId;

  bool get _isReceived => widget.type == 'INVEST';
  bool get _isGiven => widget.type == 'RETURN';
  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  Color get _accent => _isReceived ? AppColors.moiReceived : AppColors.moiGiven;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadTransactions(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _loadTransactions(reset: true);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (!_paging.hasMore || _paging.isLoadingMore || _paging.isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadTransactions(reset: false);
    }
  }

  Future<void> _loadTransactions({
    required bool reset,
    bool showLoading = true,
  }) async {
    if (reset) {
      if (mounted) {
        setState(() => _paging.prepareReset(showLoading: showLoading));
      }
    } else {
      if (!_paging.prepareLoadMore()) return;
      if (mounted) setState(() {});
    }

    try {
      _userId ??= await _resolveUserId();
      if (_userId == null || _userId!.isEmpty) {
        if (mounted) {
          setState(() => _paging.applyFailure(reset: reset));
        }
        return;
      }

      final pageToLoad = _paging.nextPageToLoad(reset: reset);
      final searchQuery = _searchController.text.trim();
      final params = <String, dynamic>{
        'userId': _userId,
        'page': pageToLoad,
        'limit': _pageSize,
        if (widget.type == 'INVEST' || widget.type == 'RETURN')
          'type': widget.type,
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      };

      final response = await _txServices.listTransactions(
        params,
        showLoading: false,
      );

      if (!mounted) return;

      if (response != null &&
          response is Map &&
          response['responseType'] == 'S') {
        final chunk = PaginatedResponseParser.mapChunk(
          response['responseValue'],
        );
        final total = PaginatedResponseParser.parseTotal(
          response['count'],
          fallback: reset ? chunk.length : _paging.totalCount,
        );
        final hasMore = PaginatedResponseParser.parseHasMore(
          hasMore: response['hasMore'],
          chunkLength: chunk.length,
          pageSize: _pageSize,
          total: total,
          offsetAfter: (pageToLoad - 1) * _pageSize + chunk.length,
        );
        setState(() {
          _paging.applySuccess(
            reset: reset,
            chunk: chunk,
            total: total,
            responseHasMore: hasMore,
            pageLoaded: pageToLoad,
          );
        });
      } else {
        setState(() => _paging.applyFailure(reset: reset));
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
      if (mounted) {
        setState(() => _paging.applyFailure(reset: reset));
      }
    }
  }

  Future<String?> _resolveUserId() async {
    final user = await _storage.get(AppVariables.userInformation);
    if (user == null || user is! Map) return null;
    return user['id']?.toString();
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

  /// Loads all pages for PDF export (server-side filters applied).
  Future<List<Map<String, dynamic>>> _fetchAllForExport() async {
    final userId = _userId ?? await _resolveUserId();
    if (userId == null || userId.isEmpty) return [];

    final all = <Map<String, dynamic>>[];
    var page = 1;
    var hasMore = true;
    final searchQuery = _searchController.text.trim();

    while (hasMore) {
      final response = await _txServices.listTransactions({
        'userId': userId,
        'page': page,
        'limit': 100,
        if (widget.type == 'INVEST' || widget.type == 'RETURN')
          'type': widget.type,
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      }, showLoading: false);

      if (response == null ||
          response is! Map ||
          response['responseType'] != 'S') {
        break;
      }
      final chunk = PaginatedResponseParser.mapChunk(response['responseValue']);
      all.addAll(chunk);
      hasMore = response['hasMore'] == true && chunk.isNotEmpty;
      page += 1;
      if (page > 500) break;
    }
    return all;
  }

  Future<void> _exportPdf() async {
    var dialogOpen = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogOpen = true;

      final user = await _storage.get(AppVariables.userInformation);
      final transactions = await _fetchAllForExport();

      if (user == null) {
        if (mounted) {
          _alertServices.errorToast(
            context.read<LanguageProvider>().tr('home.userDetailsNotFound'),
          );
        }
        return;
      }
      await ExportService.exportTransactionsToPdf(
        transactions: transactions,
        userDetails: user,
      );
      if (mounted) {
        _alertServices.successToast(
          context.read<LanguageProvider>().tr('home.exportedSuccessfully'),
        );
      }
    } catch (e) {
      debugPrint('Error exporting: $e');
      if (mounted) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('home.exportError'),
        );
      }
    } finally {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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
      body: _paging.isLoading && _paging.items.isEmpty
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
    if (_paging.items.isEmpty) {
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

    final itemCount =
        _paging.items.length +
        (_paging.isLoadingMore || _paging.hasMore ? 1 : 0);

    return RefreshIndicator(
      color: _accent,
      onRefresh: () => _loadTransactions(reset: true, showLoading: false),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= _paging.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _paging.isLoadingMore
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _accent,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final t = _paging.items[index];
          final type = t['type']?.toString().toUpperCase() ?? '';
          final isInvest = type == 'INVEST';
          final amount = double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
          final first = t['person']?['firstName']?.toString().trim() ?? '';
          final last =
              t['person']?['lastName']?.toString().trim() ??
              t['person']?['secondName']?.toString().trim() ??
              '';
          final personName = '$first $last'.trim();
          final functionName = _functionName(t);

          return MoiInvoiceListTile.moiFlow(
            isReceived: isInvest,
            accent: Theme.of(context).colorScheme.primary,
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
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, AppColors.deepenAccent(primary, amount: 0.35)],
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
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: Theme.of(context).colorScheme.primary,
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
