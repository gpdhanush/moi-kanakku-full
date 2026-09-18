import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';

class TransactionPersonDetails extends StatefulWidget {
  final PersonResponseModel person;

  const TransactionPersonDetails({super.key, required this.person});

  @override
  State<TransactionPersonDetails> createState() =>
      _TransactionPersonDetailsState();
}

class _TransactionPersonDetailsState extends State<TransactionPersonDetails> {
  static const int _pageSize = 30;

  final AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final TransactionServices txServices = TransactionServices();
  final ScrollController _scrollController = ScrollController();
  final PaginatedListState<Map<String, dynamic>> _paging =
      PaginatedListState(pageSize: _pageSize);

  String? _userId;

  @override
  void initState() {
    super.initState();
    pageTitleLogs('Transaction Person Details');
    printContent('Person ID: ${widget.person.id}');
    _scrollController.addListener(_onScroll);
    _fetchTransactions(reset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String get _displayName {
    final first = widget.person.firstName?.toString().trim() ?? '';
    final second = widget.person.secondName?.toString().trim() ?? '';
    return '$first $second'.trim().toTitleCase();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat('dd-MMM-yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final numVal = value is num
        ? value
        : num.tryParse(value.toString()) ?? 0;
    if (numVal == 0) return '0';
    return NumberFormat('#,##,000.00').format(numVal);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (!_paging.hasMore || _paging.isLoadingMore || _paging.isLoading) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _fetchTransactions(reset: false);
    }
  }

  Future<void> _fetchTransactions({
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
      final userData = await storage.get(AppVariables.userInformation);
      if (userData == null || userData is! Map) {
        if (mounted) setState(() => _paging.applyFailure(reset: reset));
        return;
      }

      _userId = userData['id']?.toString();
      final pageToLoad = _paging.nextPageToLoad(reset: reset);

      final response = await txServices.listTransactions({
        'userId': _userId,
        'personId': widget.person.id,
        'page': pageToLoad,
        'limit': _pageSize,
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
    } catch (_) {
      if (mounted) {
        setState(() => _paging.applyFailure(reset: reset));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final title = _displayName.isEmpty ? '—' : _displayName.toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _PersonDetailsHeader(
            title: title,
            onBack: () => Navigator.pop(context),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(languageProvider),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      languageProvider
                          .tr('transactions.transactionsSection')
                          .toUpperCase(),
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
              Expanded(child: _buildTransactionsList(languageProvider, primary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(LanguageProvider languageProvider) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            label: languageProvider.tr('moi.moiIn'),
            color: AppColors.moiReceived,
            icon: HugeIcons.strokeRoundedArrowDownLeft01,
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                'add-transaction',
                arguments: {'type': 'INVEST', 'person': widget.person},
              );
              if (result == true && mounted) {
                await _fetchTransactions(reset: true, showLoading: false);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            label: languageProvider.tr('moi.moiOut'),
            color: AppColors.moiGiven,
            icon: HugeIcons.strokeRoundedArrowUpRight01,
            onTap: () async {
              final result = await Navigator.pushNamed(
                context,
                'add-transaction',
                arguments: {'type': 'RETURN', 'person': widget.person},
              );
              if (result == true && mounted) {
                await _fetchTransactions(reset: true, showLoading: false);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(
    LanguageProvider languageProvider,
    Color primary,
  ) {
    if (_paging.isLoading && _paging.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (_paging.items.isEmpty) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: MoiEmptyState(
              title: languageProvider.tr('transactions.noTransactions'),
              subtitle: languageProvider.tr('transactions.noTransactionsHint'),
              icon: HugeIcons.strokeRoundedInvoice01,
              accentColor: primary,
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: () => _fetchTransactions(reset: true, showLoading: false),
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
        itemCount: _paging.items.length +
            (_paging.isLoadingMore || _paging.hasMore ? 1 : 0),
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
                          color: primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }

          final tx = _paging.items[index];
          final type = tx['type']?.toString() ?? '';
          final isInvest = type == 'INVEST';
          final isCustom =
              tx['isCustom'] == true || tx['isCustom']?.toString() == 'true';
          final functionName = isCustom
              ? tx['customFunction'] ?? '—'
              : tx['transactionFunctionName']?.toString() ?? '—';
          final date = _formatDate(tx['transactionDate']?.toString());
          final amount = tx['amount'];
          final subtitleParts = <String>[
            if (date.isNotEmpty && date != '-') date,
          ];

          return MoiInvoiceListTile.moiFlow(
            isReceived: isInvest,
            title: functionName.toString().toUpperCase(),
            subtitle: subtitleParts.join(' • '),
            amount: amount != null && amount.toString().isNotEmpty
                ? '₹${_formatNumber(amount)}'
                : '₹0',
            onTap: () => _showTransactionSheet(tx),
          );
        },
      ),
    );
  }

  void _showTransactionSheet(Map<String, dynamic> transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    showMoiActionSheet(
      context: context,
      title: languageProvider.tr('common.chooseAction'),
      titleColor: colorScheme.primary,
      actions: [
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedView,
          title: languageProvider.tr('common.viewDetails'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _viewTransactionDetails(transaction);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedPencilEdit02,
          title: languageProvider.tr('common.edit'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _editTransaction(transaction);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedDelete02,
          title: languageProvider.tr('common.delete'),
          isDestructive: true,
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            await Future<void>.delayed(const Duration(milliseconds: 220));
            if (!mounted) return;
            await _confirmDeleteTransaction(transaction);
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedCancel01,
          title: languageProvider.tr('common.cancel'),
          isCancel: true,
          onPressed: (context) async {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _viewTransactionDetails(Map<String, dynamic> transaction) {
    Navigator.pushNamed(
      context,
      'transaction-detail-view',
      arguments: transaction,
    );
  }

  Future<void> _editTransaction(Map<String, dynamic> transaction) async {
    final txType = transaction['type']?.toString() ?? 'RETURN';
    final result = await Navigator.pushNamed(
      context,
      'add-transaction',
      arguments: {
        'type': txType,
        'person': widget.person,
        'transaction': transaction,
        'isEdit': true,
      },
    );

    if (result == true && mounted) {
      await _fetchTransactions(reset: true, showLoading: false);
    }
  }

  Future<void> _confirmDeleteTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final languageProvider = context.read<LanguageProvider>();
    final confirmed = await showMoiConfirmSheet(
      context: context,
      title: languageProvider.tr('transactions.deleteTransactionTitle'),
      message: languageProvider.tr(
        'transactions.deleteTransactionConfirmation',
      ),
      confirmLabel: languageProvider.tr('common.delete'),
      cancelLabel: languageProvider.tr('common.cancel'),
      icon: HugeIcons.strokeRoundedDelete02,
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await _deleteTransaction(transaction);
    }
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final languageProvider = context.read<LanguageProvider>();

    try {
      alertServices.showLoading();
      final transactionId = transaction['id']?.toString();
      if (transactionId == null || transactionId.isEmpty) {
        alertServices.hideLoading();
        alertServices.errorToast(
          languageProvider.tr('transactions.transactionIdMissing'),
        );
        return;
      }

      final response = await txServices.deleteTransaction({
        'transactionId': transactionId,
      }, showLoading: false);

      alertServices.hideLoading();

      if (response != null && response['responseType'] == 'S') {
        final message =
            response['responseValue']?['message']?.toString() ??
            languageProvider.tr('transactions.transactionDeleted');
        alertServices.successToast(message);
        await _fetchTransactions(reset: true, showLoading: false);
      } else {
        final errorMessage =
            response?['responseValue']?['message']?.toString() ??
            languageProvider.tr('transactions.transactionDeleteFailed');
        alertServices.errorToast(errorMessage);
      }
    } catch (_) {
      alertServices.hideLoading();
      alertServices.errorToast(
        languageProvider.tr('transactions.transactionDeleteFailed'),
      );
    }
  }
}

class _PersonDetailsHeader extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _PersonDetailsHeader({
    required this.title,
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
            Positioned(
              bottom: -36,
              left: 48,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
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
          height: 1.15,
        ),
      ),
      actions: const [SizedBox(width: 54)],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final List<List<dynamic>> icon;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: Colors.white,
                size: 16,
                strokeWidth: 1.9,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

