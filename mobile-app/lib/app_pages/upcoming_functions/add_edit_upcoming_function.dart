import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_services/upcoming_function_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/image_picker_bottom_sheet.dart';
import 'package:moi/app_utils/index.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class AddEditUpcomingFunction extends StatefulWidget {
  final dynamic data;

  const AddEditUpcomingFunction({super.key, required this.data});

  @override
  State<AddEditUpcomingFunction> createState() =>
      _AddEditUpcomingFunctionState();
}

class _AddEditUpcomingFunctionState extends State<AddEditUpcomingFunction> {
  final AlertServices _alertServices = AlertServices();
  final UpcomingFunctionRequest _requestModel = UpcomingFunctionRequest();
  final UpcomingFunctionServices _upcomingFunctionServices =
      UpcomingFunctionServices();
  final SecureStorageService _secureStorage = SecureStorageService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  bool isEditing = false;
  File? _invitationImage;
  String? _existingImageUrl;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.data is UpcomingFunction && widget.data.id.isNotEmpty) {
      setFieldValue(widget.data as UpcomingFunction);
    }
  }

  void setFieldValue(UpcomingFunction function) {
    isEditing = true;
    _titleController.text = function.title;
    _locationController.text = function.location;
    _descriptionController.text = function.description ?? '';
    _dateController.text = function.functionDate;
    _requestModel.id = function.id;

    if (function.functionDate.isNotEmpty) {
      try {
        _selectedDate = AppDatePicker.parseDisplay(function.functionDate);
      } catch (_) {
        try {
          _selectedDate =
              DateFormat('dd-MMM-yyyy').parse(function.functionDate);
        } catch (_) {
          _selectedDate = DateTime.now();
        }
      }
    }

    if (function.invitationUrl != null && function.invitationUrl!.isNotEmpty) {
      _uploadedImageUrl = function.invitationUrl;
      _existingImageUrl = function.invitationUrl!.startsWith('http')
          ? function.invitationUrl
          : '$appImageUrl/${function.invitationUrl}';
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final primary = Theme.of(context).colorScheme.primary;
        final headerTitle = languageProvider.tr(
          isEditing
              ? 'upcomingFunctions.editFunction'
              : 'upcomingFunctions.addFunction',
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
                                'upcomingFunctions.functionName',
                              ),
                              controller: _titleController,
                              required: true,
                              enableMic: true,
                              maxLength: 120,
                              validator: _mandatoryValidator(
                                languageProvider.tr(
                                  'upcomingFunctions.functionName',
                                ),
                                languageProvider,
                              ),
                              onSaved: (value) => _requestModel.title = value,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildTextFormWidget(
                              title: languageProvider.tr(
                                'upcomingFunctions.functionDate',
                              ),
                              controller: _dateController,
                              required: true,
                              focusNode: AlwaysDisabledFocusNode(),
                              onTap: () => _selectDate(context),
                              validator: _mandatoryValidator(
                                languageProvider.tr(
                                  'upcomingFunctions.functionDate',
                                ),
                                languageProvider,
                              ),
                              onSaved: (value) =>
                                  _requestModel.functionDate = value,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildTextFormWidget(
                              title: languageProvider.tr(
                                'upcomingFunctions.location',
                              ),
                              controller: _locationController,
                              required: true,
                              enableMic: true,
                              maxLength: 150,
                              validator: _mandatoryValidator(
                                languageProvider.tr(
                                  'upcomingFunctions.location',
                                ),
                                languageProvider,
                              ),
                              onSaved: (value) =>
                                  _requestModel.location = value,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildTextFormWidget(
                              title: languageProvider.tr(
                                'upcomingFunctions.description',
                              ),
                              controller: _descriptionController,
                              enableMic: true,
                              maxLines: 4,
                              onSaved: (value) =>
                                  _requestModel.description = value,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildImageUploadWidget(primary, languageProvider),
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
                        ? languageProvider.tr('common.update')
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
    String? Function(dynamic)? validator,
    void Function(dynamic)? onSaved,
    int? maxLength,
    int maxLines = 1,
  }) {
    return TextFormWidget(
      title: title,
      required: required,
      controller: controller,
      focusNode: focusNode,
      enableMic: enableMic,
      onTap: onTap,
      validator: validator,
      onSaved: onSaved,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  String? Function(dynamic) _mandatoryValidator(
    String fieldName,
    LanguageProvider languageProvider,
  ) {
    return (value) {
      if (value?.toString().trim().isEmpty == true) {
        return '$fieldName ${languageProvider.tr('common.required')}';
      }
      return null;
    };
  }

  Widget _buildImageUploadWidget(
    Color primary,
    LanguageProvider languageProvider,
  ) {
    final bool hasImage =
        _invitationImage != null ||
        _existingImageUrl != null ||
        _uploadedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('upcomingFunctions.invitation'),
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
                          child: _invitationImage != null
                              ? Image.file(
                                  _invitationImage!,
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
            context.read<LanguageProvider>().tr(
              'upcomingFunctions.selectImage',
            ),
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
      title: languageProvider.tr('upcomingFunctions.selectImage'),
      galleryLabel: languageProvider.tr('upcomingFunctions.chooseFromGallery'),
      cameraLabel: languageProvider.tr('upcomingFunctions.takePhoto'),
      deleteLabel: languageProvider.tr('common.delete'),
      permissionsMessage: languageProvider.tr(
        'upcomingFunctions.permissionsNeeded',
      ),
      canUseGallery: true,
      canUseCamera: true,
      showDelete: true,
    );

    if (!mounted || action == null) return;
    if (action == ImagePickerAction.delete) {
      setState(() {
        _invitationImage = null;
        _uploadedImageUrl = null;
        _existingImageUrl = null;
      });
    } else if (action == ImagePickerAction.gallery) {
      await _pickImage(ImageSource.gallery);
    } else if (action == ImagePickerAction.camera) {
      await _pickImage(ImageSource.camera);
    }
  }

  Future<void> _showImagePickerOptions() async {
    final permissions = await _checkPermissions();
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final action = await ImagePickerBottomSheet.show(
      context: context,
      title: languageProvider.tr('upcomingFunctions.selectImage'),
      galleryLabel: languageProvider.tr('upcomingFunctions.chooseFromGallery'),
      cameraLabel: languageProvider.tr('upcomingFunctions.takePhoto'),
      deleteLabel: languageProvider.tr('common.delete'),
      permissionsMessage: languageProvider.tr(
        'upcomingFunctions.permissionsNeeded',
      ),
      canUseGallery: permissions['photos'] ?? false,
      canUseCamera: permissions['camera'] ?? false,
    );

    if (!mounted || action == null) return;
    if (action == ImagePickerAction.gallery) {
      await _pickImage(ImageSource.gallery);
    } else if (action == ImagePickerAction.camera) {
      await _pickImage(ImageSource.camera);
    }
  }

  Future<Map<String, bool>> _checkPermissions() async {
    return ImagePickerPermissions.checkImagePickerPermissions();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final permissions = await _checkPermissions();
      if ((source == ImageSource.camera && !permissions['camera']!) ||
          (source == ImageSource.gallery && !permissions['photos']!)) {
        _alertServices.errorToast(
          source == ImageSource.camera
              ? context.read<LanguageProvider>().tr(
                  'upcomingFunctions.cameraPermissionNeeded',
                )
              : context.read<LanguageProvider>().tr(
                  'upcomingFunctions.storagePermissionNeeded',
                ),
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
          context.read<LanguageProvider>().tr(
            'upcomingFunctions.compressFailed',
          ),
        );
        return;
      }

      setState(() {
        _invitationImage = compressedFile;
        _existingImageUrl = null;
        _uploadedImageUrl = null;
      });
    } catch (e) {
      _alertServices.errorToast(
        context.read<LanguageProvider>().tr(
          'upcomingFunctions.imagePickFailed',
        ),
      );
      printContent('Error picking image: $e');
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
            toolbarTitle: context.read<LanguageProvider>().tr(
              'upcomingFunctions.cropImage',
            ),
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
      return croppedFile != null ? File(croppedFile.path) : null;
    } catch (e) {
      printContent('Error cropping image: $e');
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
      printContent('Error compressing image: $e');
      return File(imagePath);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await AppDatePicker.pick(
      context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate,
      allowFutureDates: true,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 50),
      barrierColor: Colors.black54,
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
      _saveUpdateUpcomingFunction();
    }
  }

  Future<void> _saveUpdateUpcomingFunction() async {
    _alertServices.showLoading();

    String imageUrl = _uploadedImageUrl ?? _existingImageUrl ?? '';
    if (_invitationImage != null) {
      final uploadedUrl = await _uploadInvitationImage(_invitationImage!);
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        imageUrl = uploadedUrl;
        _uploadedImageUrl = uploadedUrl;
      } else {
        _alertServices.hideLoading();
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('upcomingFunctions.uploadFailed'),
        );
        return;
      }
    }

    final params = {
      if (isEditing) 'id': _requestModel.id,
      'title': _titleController.text.trim(),
      'functionDate': _convertDate(_dateController.text),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'invitationUrl': imageUrl,
      if (!isEditing) 'status': 'ACTIVE',
    };

    try {
      final response = !isEditing
          ? await _upcomingFunctionServices.createUpcomingFunction(params)
          : await _upcomingFunctionServices.updateUpcomingFunction(params);

      _alertServices.hideLoading();

      if (response != null &&
          response is Map &&
          response['responseType'] == 'S') {
        final message =
            response['responseValue']?['message']?.toString() ??
            (isEditing
                ? context.read<LanguageProvider>().tr(
                    'upcomingFunctions.updated',
                  )
                : context.read<LanguageProvider>().tr(
                    'upcomingFunctions.saved',
                  ));
        _alertServices.successToast(message);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        final errorMessage = response is Map
            ? (response['responseValue'] is Map
                  ? response['responseValue']['message']
                  : response['message'] ??
                        response['responseValue']?.toString())
            : context.read<LanguageProvider>().tr(
                'upcomingFunctions.saveFailed',
              );
        _alertServices.errorToast(
          errorMessage?.toString() ??
              context.read<LanguageProvider>().tr(
                'upcomingFunctions.saveFailed',
              ),
        );
      }
    } catch (error) {
      _alertServices.hideLoading();
      _alertServices.errorToast(
        context.read<LanguageProvider>().tr('upcomingFunctions.saveFailed'),
      );
      printContent('Error saving upcoming function: $error');
    }
  }

  Future<String?> _uploadInvitationImage(File imageFile) async {
    try {
      final userData = await _secureStorage.get(AppVariables.userInformation);
      final userId = userData?['id'] ?? '';

      if (userId.isEmpty) {
        printContent('Error: User ID not found');
        return null;
      }

      final params = {'userId': userId, 'path': 'upcoming-function'};
      final response = await _upcomingFunctionServices
          .uploadUpcomingFunctionImage(params, imageFile.path);

      if (response != null && response['responseType'] == 'S') {
        String uploadedUrl = '';

        if (response['responseValue'] is String) {
          uploadedUrl = response['responseValue'].toString();
        } else if (response['responseValue'] is Map) {
          uploadedUrl =
              response['responseValue']?['imageUrl']?.toString() ??
              response['responseValue']?['url']?.toString() ??
              response['responseValue']?.toString() ??
              '';
        }

        if (uploadedUrl.isNotEmpty) {
          printContent('Image uploaded successfully: $uploadedUrl');
          return uploadedUrl;
        }
        printContent('Image upload failed: Invalid response format');
        return null;
      }

      printContent('Image upload failed: $response');
      return null;
    } catch (e) {
      printContent('Error uploading image: $e');
      return null;
    }
  }

  String _convertDate(String inputDate) {
    try {
      final parsed = AppDatePicker.parseDisplay(inputDate);
      return AppDatePicker.formatForDisplay(parsed);
    } catch (_) {
      try {
        final parsed = DateFormat('dd-MMM-yyyy').parse(inputDate);
        return DateFormat('dd-MMM-yyyy').format(parsed);
      } catch (_) {
        return inputDate;
      }
    }
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
