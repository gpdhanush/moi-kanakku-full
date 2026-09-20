import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_forms/custom_dropdown.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class AddTransactionPage extends StatefulWidget {
  final String type;
  final dynamic person;
  final Map<String, dynamic>? transaction;
  final bool isEdit;

  const AddTransactionPage({
    super.key,
    required this.type,
    this.person,
    this.transaction,
    this.isEdit = false,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final txServices = TransactionServices();
  final moiServices = MoiServices();

  final TextEditingController customFunctionCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController thingsCtrl = TextEditingController();
  final TextEditingController notesCtrl = TextEditingController();

  List functionsMaster = [];
  String selectedFunction = '';
  String? selectedFunctionId;
  bool isCustomFunction = false;
  bool _isDisposed = false;

  bool get _isReceived => widget.type == 'INVEST';

  @override
  void initState() {
    super.initState();
    dateCtrl.text = AppDatePicker.formatForDisplay(DateTime.now());
    _setInitialValuesForEdit();
    getAllFunctions();
  }

  void _setInitialValuesForEdit() {
    if (!widget.isEdit || widget.transaction == null) return;
    final tx = widget.transaction!;

    selectedFunction = tx['transactionFunctionName']?.toString().trim() ?? '';
    selectedFunctionId = tx['transactionFunctionId']?.toString();

    final rawDate = tx['transactionDate']?.toString();
    if (rawDate != null && rawDate.isNotEmpty) {
      try {
        final parsed = DateTime.parse(rawDate);
        dateCtrl.text = DateFormat('dd-MMM-yyyy').format(parsed);
      } catch (_) {
        dateCtrl.text = rawDate;
      }
    }

    isCustomFunction =
        tx['isCustom'] == true ||
        tx['isCustom']?.toString().toLowerCase() == 'true' ||
        tx['isCustom']?.toString() == '1';

    customFunctionCtrl.text = _cleanText(tx['customFunction']);
    amountCtrl.text = _amountText(tx['amount']);
    thingsCtrl.text = _cleanText(tx['itemName']);
    notesCtrl.text = _cleanText(tx['notes']);
  }

  String _cleanText(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  String _amountText(dynamic value) {
    if (value == null) return '';
    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return '';
    final parsed = num.tryParse(raw);
    if (parsed == null) return '';
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }

  Future<void> getAllFunctions() async {
    try {
      final user = await storage.get(AppVariables.userInformation);
      if (user == null) return;
      final response = await moiServices.getDefaultFunctionLists({
        'userId': user['id']?.toString(),
      }, showLoading: false);

      if (response != null && response['responseType'] == 'S' && mounted) {
        final list = response['responseValue'] ?? [];
        final loaded = list is List ? List.from(list) : <dynamic>[];

        final hasCustom = loaded.any((e) {
          final name = e is Map ? e['name']?.toString() ?? '' : '';
          return _isCustomOption(name);
        });

        if (!hasCustom) {
          loaded.add({'id': null, 'name': 'மற்றவை'});
        }

        if (widget.isEdit &&
            selectedFunction.isNotEmpty &&
            !loaded.any(
              (e) =>
                  e is Map &&
                  (e['name']?.toString().trim().toLowerCase() ?? '') ==
                      selectedFunction.trim().toLowerCase(),
            )) {
          loaded.insert(0, {
            'id': selectedFunctionId,
            'name': selectedFunction,
          });
        }

        if (mounted && !_isDisposed) {
          setState(() {
            functionsMaster = loaded;
          });
        }
      }
    } catch (_) {}
  }

  bool _isCustomOption(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.contains('other') || normalized.contains('மற்றவை');
  }

  String? _extractPersonId(dynamic person) {
    if (person == null) return null;
    if (person is Map) {
      return person['id']?.toString();
    }
    try {
      final id = person.id;
      return id?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectDate() async {
    final initial = AppDatePicker.parseDisplay(dateCtrl.text.trim());
    final picked = await AppDatePicker.pick(
      context,
      initialDate: initial,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted && !_isDisposed) {
      setState(() {
        dateCtrl.text = AppDatePicker.formatForDisplay(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedFunction.isEmpty && selectedFunctionId == null) {
      alertServices.errorToast(
        context.read<LanguageProvider>().tr('transactions.selectFunction'),
      );
      return;
    }
    if (isCustomFunction && customFunctionCtrl.text.trim().isEmpty) {
      alertServices.errorToast(
        context.read<LanguageProvider>().tr(
          'transactions.customFunctionRequired',
        ),
      );
      return;
    }
    if (amountCtrl.text.trim().isEmpty && thingsCtrl.text.trim().isEmpty) {
      alertServices.errorToast(
        context.read<LanguageProvider>().tr(
          'transactions.amountOrThingRequired',
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      alertServices.showLoading();
      final user = await storage.get(AppVariables.userInformation);
      final userId = user != null ? user['id']?.toString() : null;
      final personId = _extractPersonId(widget.person);

      if (userId == null) {
        alertServices.errorToast(
          context.read<LanguageProvider>().tr('transactions.userInfoMissing'),
        );
        return;
      }
      if (!widget.isEdit && personId == null) {
        alertServices.errorToast(
          context.read<LanguageProvider>().tr('transactions.personInfoMissing'),
        );
        return;
      }

      String apiDate = dateCtrl.text;
      try {
        final d = DateFormat('dd-MMM-yyyy', 'en').parse(dateCtrl.text.trim());
        apiDate = DateFormat('yyyy-MM-dd').format(d);
      } catch (_) {}

      final hasThings = thingsCtrl.text.trim().isNotEmpty;
      final hasAmount = amountCtrl.text.trim().isNotEmpty;
      final itemType = hasThings && !hasAmount ? 'THINGS' : 'MONEY';

      final response = widget.isEdit
          ? await txServices.updateTransaction({
              'transactionId': widget.transaction?['id']?.toString(),
              'userId': userId,
              'transactionDate': apiDate,
              'type': widget.type,
              'itemName': thingsCtrl.text.trim().isEmpty
                  ? null
                  : thingsCtrl.text.trim(),
              'amount': int.tryParse(amountCtrl.text.trim()) ?? 0,
              'notes': notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              'isCustom': isCustomFunction,
              'is_custom': isCustomFunction,
              'customFunction': isCustomFunction
                  ? customFunctionCtrl.text.trim()
                  : null,
              'transactionFunctionId': selectedFunctionId,
              'transactionFunctionName': selectedFunction,
            }, showLoading: false)
          : await txServices.createTransactionV2({
              'userId': userId,
              'personId': personId,
              'transactionDate': apiDate,
              'type': widget.type,
              'itemType': itemType,
              'itemName': thingsCtrl.text.trim(),
              'amount': int.tryParse(amountCtrl.text.trim()) ?? 0,
              'notes': notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              'is_custom': isCustomFunction,
              'customFunction': isCustomFunction
                  ? customFunctionCtrl.text.trim()
                  : null,
              'transactionFunctionId': selectedFunctionId,
              'transactionFunctionName': selectedFunction,
            }, showLoading: false);

      if (response != null && response['responseType'] == 'S') {
        alertServices.successToast(
          response['responseValue']['message']?.toString() ??
              (widget.isEdit ? 'Updated' : 'Added'),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        alertServices.errorToast(
          response?['responseValue']?['message']?.toString() ??
              (widget.isEdit ? 'Failed to update' : 'Failed to add'),
        );
      }
    } catch (e) {
      printContent('Error creating/updating transaction: $e');
      alertServices.errorToast(
        context.read<LanguageProvider>().tr('common.tryAgain'),
      );
    } finally {
      alertServices.hideLoading();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    FocusManager.instance.primaryFocus?.unfocus();
    customFunctionCtrl.dispose();
    dateCtrl.dispose();
    amountCtrl.dispose();
    thingsCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final accent = _isReceived ? primary : AppColors.moiGiven;
        final title = widget.isEdit
            ? languageProvider.tr('transactions.updateTitle')
            : _isReceived
            ? languageProvider.tr('transactions.newInvest')
            : languageProvider.tr('transactions.newReturn');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiFlowAppHeader(
            title: title.toUpperCase(),
            accent: accent,
            onBack: () => Navigator.pop(context),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.lg,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFunctionDropdown(languageProvider),
                        if (isCustomFunction) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildCustomFunctionField(languageProvider),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _buildDateField(languageProvider),
                        const SizedBox(height: AppSpacing.md),
                        TextFormWidget(
                          title: languageProvider.tr('transactions.amount'),
                          controller: amountCtrl,
                          prefixIcon: HugeIcons.strokeRoundedMoney01,
                          prefixText: '₹ ',
                          maxLength: 7,
                          required: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormWidget(
                          title: languageProvider.tr('transactions.thing'),
                          controller: thingsCtrl,
                          prefixIcon: HugeIcons.strokeRoundedGift,
                          required: false,
                          maxLines: 3,
                          enableMic: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormWidget(
                          title: languageProvider.tr('transactions.notes'),
                          controller: notesCtrl,
                          prefixIcon: HugeIcons.strokeRoundedNote,
                          required: false,
                          maxLines: 3,
                          enableMic: true,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _BottomSaveBar(
                title: languageProvider.tr(
                  widget.isEdit ? 'common.update' : 'common.save',
                ),
                accent: accent,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunctionDropdown(LanguageProvider languageProvider) {
    return CustomDropdown(
      key: ValueKey(
        'function_dropdown_${selectedFunction}_${functionsMaster.length}',
      ),
      initialSelection: selectedFunction.isNotEmpty ? selectedFunction : null,
      title: languageProvider.tr('transactions.selectFunction'),
      required: true,
      search: false,
      enableMic: false,
      showArrow: true,
      prefixIcon: HugeIcons.strokeRoundedWedding,
      notFoundText: languageProvider.tr('transactions.functionNotFound'),
      dropdownMenuEntries: functionsMaster
          .map((e) => e is Map ? e['name']?.toString() ?? '' : '')
          .where((name) => name.isNotEmpty)
          .toList()
          .map<DropdownMenuEntry<String>>((value) {
            return DropdownMenuEntry<String>(
              value: value,
              label: value.toUpperCase(),
            );
          })
          .toList(),
      onSelected: (value) {
        if (!mounted || _isDisposed) return;
        FocusScope.of(context).unfocus();

        final selectedValue = value?.toString().trim() ?? '';
        if (selectedValue.isEmpty) return;

        final selected = functionsMaster.where((element) {
          if (element is! Map) return false;
          final name = element['name']?.toString().trim() ?? '';
          return name.toLowerCase() == selectedValue.toLowerCase();
        }).toList();

        setState(() {
          selectedFunction = selectedValue;
          selectedFunctionId = selected.isNotEmpty
              ? selected[0]['id']?.toString()
              : null;
          isCustomFunction = _isCustomOption(selectedFunction);
          if (!isCustomFunction) {
            customFunctionCtrl.clear();
          }
        });
      },
    );
  }

  Widget _buildCustomFunctionField(LanguageProvider languageProvider) {
    return TextFormWidget(
      title: languageProvider.tr('transactions.customFunction'),
      controller: customFunctionCtrl,
      prefixIcon: HugeIcons.strokeRoundedPencilEdit02,
      required: true,
      enableMic: true,
      validator: (value) => value.toString().trim().isEmpty
          ? languageProvider.tr('transactions.customFunctionRequired')
          : null,
    );
  }

  Widget _buildDateField(LanguageProvider languageProvider) {
    return TextFormWidget(
      title: languageProvider.tr('transactions.date'),
      controller: dateCtrl,
      prefixIcon: HugeIcons.strokeRoundedCalendar01,
      required: true,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) => value.toString().isEmpty
          ? languageProvider.tr('transactions.dateRequired')
          : null,
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  final String title;
  final Color accent;
  final VoidCallback onPressed;

  const _BottomSaveBar({
    required this.title,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            12,
            AppSpacing.page,
            12,
          ),
          child: AppButton(title: title, onPressed: onPressed),
        ),
      ),
    );
  }
}
