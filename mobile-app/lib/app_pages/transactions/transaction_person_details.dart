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
  final AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final TransactionServices txServices = TransactionServices();

  List<Map<String, dynamic>> transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    pageTitleLogs('Transaction Person Details');
    printContent('Person ID: ${widget.person.id}');
    _fetchTransactions();
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

  Future<void> _fetchTransactions() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final userData = await storage.get(AppVariables.userInformation);
      if (userData == null || userData is! Map) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await txServices.listTransactions({
        'userId': userData['id']?.toString(),
        'personId': widget.person.id,
      }, showLoading: false);

      if (response != null && response['responseType'] == 'S') {
        final rv = response['responseValue'];
        if (rv is List) {
          final txList = List<Map<String, dynamic>>.from(
            rv.map(
              (e) =>
                  e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
            ),
          );
          txList.sort((a, b) {
            final aDate = a['createdAt']?.toString() ?? '';
            final bDate = b['createdAt']?.toString() ?? '';
            return bDate.compareTo(aDate);
          });
          if (mounted) {
            setState(() {
              transactions = txList;
              _isLoading = false;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          transactions = [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
              if (result == true && mounted) await _fetchTransactions();
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
              if (result == true && mounted) await _fetchTransactions();
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (transactions.isEmpty) {
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

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      itemCount: transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final type = tx['type']?.toString() ?? '';
        final isInvest = type == 'INVEST';
        final isCustom =
            tx['isCustom'] == true || tx['isCustom']?.toString() == 'true';
        final functionName = isCustom
            ? tx['customFunction'] ?? '—'
            : tx['transactionFunctionName']?.toString() ?? '—';
        final date = _formatDate(tx['transactionDate']?.toString());
        final amount = tx['amount'];
        final accent = isInvest ? AppColors.moiReceived : AppColors.moiGiven;

        return _TransactionCard(
          title: functionName.toString().toUpperCase(),
          subtitle: date,
          amountText: amount != null && amount.toString().isNotEmpty
              ? '₹ ${_formatNumber(amount)}'
              : null,
          accent: accent,
          isInvest: isInvest,
          onTap: () => _showTransactionSheet(tx),
        );
      },
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
      await _fetchTransactions();
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
        await _fetchTransactions();
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

class _TransactionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? amountText;
  final Color accent;
  final bool isInvest;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.accent,
    required this.isInvest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accent.withValues(alpha: 0.06),
        highlightColor: accent.withValues(alpha: 0.03),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffE4E4E7)),
            boxShadow: AppShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: isInvest
                      ? HugeIcons.strokeRoundedArrowDownLeft01
                      : HugeIcons.strokeRoundedArrowUpRight01,
                  color: accent,
                  size: 18,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (amountText != null) ...[
                const SizedBox(width: 8),
                Text(
                  amountText!,
                  style: AppTypography.amountMedium.copyWith(
                    color: accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
