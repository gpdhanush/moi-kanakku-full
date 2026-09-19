import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
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
  final SecureStorageService _storage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final FunctionRequest _requestModel = FunctionRequest();
  final FunctionServices _functionServices = FunctionServices();

  final TextEditingController _functionNameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  File? _functionImage;
  String? _existingImageUrl;
  String? _uploadedImageUrl;
  String? _initialImagePath;

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
    final imageUrl = i['imageUrl']?.toString().trim() ?? '';
    if (imageUrl.isNotEmpty) {
      _initialImagePath = imageUrl;
      _existingImageUrl = imageUrl.startsWith('http')
          ? imageUrl
          : "$appImageUrl/$imageUrl";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final headerTitle = languageProvider.tr(
          isEditing ? 'functions.editFunction' : 'functions.addFunction',
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _FormAppHeader(
            title: headerTitle.toUpperCase(),
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
                        _FormSectionCard(
                          children: [
                            _buildTextFormWidget(
                              title: languageProvider.tr(
                                'functions.functionName',
                              ),
                              controller: _functionNameController,
                              required: true,
                              enableMic: true,
                              maxLength: 100,
                              inputFormatters: _nameInputFormatters(),
                              validator: _mandatoryValidator(
                                languageProvider.tr('functions.functionName'),
                                languageProvider,
                              ),
                              onSaved: (value) =>
                                  _requestModel.functionName = value,
                            ),
                            const SizedBox(height: AppSpacing.md),
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
                            const SizedBox(height: AppSpacing.md),
                            _buildTextFormWidget(
                              title: languageProvider.tr('functions.location'),
                              enableMic: true,
                              controller: _placeController,
                              inputFormatters: _nameInputFormatters(),
                              onSaved: (value) =>
                                  _requestModel.nativePlace = value,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildTextFormWidget(
                              title: languageProvider.tr('functions.notes'),
                              enableMic: true,
                              controller: _notesController,
                              inputFormatters: _nameInputFormatters(),
                              onSaved: (value) =>
                                  _requestModel.nativePlace = value,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildImageUploadWidget(primary),
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
                    title: isEditing
                        ? languageProvider.tr('home.updateFunction')
                        : languageProvider.tr('common.save'),
                    onPressed: _onSubmit,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

  List<TextInputFormatter> _nameInputFormatters() {
    return [
      FilteringTextInputFormatter.deny(RegExp(r'[0-9!@#\\$%^&*(),.?":{}|<>]')),
    ];
  }

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await AppDatePicker.pick(
      context,
      initialDate: _selectedDate,
      allowFutureDates: false,
      firstDate: DateTime(DateTime.now().year - 50),
      barrierColor: Colors.black54,
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = AppDatePicker.formatForDisplay(picked);
      });
    }
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      FocusScope.of(context).unfocus();
      _saveUpdateFunctions();
    }
  }

  void _saveUpdateFunctions() async {
    final user = await _storage.get(AppVariables.userInformation);

    await _alertServices.showLoading();

    String id = '';
    if (isEditing) {
      id = widget.data[0]['id'].toString();
    }
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
      // Always send imageUrl when editing so a deleted image is cleared on the server.
      if (isEditing || imagePathToSend.isNotEmpty) "imageUrl": imagePathToSend,
    };

    try {
      Map<String, dynamic>? response;
      if (!isEditing) {
        response = await _functionServices.saveFunctions(
          params,
          showLoading: false,
        );
      } else {
        response = await _functionServices.updateFunctions(
          params,
          showLoading: false,
        );
      }
      if (response != null && response['responseType'] == "S") {
        _alertServices.successToast(response['responseValue']['message']);
        if (!mounted) return;
        Navigator.pushNamed(context, "functions-list");
      }
    } catch (error) {
      // Loader cleared in finally.
    } finally {
      await _alertServices.hideLoading();
    }
  }

  String _convertDate(String inputDate) {
    try {
      final parsedDate = AppDatePicker.parseDisplay(inputDate);
      return DateFormat("yyyy-MM-dd").format(parsedDate);
    } catch (e) {
      return inputDate;
    }
  }

  Widget _buildImageUploadWidget(Color primary) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final bool hasImage =
        _functionImage != null ||
        _existingImageUrl != null ||
        _uploadedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('functions.image'),
          style: AppTypography.label.copyWith(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: hasImage ? _showImageOptions : _showImagePickerOptions,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.soft,
              ),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _functionImage != null
                              ? Image.file(
                                  _functionImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : (_existingImageUrl != null &&
                                    _existingImageUrl!.isNotEmpty)
                              ? MoiNetworkImage(
                      url: _existingImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildPlaceholder(primary),
                                )
                              : _buildPlaceholder(primary),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedPencilEdit02,
                              color: Colors.white,
                              size: 16,
                              strokeWidth: 1.8,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildPlaceholder(primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedCamera01,
              color: primary.withValues(alpha: 0.85),
              size: 24,
              strokeWidth: 1.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.read<LanguageProvider>().tr('functions.selectImage'),
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        _initialImagePath = null;
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
      final compressed = await _compressImage(croppedFile.path);
      if (compressed != null) {
        return compressed;
      }
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
    var loaderShown = false;
    try {
      final user = await _storage.get(AppVariables.userInformation);
      if (user == null || user['id'] == null) {
        _alertServices.errorToast(
          languageProvider.tr('functions.userInfoMissing'),
        );
        return;
      }

      await _alertServices.showLoading();
      loaderShown = true;
      final response = await _functionServices.uploadFile(
        user['id'].toString(),
        imageFile.path,
        "function-image",
        showLoading: false,
      );

      if (response != null &&
          response is Map &&
          response['responseType'] == "S") {
        final imagePath = response['responseValue']?.toString();
        if (imagePath != null && imagePath.isNotEmpty) {
          if (mounted) {
            setState(() {
              _uploadedImageUrl = imagePath;
              _functionImage = null;
              _existingImageUrl =
                  imagePath.startsWith('http://') ||
                      imagePath.startsWith('https://')
                  ? imagePath
                  : "$appImageUrl/$imagePath";
            });
          }
          _alertServices.successToast(
            languageProvider.tr('functions.imageUploadSuccess') ??
                "Image uploaded successfully",
          );
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
      _alertServices.errorToast(
        languageProvider.tr('functions.uploadFailed') ??
            "Failed to upload image",
      );
      printContent("Error uploading image: $e");
    } finally {
      if (loaderShown) {
        await _alertServices.hideLoading();
      }
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
                AppColors.deepenAccent(primary, amount: 0.28),
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
