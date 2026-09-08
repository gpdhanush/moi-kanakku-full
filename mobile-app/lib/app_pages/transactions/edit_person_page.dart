import 'package:flutter/material.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class EditPersonPage extends StatefulWidget {
  final PersonResponseModel person;

  const EditPersonPage({super.key, required this.person});

  @override
  State<EditPersonPage> createState() => _EditPersonPageState();
}

class _EditPersonPageState extends State<EditPersonPage> {
  final AlertServices _alertServices = AlertServices();
  final TransactionServices _txServices = TransactionServices();

  late TextEditingController _firstNameCtrl;
  late TextEditingController _secondNameCtrl;
  late TextEditingController _businessCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _mobileCtrl;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.person.firstName ?? '');
    _secondNameCtrl = TextEditingController(
      text: widget.person.secondName ?? '',
    );
    _businessCtrl = TextEditingController(text: widget.person.business ?? '');
    _cityCtrl = TextEditingController(text: widget.person.city ?? '');
    _mobileCtrl = TextEditingController(text: widget.person.mobile ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _businessCtrl.dispose();
    _cityCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePersonDetails() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    try {
      SecureStorageService storage = SecureStorageService();
      _alertServices.showLoading();
      final userData = await storage.get(AppVariables.userInformation);
      final userId = userData['id']?.toString();

      final params = {
        "id": widget.person.id.toString(),
        "userId": userId,
        "firstName": _firstNameCtrl.text.trim(),
        "secondName": _secondNameCtrl.text.trim(),
        "mobile": _mobileCtrl.text.trim(),
        "city": _cityCtrl.text.trim(),
        "business": _businessCtrl.text.trim(),
      };

      final response = await _txServices.updatePerson(params);

      _alertServices.hideLoading();

      if (response != null && response['responseType'] == "S") {
        if (!mounted) return;
        _alertServices.successToast(
          response['responseValue']?['message']?.toString() ??
              context.read<LanguageProvider>().tr('transactions.personUpdated'),
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (!mounted) return;
        _alertServices.errorToast(
          response?['responseValue']?['message']?.toString() ??
              context.read<LanguageProvider>().tr('transactions.updateFailed'),
        );
      }
    } catch (e) {
      _alertServices.hideLoading();
      if (!mounted) return;
      _alertServices.errorToast(
        context.read<LanguageProvider>().tr('common.tryAgain'),
      );
      debugPrint('Error updating person: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Scaffold(
      appBar: AppBarWidget(
        title: languageProvider.tr('transactions.editPerson'),
        action: const [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormWidget(
                title: languageProvider.tr('transactions.firstName'),
                controller: _firstNameCtrl,
                required: true,
                enableMic: true,
                validator: (value) => value?.isEmpty == true
                    ? languageProvider.tr('transactions.firstNameRequired')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                title: languageProvider.tr('transactions.secondName'),
                controller: _secondNameCtrl,
                required: false,
                enableMic: true,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                title: languageProvider.tr('transactions.mobile'),
                controller: _mobileCtrl,
                required: false,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                title: languageProvider.tr('transactions.city'),
                controller: _cityCtrl,
                enableMic: true,
                required: false,
              ),
              const SizedBox(height: 16),
              TextFormWidget(
                title: languageProvider.tr('transactions.occupation'),
                controller: _businessCtrl,
                required: false,
                enableMic: true,
              ),
              const SizedBox(height: 28),
              AppButton(
                title: languageProvider.tr('common.update'),
                onPressed: _updatePersonDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
