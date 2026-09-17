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
            })
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
            });

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
        final title = widget.isEdit
            ? languageProvider.tr('transactions.updateTitle')
            : _isReceived
            ? languageProvider.tr('transactions.receivedTitle')
            : languageProvider.tr('transactions.givenTitle');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _FormAppHeader(
            title: title.toUpperCase(),
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
                    child: _FormSectionCard(
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
                          required: false,
                          maxLines: 3,
                          enableMic: true,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormWidget(
                          title: languageProvider.tr('transactions.notes'),
                          controller: notesCtrl,
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
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    0,
                    AppSpacing.page,
                    AppSpacing.md,
                  ),
                  child: _PrimaryActionButton(
                    title: languageProvider.tr(
                      widget.isEdit ? 'common.update' : 'common.save',
                    ),
                    onPressed: _submit,
                  ),
                ),
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
      notFoundText: languageProvider.tr('transactions.functionNotFound'),
      dropdownMenuEntries: functionsMaster
          .map((e) => e is Map ? e['name']?.toString() ?? '' : '')
          .where((name) => name.isNotEmpty)
          .toList()
          .map<DropdownMenuEntry<String>>((value) {
            return DropdownMenuEntry<String>(value: value, label: value);
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
      required: true,
      readOnly: true,
      onTap: _selectDate,
      validator: (value) => value.toString().isEmpty
          ? languageProvider.tr('transactions.dateRequired')
          : null,
    );
  }
}

class _FormAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBack;

  const _FormAppHeader({required this.title, required this.onBack});

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
        ),
      ),
      actions: const [SizedBox(width: 54)],
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final List<Widget> children;

  const _FormSectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const _PrimaryActionButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                Color.lerp(primary, const Color(0xff0A3D8F), 0.28)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.label.copyWith(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
