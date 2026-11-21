import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
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
  static const int _pageSize = 30;

  final TransactionServices transactionServices = TransactionServices();
  final SecureStorageService storage = SecureStorageService();
  final AlertServices alertServices = AlertServices();
  static final NumberFormat _formatter = NumberFormat('#,##,##,000.00');

  final PaginatedListState<Map<String, dynamic>> _paging = PaginatedListState(
    pageSize: _pageSize,
  );
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String? _userId;

  String get _functionName {
    final name = widget.functionData['functionName']?.toString().trim() ?? '';
    return name.isEmpty ? '—' : name;
  }

  // String get _functionDateSubtitle {
  //   final raw = widget.functionData['functionDate']?.toString();
  //   final formatted = formatFunctionDateWithDay(raw);
  //   return formatted.isEmpty ? '' : formatted.toUpperCase();
  // }

  @override
  void initState() {
    super.initState();
    searchController.addListener(searchListener);
    _scrollController.addListener(_onScroll);
    _loadTransactions(reset: true);
  }

  @override
  void dispose() {
    searchController.removeListener(searchListener);
    searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void searchListener() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
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

  Future<void> _showExportSupportSheet() {
    return showExportSupportSheet(
      context: context,
      languageProvider: context.read<LanguageProvider>(),
    );
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
      final user = await storage.get(AppVariables.userInformation);
      if (user == null) {
        if (mounted) setState(() => _paging.applyFailure(reset: reset));
        return;
      }

      _userId = user['id'].toString();
      final functionId = widget.functionData['id'].toString();
      final pageToLoad = _paging.nextPageToLoad(reset: reset);
      final searchQuery = searchController.text.trim();

      final response = await transactionServices.listTransactions({
        'userId': _userId,
        'transactionFunctionId': functionId,
        'page': pageToLoad,
        'limit': _pageSize,
        if (searchQuery.isNotEmpty) 'search': searchQuery,
      }, showLoading: false);

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
      printContent("Error loading transactions: $e");
      if (mounted) {
        setState(() => _paging.applyFailure(reset: reset));
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
      appBar: MoiAppHeader(
        title: _functionName.toTitleCase(),
        // subtitle: _functionDateSubtitle,
        showBack: true,
        onBack: () => Navigator.pop(context),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: MoiAppHeader.circleButton(
              tooltip: languageProvider.tr('transactionList.exportPdf'),
              onTap: _showExportSupportSheet,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedPdf02,
                color: primary,
                size: 20,
                strokeWidth: 1.9,
              ),
            ),
          ),
        ],
      ),
      body: _paging.isLoading && _paging.items.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                children: [
                  for (int i = 0; i < 12; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    const AppSkeletonListTile(showTrailing: true),
                  ],
                ],
              ),
            )
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
                  child: _paging.items.isEmpty
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
                      : RefreshIndicator(
                          color: primary,
                          onRefresh: () => _loadTransactions(
                            reset: true,
                            showLoading: false,
                          ),
                          child: ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.page,
                              0,
                              AppSpacing.page,
                              24,
                            ),
                            itemCount:
                                _paging.items.length +
                                (_paging.isLoadingMore || _paging.hasMore
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index >= _paging.items.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: _paging.isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: AppSkeletonListTile(
                                            showAvatar: true,
                                            showTrailing: true,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                );
                              }
                              final tx = _paging.items[index];
                              final type =
                                  tx['type']?.toString().toUpperCase() ?? '';
                              final isInvest = type == 'INVEST';
                              final amount =
                                  double.tryParse(
                                    tx['amount']?.toString() ?? '0',
                                  ) ??
                                  0.0;
                              final first =
                                  tx['person']?['firstName']
                                      ?.toString()
                                      .trim() ??
                                  '';
                              final last =
                                  tx['person']?['lastName']
                                      ?.toString()
                                      .trim() ??
                                  tx['person']?['secondName']
                                      ?.toString()
                                      .trim() ??
                                  '';
                              final personName = '$first $last'.trim();
                              final city =
                                  tx['person']?['city']?.toString().trim() ??
                                  '';
                              final location =
                                  tx['person']?['location']
                                      ?.toString()
                                      .trim() ??
                                  '';
                              final place = city.isNotEmpty ? city : location;

                              return MoiInvoiceListTile.moiFlow(
                                isReceived: isInvest,
                                accent: Theme.of(context).colorScheme.primary,
                                title: personName.isEmpty
                                    ? languageProvider.tr(
                                        'transactionList.unknown',
                                      )
                                    : personName,
                                subtitle: place.toUpperCase(),
                                amount: '₹${_formatAmount(amount)}',
                                onTap: () {
                                  AppRoute.open(
                                    context,
                                    'transaction-detail-view',
                                    arguments: tx,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
