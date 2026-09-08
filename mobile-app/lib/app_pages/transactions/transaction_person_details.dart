import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'package:moi/app_utils/app_widgets/moi_list_item.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class TransactionPersonDetails extends StatefulWidget {
  final PersonResponseModel person;

  const TransactionPersonDetails({super.key, required this.person});

  @override
  State<TransactionPersonDetails> createState() =>
      _TransactionPersonDetailsState();
}

class _TransactionPersonDetailsState extends State<TransactionPersonDetails> {
  AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final txServices = TransactionServices();

  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    pageTitleLogs("Transaction Person Details");
    printContent("Person ID: ${widget.person.id}");
    _fetchTransactions();
  }

  /// helper to format incoming ISO date string for display
  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      DateTime d = DateTime.parse(iso).toLocal();
      return DateFormat('dd-MMM-yyyy').format(d);
      // return DateFormat('dd-MMM-yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final numVal = value is num
        ? value
        : int.tryParse(value.toString().split('.').first) ?? 0;
    if (numVal == 0) return '0';
    final formatter = NumberFormat('#,##,000.00');
    return formatter.format(numVal);
  }

  Future<void> _fetchTransactions() async {
    try {
      final userData = await storage.get(AppVariables.userInformation);
      if (userData == null || userData is! Map) return;
      final params = {
        'userId': userData['id']?.toString(),
        'personId': widget.person.id,
      };
      final response = await txServices.listTransactions(params);
      if (response != null && response['responseType'] == 'S') {
        final rv = response['responseValue'];
        if (rv is List) {
          final txList = List<Map<String, dynamic>>.from(
            rv.map(
              (e) =>
                  e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{},
            ),
          );
          // Sort by createdAt descending (most recent first)
          txList.sort((a, b) {
            final aDate = a['createdAt']?.toString() ?? '';
            final bDate = b['createdAt']?.toString() ?? '';
            return bDate.compareTo(aDate);
          });
          setState(() {
            transactions = txList;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.person.firstName.toString().toTitleCase(),
        action: [],
      ),
      body: Column(
        children: [
          _buildActionButtons(),
          Expanded(child: _buildTransactionsList()),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  "add-transaction",
                  arguments: {"type": "INVEST", "person": widget.person},
                );
                if (result == true && mounted) {
                  await _fetchTransactions();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 3, 153, 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                context.read<LanguageProvider>().tr('moi.moiIn'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Colors.white,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  "add-transaction",
                  arguments: {"type": "RETURN", "person": widget.person},
                );
                if (result == true && mounted) {
                  await _fetchTransactions();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(
                context.read<LanguageProvider>().tr('moi.moiOut'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: Colors.white,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          context.read<LanguageProvider>().tr('common.noData'),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontFamily: 'Roboto',
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: transactions.length,
      separatorBuilder: (_, io) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final type = tx['type']?.toString() ?? '';
        final isInvest = type == 'INVEST';
        printContent(
          "isInvest: $isInvest, amount: ${tx['amount']}, date: ${tx['transactionDate']}",
        );

        final isCustom =
            tx['isCustom'] == true || tx['isCustom']?.toString() == 'true';

        final functionName = isCustom
            ? tx['customFunction'] ?? '-'
            : tx['transactionFunctionName']?.toString() ?? '-';

        final date = _formatDate(tx['transactionDate']?.toString());
        final amount = tx['amount'];

        final amountColor = isInvest
            ? Colors.green.shade700
            : Colors.red.shade700;

        final iconColor = isInvest
            ? Colors.green.shade700
            : Colors.red.shade700;

        return MoiListItem(
          leadingIcon: isInvest ? Icons.arrow_downward : Icons.arrow_upward,
          accentColor: iconColor,
          title: functionName.toString(),
          subtitle: date,
          onTap: () => _showTransactionSheet(tx),
          trailing: amount != null && amount.toString().isNotEmpty
              ? Text(
                  '₹ ${_formatNumber(amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                    fontFamily: 'amountFont',
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showTransactionSheet(Map<String, dynamic> transaction) {
    final colorScheme = Theme.of(context).colorScheme;
    showCustomActionSheet(
      context: context,
      title: context.read<LanguageProvider>().tr('common.chooseAction'),
      titleColor: colorScheme.primary,
      actions: [
        ActionSheetItem(
          icon: Icons.visibility_outlined,
          title: context.read<LanguageProvider>().tr('common.viewDetails'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _viewTransactionDetails(transaction);
          },
        ),
        ActionSheetItem(
          icon: Icons.edit_outlined,
          title: context.read<LanguageProvider>().tr('common.edit'),
          color: colorScheme.primary,
          onPressed: (context) async {
            Navigator.pop(context);
            _editTransaction(transaction);
          },
        ),
        ActionSheetItem(
          icon: Icons.delete_outlined,
          title: context.read<LanguageProvider>().tr('common.delete'),
          color: Colors.redAccent,
          onPressed: (context) async {
            Navigator.pop(context);
            _confirmDeleteTransaction(transaction);
          },
        ),
        ActionSheetItem(
          icon: Icons.cancel_outlined,
          title: context.read<LanguageProvider>().tr('common.cancel'),
          color: colorScheme.primary,
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

  void _confirmDeleteTransaction(Map<String, dynamic> transaction) {
    alertServices
        .confirmAlert(
          context,
          context.read<LanguageProvider>().tr(
            'transactions.deleteTransactionConfirmation',
          ),
        )
        .then((confirmed) {
          if (confirmed == true) {
            _deleteTransaction(transaction);
          }
        });
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    try {
      alertServices.showLoading();
      final transactionId = transaction['id']?.toString();
      if (transactionId == null || transactionId.isEmpty) {
        alertServices.hideLoading();
        alertServices.errorToast('பரிவர்த்தனை ID கிடைக்கவில்லை');
        return;
      }

      final response = await txServices.deleteTransaction({
        'transactionId': transactionId,
      }, showLoading: false);

      alertServices.hideLoading();

      if (response != null && response['responseType'] == 'S') {
        final message =
            response['responseValue']?['message']?.toString() ??
            'பரிவர்த்தனை வெற்றிகரமாக நீக்கப்பட்டது';
        alertServices.successToast(message);
        await _fetchTransactions();
      } else {
        final errorMessage =
            response?['responseValue']?['message']?.toString() ??
            'பரிவர்த்தனையை நீக்க முடியவில்லை';
        alertServices.errorToast(errorMessage);
      }
    } catch (e) {
      alertServices.hideLoading();
      alertServices.errorToast('பிழை ஏற்பட்டது');
    }
  }
}
