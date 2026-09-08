import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
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
  // Person fields
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController secondNameCtrl = TextEditingController();
  final TextEditingController businessCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();

  // Moi fields
  final TextEditingController customFunctionCtrl = TextEditingController();
  final TextEditingController functionDropdownCtrl = TextEditingController();
  final TextEditingController dateCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController thingsCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();

  List functionsMaster = [];
  String selectedFunction = "";
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
              "${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}";
        }
      }
    } catch (e) {
      // leave as-is on parse failure
    }
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
    String notes = remarksCtrl.text.trim();
    final isCustom = isCustomFunction;

    final Map<String, dynamic> params = {
      "userId": userId,
      "firstName": firstName.isNotEmpty ? firstName : null,
      "secondName": secondName.isNotEmpty ? secondName : null,
      "business": business.isNotEmpty ? business : null,
      "city": city.isNotEmpty ? city : null,
      "mobile": mobile.isNotEmpty ? mobile : null,
      "transactionDate": _displayDateToApi(dateCtrl.text),
      "type": _getTransactionType(),
      "itemName": itemName,
      "amount": amountCtrl.text.trim().isNotEmpty ? amount : 0,
      "notes": notes.isNotEmpty ? notes : null,
      "is_custom": isCustom,
      "customFunction": isCustom ? customFunctionCtrl.text.trim() : null,
      "transactionFunctionId": selectedFunctionId,
      "transactionFunctionName": selectedFunction,
    };

    if (transactionId != null && transactionId!.isNotEmpty) {
      params["id"] = transactionId;
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

      if (response != null && response['responseType'] == "S") {
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
    } catch (e) {
      if (mounted) Navigator.pop(context);
      alertServices.errorToast(
        context.read<LanguageProvider>().tr('common.tryAgain'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final String title = _getTransactionType() != "RETURN"
        ? languageProvider.tr('transactions.addReceived')
        : languageProvider.tr('transactions.addGiven');
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBarWidget(title: title, action: []),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildPersonFields(),
                const SizedBox(height: 16),
                _buildFunctionDropdown(),
                if (isCustomFunction) ...[
                  const SizedBox(height: 12),
                  _buildCustomFunctionField(),
                ],
                const SizedBox(height: 16),
                _buildDateField(),
                const SizedBox(height: 16),
                TextFormWidget(
                  title: languageProvider.tr('transactions.amount'),
                  prefixIcon: Icons.currency_rupee_outlined,
                  controller: amountCtrl,
                  required: false,
                  maxLength: 7,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),

                TextFormWidget(
                  title: languageProvider.tr('transactions.thing'),
                  prefixIcon: Icons.category,
                  controller: thingsCtrl,
                  required: false,
                  enableMic: true,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                ),

                // _buildTypeRadioButtons(),
                const SizedBox(height: 16),
                TextFormWidget(
                  title: languageProvider.tr('transactions.notes'),
                  prefixIcon: Icons.note_add_outlined,
                  controller: remarksCtrl,
                  required: false,
                  enableMic: true,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getAllFunctions() async {
    try {
      if (userId == null) return;

      final response = await moiServices.getMoiDefaultFunctionsDropdown({
        "userId": userId,
      }, showLoading: false);

      if (response != null && response['responseType'] == "S" && mounted) {
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
    } catch (e) {
      // silent fail
    }
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
    return "RETURN";
  }

  Future<void> _selectDate() async {
    // determine initial value from text field using shared parser
    DateTime initial = AppDatePicker.parseDisplay(dateCtrl.text.trim());
    final DateTime? picked = await AppDatePicker.pick(
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
    // simply forward to the generic submit method
    await _submitTransaction();
  }

  Widget _buildPersonFields() {
    return Column(
      children: [
        TextFormWidget(
          title: context.read<LanguageProvider>().tr('transactions.city'),
          prefixIcon: Icons.location_city_outlined,
          enableMic: true,
          controller: cityCtrl,
          required: true,
          textCapitalization: TextCapitalization.characters,
          validator: (value) => value.toString().isEmpty
              ? context.read<LanguageProvider>().tr('transactions.cityRequired')
              : null,
        ),
        const SizedBox(height: 12),
        TextFormWidget(
          title: context.read<LanguageProvider>().tr('transactions.firstName'),
          prefixIcon: Icons.person_outlined,
          controller: firstNameCtrl,
          enableMic: true,
          required: true,
          textCapitalization: TextCapitalization.characters,
          validator: (value) => value.toString().isEmpty
              ? context.read<LanguageProvider>().tr('transactions.nameRequired')
              : null,
        ),
        const SizedBox(height: 12),
        TextFormWidget(
          title: context.read<LanguageProvider>().tr('transactions.secondName'),
          prefixIcon: Icons.person_2_outlined,
          controller: secondNameCtrl,
          required: false,
          enableMic: true,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormWidget(
                title: context.read<LanguageProvider>().tr(
                  'transactions.mobile',
                ),
                prefixIcon: Icons.phone_iphone_outlined,
                controller: mobileCtrl,
                required: false,
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormWidget(
                title: context.read<LanguageProvider>().tr(
                  'transactions.occupation',
                ),
                prefixIcon: Icons.business_outlined,
                controller: businessCtrl,
                required: false,
                enableMic: true,
                textCapitalization: TextCapitalization.characters,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunctionDropdown() {
    // Force rebuild when selectedFunction or functionsMaster changes
    // The key ensures the widget is completely recreated when these values change
    return CustomDropdown(
      key: const ValueKey('function_dropdown'),
      initialSelection: selectedFunction.isNotEmpty ? selectedFunction : null,
      title: context.read<LanguageProvider>().tr('transactions.functionName'),
      required: true,
      search: false,
      controller: functionDropdownCtrl,
      enableMic: false,
      showArrow: false,
      notFoundText: context.read<LanguageProvider>().tr(
        'transactions.functionNotFound',
      ),
      prefixIcon: Icons.celebration_outlined,
      dropdownMenuEntries: functionsMaster
          .map((e) => e is Map ? e['name']?.toString() ?? '' : '')
          .where((name) => name.isNotEmpty)
          .toList()
          .map<DropdownMenuEntry<String>>((value) {
            return DropdownMenuEntry<String>(value: value, label: value);
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

          // Bind date if available
          if (select.isNotEmpty && select[0]['date'] != null) {
            try {
              final dateString = select[0]['date'].toString();
              final parsedDate = DateTime.parse(dateString).toLocal();
              dateCtrl.text = AppDatePicker.formatForDisplay(parsedDate);
            } catch (e) {
              // Keep current date on parse error
            }
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

  Widget _buildCustomFunctionField() {
    return TextFormWidget(
      title: context.read<LanguageProvider>().tr('transactions.customFunction'),
      prefixIcon: Icons.edit_note_outlined,
      controller: customFunctionCtrl,
      required: true,
      enableMic: true,
      validator: (value) => value.toString().trim().isEmpty
          ? context.read<LanguageProvider>().tr(
              'transactions.customFunctionRequired',
            )
          : null,
    );
  }

  Widget _buildDateField() {
    return TextFormWidget(
      title: context.read<LanguageProvider>().tr('transactions.date'),
      prefixIcon: Icons.calendar_month_outlined,
      controller: dateCtrl,
      required: true,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) => value.toString().isEmpty
          ? context.read<LanguageProvider>().tr('transactions.dateRequired')
          : null,
    );
  }

  Widget _buildSaveButton() {
    final buttonText = transactionId != null && transactionId!.isNotEmpty
        ? context.read<LanguageProvider>().tr('common.update')
        : context.read<LanguageProvider>().tr('common.save');
    return AppButton(title: buttonText, onPressed: _saveMoiReturnInvest);
    // return Container(
    //   decoration: BoxDecoration(
    //     borderRadius: BorderRadius.circular(12),
    //     boxShadow: [
    //       BoxShadow(
    //         color: colorScheme.primary.withValues(alpha: 0.3),
    //         blurRadius: 12,
    //         offset: const Offset(0, 4),
    //         spreadRadius: 0,
    //       ),
    //     ],
    //   ),
    //   child: SizedBox(
    //     width: double.infinity,
    //     height: 52,
    //     child: ElevatedButton(
    //       onPressed: _saveMoiReturnInvest,
    //       style: ElevatedButton.styleFrom(
    //         backgroundColor: colorScheme.primary,
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(12),
    //         ),
    //         elevation: 0,
    //       ),
    //       child: Text(
    //         buttonText,
    //         style: const TextStyle(
    //           fontSize: 17,
    //           fontWeight: FontWeight.bold,
    //           color: Colors.white,
    //
    //         ),
    //       ),
    //     ),
    //   ),
    // );
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
