import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/image_picker_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'models/functions_model.dart';

class AddEditFunctions extends StatefulWidget {
  final List data;

  const AddEditFunctions({super.key, required this.data});

  @override
  State<AddEditFunctions> createState() => _AddEditFunctionsState();
}

class _AddEditFunctionsState extends State<AddEditFunctions> {
  // Initialize services and controllers
  final SecureStorageService _storage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final FunctionRequest _requestModel = FunctionRequest();
  final FunctionServices _functionServices = FunctionServices();

  final TextEditingController _functionNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Image upload state
  final ImagePicker _imagePicker = ImagePicker();
  File? _functionImage;
  String? _existingImageUrl; // full URL for display
  String? _uploadedImageUrl; // raw path returned by server
  String? _initialImagePath; // raw path from server when editing

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  bool get isEditing => widget.data.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.data.isNotEmpty) {
      setFieldValue();
    }
  }

  // Set initial field values if data is provided
  void setFieldValue() {
    var i = widget.data[0];
    final rawDate = i['functionDate'].toString();
    _dateController.text = formatFunctionDate(rawDate);
    try {
      _selectedDate = AppDatePicker.parseDisplay(
        _dateController.text,
      ).toLocal();
    } catch (_) {
      _selectedDate = DateTime.now();
    }
    _functionNameController.text = i['functionName'].toString().trim();
    _placeController.text = (i['location'] ?? i['place'] ?? '')
        .toString()
        .trim();
    _notesController.text = (i['notes'] ?? i['nativePlace'] ?? '')
        .toString()
        .trim();
    if (_placeController.text.toLowerCase() == 'null') {
      _placeController.text = '';
    }
    if (_notesController.text.toLowerCase() == 'null') {
      _notesController.text = '';
    }
    // existing image (if backend sends it)
    final imageUrl = i['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      _initialImagePath = imageUrl; // raw response value for saving
      _existingImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : "$appImageUrl/$imageUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBarWidget(
            title: languageProvider.tr('functions.title'),
            action: [],
          ),
          body: Material(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildTextFormWidget(
                        title: languageProvider.tr('functions.functionName'),
                        controller: _functionNameController,
                        required: true,
                        enableMic: true,
                        maxLength: 100,
                        inputFormatters: _nameInputFormatters(),
                        validator: _mandatoryValidator(
                          languageProvider.tr('functions.functionName'),
                          languageProvider,
                        ),
                        onSaved: (value) => _requestModel.functionName = value,
                      ),
                      const SizedBox(height: 16),
                      _buildTextFormWidget(
                        title: languageProvider.tr('functions.date'),
                        controller: _dateController,
                        required: true,
                        focusNode: AlwaysDisabledFocusNode(),
                        onTap: () => _selectDate(context),
                        validator: _mandatoryValidator(
                          languageProvider.tr('functions.date'),
                          languageProvider,
                        ),
                        onSaved: (value) => _requestModel.date = value,
                      ),
                      const SizedBox(height: 16),

                      _buildTextFormWidget(
                        title: languageProvider.tr('functions.location'),
                        enableMic: true,
                        controller: _placeController,
                        inputFormatters: _nameInputFormatters(),
                        onSaved: (value) => _requestModel.nativePlace = value,
                      ),
                      const SizedBox(height: 16),

                      _buildTextFormWidget(
                        title: languageProvider.tr('functions.notes'),
                        enableMic: true,
                        controller: _notesController,
                        inputFormatters: _nameInputFormatters(),
                        onSaved: (value) => _requestModel.nativePlace = value,
                      ),
                      const SizedBox(height: 16),
                      _buildImageUploadWidget(),
                      const SizedBox(height: 32),
                      AppButton(
                        title: isEditing
                            ? languageProvider.tr('functions.updateFunction')
                            : languageProvider.tr('common.save'),
                        onPressed: _onSubmit,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper method to build text form widgets
  Widget _buildTextFormWidget({
    required String title,
    required TextEditingController controller,
    bool required = false,
    bool enableMic = false,
    FocusNode? focusNode,
    VoidCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
    String? Function(dynamic)? validator,
    void Function(dynamic)? onSaved,
    int? maxLength,
  }) {
    return TextFormWidget(
      title: title,
      required: required,
      controller: controller,
      focusNode: focusNode,
      enableMic: enableMic,
      onTap: onTap,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.characters,
    );
  }

  // Input formatters to restrict unwanted characters
  List<TextInputFormatter> _nameInputFormatters() {
    return [
      FilteringTextInputFormatter.deny(RegExp(r'[0-9!@#\\$%^&*(),.?":{}|<>]')),
    ];
  }

  // Validator to ensure fields are not empty
  String? Function(dynamic) _mandatoryValidator(
    String fieldName,
    LanguageProvider languageProvider,
  ) {
    return (value) {
      if (value?.trim().isEmpty == true) {
        return '${languageProvider.tr('validation.required')}: $fieldName';
      }
      return null;
    };
  }

  // Date picker for selecting function date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await AppDatePicker.pick(
      context,
      initialDate: _selectedDate,
      allowFutureDates: false,
      firstDate: DateTime(DateTime.now().year - 50),
      // lastDate: DateTime(DateTime.now().year + 50),
      barrierColor: Colors.black54,
      lastDate: DateTime.now(),
      // locale: Provider.of<LanguageProvider>(context, listen: false).isTamil
      // ? const Locale("ta", "IN")
      // : const Locale("en", "US"),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = AppDatePicker.formatForDisplay(picked);
      });
    }
  }

  // Handle form submission
  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      FocusScope.of(context).unfocus();
      _saveUpdateFunctions();
    }
  }

  // Save or update function details
  void _saveUpdateFunctions() async {
    final user = await _storage.get(AppVariables.userInformation);

    _alertServices.showLoading();

    String id = '';
    if (isEditing) {
      id = widget.data[0]['id'].toString();
    }
    // determine which image path should be sent (only relative/raw path)
    String imagePathToSend = '';
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      imagePathToSend = _uploadedImageUrl!;
    } else if (_initialImagePath != null && _initialImagePath!.isNotEmpty) {
      imagePathToSend = _initialImagePath!;
    }

    var params = {
      "functionId": id,
      "userId": user['id'].toString(),
      "functionName": _functionNameController.text
          .toString()
          .trim()
          .toCapitalized(),
      "functionDate": _convertDate(_dateController.text.toString()),
      "location": _placeController.text.toString().trim().toCapitalized(),
      "notes": _notesController.text.toString().trim().toCapitalized(),
      if (imagePathToSend.isNotEmpty) "imageUrl": imagePathToSend,
    };

    try {
      Map<String, dynamic>? response;
      if (!isEditing) {
        response = await _functionServices.saveFunctions(params);
      } else {
        response = await _functionServices.updateFunctions(params);
      }
      _alertServices.hideLoading();
      if (response != null && response['responseType'] == "S") {
        _alertServices.successToast(response['responseValue']['message']);
        if (!mounted) return;
        Navigator.pushNamed(context, "functions-list");
      }
    } catch (error) {
      _alertServices.hideLoading();
    }
  }

  // Convert date format for API
  String _convertDate(String inputDate) {
    try {
      final parsedDate = AppDatePicker.parseDisplay(inputDate);
      return DateFormat("yyyy-MM-dd").format(parsedDate);
    } catch (e) {
      return inputDate;
    }
  }

  // -------------------- image upload helpers --------------------

  Widget _buildImageUploadWidget() {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasImage =
        _functionImage != null ||
        _existingImageUrl != null ||
        _uploadedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('functions.image'),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal),
          // style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: hasImage ? _showImageOptions : _showImagePickerOptions,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _functionImage != null
                            ? Image.file(
                                _functionImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : (_existingImageUrl != null &&
                                  _existingImageUrl!.isNotEmpty)
                            ? Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(colorScheme),
                              )
                            : _buildPlaceholder(colorScheme),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildPlaceholder(colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(
        Icons.camera_alt_outlined,
        size: 48,
        color: colorScheme.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Future<void> _showImageOptions() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    if (!mounted) return;
    final action = await ImagePickerBottomSheet.show(
      context: context,
      title: languageProvider.tr('functions.selectImage'),
      galleryLabel: languageProvider.tr('functions.chooseFromGallery'),
      cameraLabel: languageProvider.tr('functions.takePhoto'),
      deleteLabel: languageProvider.tr('functions.delete'),
      permissionsMessage: languageProvider.tr('functions.permissionsNeeded'),
      canUseGallery: true,
      canUseCamera: true,
      showDelete: true,
    );
    if (!mounted || action == null) return;
    if (action == ImagePickerAction.delete) {
      setState(() {
        _functionImage = null;
        _uploadedImageUrl = null;
        _existingImageUrl = null;
      });
    } else if (action == ImagePickerAction.gallery) {
      await _pickImage(ImageSource.gallery);
    } else {
      await _pickImage(ImageSource.camera);
    }
  }

  Future<void> _showImagePickerOptions() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final permissions = await _checkPermissions();
    if (!mounted) return;

    final action = await ImagePickerBottomSheet.show(
      context: context,
      title: languageProvider.tr('functions.selectImage'),
      galleryLabel: languageProvider.tr('functions.chooseFromGallery'),
      cameraLabel: languageProvider.tr('functions.takePhoto'),
      deleteLabel: languageProvider.tr('functions.delete'),
      permissionsMessage: languageProvider.tr('functions.permissionsNeeded'),
      canUseGallery: permissions['photos'] ?? false,
      canUseCamera: permissions['camera'] ?? false,
    );
    if (!mounted || action == null) return;
    await _pickImage(
      action == ImagePickerAction.gallery
          ? ImageSource.gallery
          : ImageSource.camera,
    );
  }

  Future<Map<String, bool>> _checkPermissions() async {
    return ImagePickerPermissions.checkImagePickerPermissions();
  }

  Future<void> _pickImage(ImageSource source) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      final permissions = await _checkPermissions();
      if ((source == ImageSource.camera && !permissions['camera']!) ||
          (source == ImageSource.gallery && !permissions['photos']!)) {
        _alertServices.errorToast(
          source == ImageSource.camera
              ? languageProvider.tr('functions.cameraPermissionNeeded') ??
                    "Camera permission required"
              : languageProvider.tr('functions.storagePermissionNeeded') ??
                    "Storage permission required",
        );
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (pickedFile == null) return;

      final croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile == null) return;

      final compressedFile = await _compressImage(croppedFile.path);
      if (compressedFile == null) {
        _alertServices.errorToast(
          languageProvider.tr('functions.compressFailed') ??
              "Unable to compress image",
        );
        return;
      }

      setState(() {
        _functionImage = compressedFile;
        _existingImageUrl = null;
        _uploadedImageUrl = null;
      });

      await _uploadImage(compressedFile);
    } catch (e) {
      _alertServices.errorToast(
        languageProvider.tr('functions.imagePickFailed') ??
            "Failed to pick image",
      );
      printContent("Error picking image: $e");
    }
  }

  Future<File?> _cropImage(String imagePath) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: Provider.of<LanguageProvider>(
              context,
              listen: false,
            ).tr('functions.cropImage'),
            statusBarLight: true,
            activeControlsWidgetColor: Theme.of(context).colorScheme.primary,
            toolbarColor: Theme.of(context).colorScheme.primary,
            navBarLight: false,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: false,
          ),
        ],
      );
      if (croppedFile == null) return null;
      // compress the cropped image before returning
      final compressed = await _compressImage(croppedFile.path);
      if (compressed != null) {
        return compressed;
      }
      // fallback to original cropped file if compression failed
      return File(croppedFile.path);
    } catch (e) {
      printContent("Error cropping image: $e");
      return File(imagePath);
    }
  }

  Future<File?> _compressImage(String imagePath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 85,
        minWidth: 1024,
        minHeight: 576,
        format: CompressFormat.jpeg,
      );
      return compressedFile != null ? File(compressedFile.path) : null;
    } catch (e) {
      printContent("Error compressing image: $e");
      return File(imagePath);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      final user = await _storage.get(AppVariables.userInformation);
      if (user == null || user['id'] == null) {
        _alertServices.errorToast(
          languageProvider.tr('functions.userInfoMissing'),
        );
        return;
      }

      _alertServices.showLoading();
      final response = await _functionServices.uploadFile(
        user['id'].toString(),
        imageFile.path,
        "function-image",
      );
      _alertServices.hideLoading();

      if (response != null &&
          response is Map &&
          response['responseType'] == "S") {
        final imagePath = response['responseValue']?.toString();
        if (imagePath != null && imagePath.isNotEmpty) {
          setState(() {
            _uploadedImageUrl = imagePath;
            _functionImage = null;
            _existingImageUrl =
                imagePath.startsWith('http://') ||
                    imagePath.startsWith('https://')
                ? imagePath
                : "$appImageUrl/$imagePath";
          });
          _alertServices.successToast(
            languageProvider.tr('functions.imageUploadSuccess') ??
                "Image uploaded successfully",
          );
          // delete local cache
          if (await imageFile.exists()) {
            // ignore: body_might_complete_normally_catch_error
            await imageFile.delete().catchError((_) {});
          }
        } else {
          _alertServices.errorToast(
            languageProvider.tr('functions.imageUrlMissing') ??
                "Unable to get image URL",
          );
        }
      } else {
        final errorMessage = response is Map
            ? (response['responseValue'] is Map
                  ? response['responseValue']['message']
                  : response['message'] ??
                        response['responseValue']?.toString())
            : languageProvider.tr('functions.uploadFailed');
        _alertServices.errorToast(
          errorMessage?.toString() ??
              (languageProvider.tr('functions.uploadFailed') ??
                  'Failed to upload image'),
        );
      }
    } catch (e) {
      _alertServices.hideLoading();
      _alertServices.errorToast(
        languageProvider.tr('functions.uploadFailed') ??
            "Failed to upload image",
      );
      printContent("Error uploading image: $e");
    }
  }

  @override
  void dispose() {
    _functionNameController.dispose();
    _dateController.dispose();
    _placeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
