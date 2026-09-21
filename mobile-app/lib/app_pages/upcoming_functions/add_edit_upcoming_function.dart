import 'dart:io';

import 'package:flutter/material.dart';
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
          _selectedDate = DateFormat(
            'dd-MMM-yyyy',
          ).parse(function.functionDate);
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
          appBar: MoiFlowAppHeader(
            title: headerTitle.toUpperCase(),
            onBack: () => Navigator.pop(context),
            accent: primary,
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
                            languageProvider.tr('upcomingFunctions.location'),
                            languageProvider,
                          ),
                          onSaved: (value) => _requestModel.location = value,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextFormWidget(
                          title: languageProvider.tr(
                            'upcomingFunctions.description',
                          ),
                          controller: _descriptionController,
                          enableMic: true,
                          maxLines: 4,
                          onSaved: (value) => _requestModel.description = value,
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
                  child: AppButton(
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('upcomingFunctions.invitation'),
          style: AppTypography.label.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Material(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: hasImage ? _showImageOptions : _showImagePickerOptions,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : AppShadows.soft,
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
            aspectRatioPresets: const [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: context.read<LanguageProvider>().tr(
              'upcomingFunctions.cropImage',
            ),
            aspectRatioLockEnabled: false,
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
    await _alertServices.showLoading();

    try {
      String imageUrl = _uploadedImageUrl ?? _existingImageUrl ?? '';
      if (_invitationImage != null) {
        final uploadedUrl = await _uploadInvitationImage(_invitationImage!);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          imageUrl = uploadedUrl;
          _uploadedImageUrl = uploadedUrl;
        } else {
          _alertServices.errorToast(
            context.read<LanguageProvider>().tr(
              'upcomingFunctions.uploadFailed',
            ),
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

      final response = !isEditing
          ? await _upcomingFunctionServices.createUpcomingFunction(
              params,
              showLoading: false,
            )
          : await _upcomingFunctionServices.updateUpcomingFunction(
              params,
              showLoading: false,
            );

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
      _alertServices.errorToast(
        context.read<LanguageProvider>().tr('upcomingFunctions.saveFailed'),
      );
      printContent('Error saving upcoming function: $error');
    } finally {
      await _alertServices.hideLoading();
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
          .uploadUpcomingFunctionImage(
            params,
            imageFile.path,
            showLoading: false,
          );

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
