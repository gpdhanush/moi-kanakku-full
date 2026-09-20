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

class AddEditPage extends StatefulWidget {
  const AddEditPage({super.key, required this.data, this.requestParams});
  final dynamic data;
  final Map<String, dynamic>? requestParams;

  @override
  State<AddEditPage> createState() => _AddEditPageState();
}

class _AddEditPageState extends State<AddEditPage> {
  bool isEditMode = false;
  String? userId;
  final _formKey = GlobalKey<FormState>();
  final AlertServices alertServices = AlertServices();
  final SecureStorageService storage = SecureStorageService();
  final txServices = TransactionServices();
  final moiServices = MoiServices();

  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController secondNameCtrl = TextEditingController();
  final TextEditingController businessCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();

  final TextEditingController customFunctionCtrl = TextEditingController();
  final TextEditingController functionDropdownCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController thingsCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();

  List functionsMaster = [];
  String selectedFunction = '';
  String? selectedPersonId;
  String? selectedFunctionId;
  String? transactionId;
  bool isCustomFunction = false;

  @override
  void initState() {
    super.initState();
    _initializeDate();
    _initPage();
  }

  Future<void> _initPage() async {
    await _loadUser();
    await getAllFunctions();
  }

  Future<void> _loadUser() async {
    final user = await storage.get(AppVariables.userInformation);
    userId = user?['id']?.toString();
  }

  void _initializeDate() {
    dateCtrl.text = DateFormat('dd-MMM-yyyy', 'en').format(DateTime.now());
  }

  String _displayDateToApi(String display) {
    String apiDate = display.trim();
    try {
      if (apiDate.contains('-')) {
        final parts = apiDate.split('-');
        if (parts.length == 3) {
          if (parts[1].length == 3) {
            final date = DateFormat('dd-MMM-yyyy', 'en').parse(apiDate);
            apiDate = DateFormat('yyyy-MM-dd').format(date);
          } else if (parts[0].length == 4) {
            // already YYYY-MM-DD
          } else {
            final date = DateFormat('dd-MM-yyyy').parse(apiDate);
            apiDate = DateFormat('yyyy-MM-dd').format(date);
          }
        }
      } else if (apiDate.contains('/')) {
        final parts = apiDate.split('/');
        if (parts.length == 3) {
          apiDate =
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
        }
      }
    } catch (_) {}
    return apiDate;
  }

  bool _isCustomOption(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.contains('other') || normalized.contains('மற்றவை');
  }

  Future<Map<String, dynamic>> _buildTransactionParams() async {
    final firstName = firstNameCtrl.text.trim();
    final secondName = secondNameCtrl.text.trim();
    final business = businessCtrl.text.trim();
    final city = cityCtrl.text.trim();
    final mobile = mobileCtrl.text.trim();
    final itemName = thingsCtrl.text.trim();
    final amount = int.tryParse(amountCtrl.text.trim()) ?? 0;
    final notes = remarksCtrl.text.trim();
    final isCustom = isCustomFunction;

    final Map<String, dynamic> params = {
      'userId': userId,
      'firstName': firstName.isNotEmpty ? firstName : null,
      'secondName': secondName.isNotEmpty ? secondName : null,
      'business': business.isNotEmpty ? business : null,
      'city': city.isNotEmpty ? city : null,
      'mobile': mobile.isNotEmpty ? mobile : null,
      'transactionDate': _displayDateToApi(dateCtrl.text),
      'type': _getTransactionType(),
      'itemName': itemName,
      'amount': amountCtrl.text.trim().isNotEmpty ? amount : 0,
      'notes': notes.isNotEmpty ? notes : null,
      'is_custom': isCustom,
      'customFunction': isCustom ? customFunctionCtrl.text.trim() : null,
      'transactionFunctionId': selectedFunctionId,
      'transactionFunctionName': selectedFunction,
    };

    if (transactionId != null && transactionId!.isNotEmpty) {
      params['id'] = transactionId;
    }

    return params;
  }

  Future<void> _submitTransaction() async {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final params = await _buildTransactionParams();
      final response = transactionId != null && transactionId!.isNotEmpty
          ? await txServices.updateTransaction(params, showLoading: false)
          : await txServices.createTransactionV2(params, showLoading: false);

      if (mounted) Navigator.pop(context);

      if (response != null && response['responseType'] == 'S') {
        alertServices.successToast(
          response['responseValue']['message']?.toString() ??
              context.read<LanguageProvider>().tr('transactions.saved'),
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        alertServices.errorToast(
          response['responseValue']['message']?.toString() ??
              context.read<LanguageProvider>().tr('transactions.saveFailed'),
        );
      }
    } catch (_) {
      if (mounted) Navigator.pop(context);
      alertServices.errorToast(
        context.read<LanguageProvider>().tr('common.tryAgain'),
      );
    }
  }

  Future<void> getAllFunctions() async {
    try {
      if (userId == null) return;

      final response = await moiServices.getMoiDefaultFunctionsDropdown({
        'userId': userId,
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

        setState(() {
          functionsMaster = loaded;
        });
      }
    } catch (_) {}
  }

  String _getTransactionType() {
    final args = widget.data;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map && args['type'] != null) return args['type'].toString();
    if (args is List &&
        args.isNotEmpty &&
        args[0] is Map &&
        args[0]['type'] != null) {
      return args[0]['type'].toString();
    }
    return 'RETURN';
  }

  Future<void> _selectDate() async {
    final initial = AppDatePicker.parseDisplay(dateCtrl.text.trim());
    final picked = await AppDatePicker.pick(
      context,
      initialDate: initial,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateCtrl.text = AppDatePicker.formatForDisplay(picked);
      });
    }
  }

  Future<void> _saveMoiReturnInvest() async {
    await _submitTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isReceived = _getTransactionType() != 'RETURN';
        final primary = Theme.of(context).colorScheme.primary;
        final accent = isReceived ? primary : AppColors.moiGiven;
        final title = isReceived
            ? languageProvider.tr('transactions.newInvest')
            : languageProvider.tr('transactions.newReturn');
        final saveLabel = transactionId != null && transactionId!.isNotEmpty
            ? languageProvider.tr('common.update')
            : languageProvider.tr('common.save');

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          accent: accent,
                          title: languageProvider
                              .tr('profile.personalInformation')
                              .toUpperCase(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._buildPersonFields(languageProvider),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionHeader(
                          accent: accent,
                          title: languageProvider
                              .tr('transactions.transactionsSection')
                              .toUpperCase(),
                        ),
                        const SizedBox(height: AppSpacing.sm),
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
                          required: false,
                          maxLength: 7,
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
                          enableMic: true,
                          textInputAction: TextInputAction.done,
                          maxLines: 3,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormWidget(
                          title: languageProvider.tr('transactions.notes'),
                          controller: remarksCtrl,
                          prefixIcon: HugeIcons.strokeRoundedNote,
                          required: false,
                          enableMic: true,
                          textInputAction: TextInputAction.done,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _BottomSaveBar(
                title: saveLabel,
                accent: accent,
                onPressed: _saveMoiReturnInvest,
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPersonFields(LanguageProvider languageProvider) {
    return [
      TextFormWidget(
        title: languageProvider.tr('transactions.city'),
        enableMic: true,
        controller: cityCtrl,
        prefixIcon: HugeIcons.strokeRoundedCity01,
        required: true,
        textCapitalization: TextCapitalization.characters,
        validator: (value) => value.toString().isEmpty
            ? languageProvider.tr('transactions.cityRequired')
            : null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormWidget(
        title: languageProvider.tr('transactions.firstName'),
        controller: firstNameCtrl,
        prefixIcon: HugeIcons.strokeRoundedUser,
        enableMic: true,
        required: true,
        textCapitalization: TextCapitalization.characters,
        validator: (value) => value.toString().isEmpty
            ? languageProvider.tr('transactions.nameRequired')
            : null,
      ),
      const SizedBox(height: AppSpacing.md),
      TextFormWidget(
        title: languageProvider.tr('transactions.secondName'),
        controller: secondNameCtrl,
        prefixIcon: HugeIcons.strokeRoundedId,
        required: false,
        enableMic: true,
        textCapitalization: TextCapitalization.characters,
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormWidget(
              title: languageProvider.tr('transactions.mobile'),
              controller: mobileCtrl,
              prefixIcon: HugeIcons.strokeRoundedCall,
              required: false,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormWidget(
              title: languageProvider.tr('transactions.occupation'),
              controller: businessCtrl,
              prefixIcon: HugeIcons.strokeRoundedBriefcase01,
              required: false,
              enableMic: true,
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildFunctionDropdown(LanguageProvider languageProvider) {
    return CustomDropdown(
      key: const ValueKey('function_dropdown'),
      initialSelection: selectedFunction.isNotEmpty ? selectedFunction : null,
      title: languageProvider.tr('transactions.functionName'),
      required: true,
      search: false,
      controller: functionDropdownCtrl,
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
        FocusScope.of(context).unfocus();
        final selectedValue = (value?.toString().trim().isNotEmpty ?? false)
            ? value.toString().trim()
            : functionDropdownCtrl.text.trim();
        final select = functionsMaster.where((element) {
          if (element is! Map) return false;
          final name = element['name']?.toString().trim() ?? '';
          return name.toLowerCase() == selectedValue.toLowerCase();
        }).toList();
        setState(() {
          selectedFunction = selectedValue;
          selectedFunctionId = select.isNotEmpty
              ? select[0]['id']?.toString()
              : null;
          isCustomFunction = _isCustomOption(selectedFunction);
          if (!isCustomFunction) {
            customFunctionCtrl.clear();
          }

          if (select.isNotEmpty && select[0]['date'] != null) {
            try {
              final dateString = select[0]['date'].toString();
              final parsedDate = DateTime.parse(dateString).toLocal();
              dateCtrl.text = AppDatePicker.formatForDisplay(parsedDate);
            } catch (_) {}
          } else {
            dateCtrl.text = DateFormat(
              'dd-MMM-yyyy',
              'en',
            ).format(DateTime.now());
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

  @override
  void dispose() {
    customFunctionCtrl.dispose();
    functionDropdownCtrl.dispose();
    firstNameCtrl.dispose();
    secondNameCtrl.dispose();
    businessCtrl.dispose();
    cityCtrl.dispose();
    mobileCtrl.dispose();
    dateCtrl.dispose();
    amountCtrl.dispose();
    thingsCtrl.dispose();
    remarksCtrl.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color accent;

  const _SectionHeader({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.35,
            ),
          ),
        ),
      ],
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle.withValues(alpha: 0.9)),
        ),
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
