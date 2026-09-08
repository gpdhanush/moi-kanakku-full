import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/upcoming_function_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_widgets/image_picker_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'models/upcoming_function_model.dart';

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
  String buttonName = '';
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
    buttonName = 'update';
    _titleController.text = function.title;
    _locationController.text = function.location;
    _descriptionController.text = function.description ?? '';
    _dateController.text = function.functionDate;

    _requestModel.id = function.id;

    if (function.functionDate.isNotEmpty) {
      try {
        _selectedDate = DateFormat("dd-MMM-yyyy").parse(function.functionDate);
      } catch (e) {
        _selectedDate = DateTime.now();
      }
    }

    if (function.invitationUrl != null && function.invitationUrl!.isNotEmpty) {
      _uploadedImageUrl = function.invitationUrl;
      _existingImageUrl = function.invitationUrl!.startsWith('http')
          ? function.invitationUrl
          : "$appImageUrl/${function.invitationUrl}";
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
    final languageProvider = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBarWidget(
        title: languageProvider.tr('upcomingFunctions.title'),
        action: [],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildTextFormWidget(
                  title: languageProvider.tr('upcomingFunctions.functionName'),
                  controller: _titleController,
                  required: true,
                  enableMic: true,
                  maxLength: 120,
                  validator: _mandatoryValidator(
                    languageProvider.tr('upcomingFunctions.functionName'),
                  ),
                  onSaved: (value) => _requestModel.title = value,
                ),
                const SizedBox(height: 16),
                _buildTextFormWidget(
                  title: languageProvider.tr('upcomingFunctions.functionDate'),
                  controller: _dateController,
                  required: true,
                  focusNode: AlwaysDisabledFocusNode(),
                  onTap: () => _selectDate(context),
                  validator: _mandatoryValidator(
                    languageProvider.tr('upcomingFunctions.functionDate'),
                  ),
                  onSaved: (value) => _requestModel.functionDate = value,
                ),
                const SizedBox(height: 16),
                _buildTextFormWidget(
                  title: languageProvider.tr('upcomingFunctions.location'),
                  controller: _locationController,
                  required: true,
                  enableMic: true,
                  maxLength: 150,
                  validator: _mandatoryValidator(
                    languageProvider.tr('upcomingFunctions.location'),
                  ),
                  onSaved: (value) => _requestModel.location = value,
                ),
                const SizedBox(height: 16),
                _buildTextFormWidget(
                  title: languageProvider.tr('upcomingFunctions.description'),
                  controller: _descriptionController,
                  required: false,
                  enableMic: true,
                  maxLines: 4,
                  onSaved: (value) => _requestModel.description = value,
                ),
                const SizedBox(height: 16),
                _buildImageUploadWidget(),
                const SizedBox(height: 32),
                AppButton(
                  title: isEditing
                      ? languageProvider.tr('common.update')
                      : languageProvider.tr('common.save'),
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
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

  String? Function(dynamic) _mandatoryValidator(String fieldName) {
    return (value) => value?.toString().trim().isEmpty == true
        ? "$fieldName ${context.read<LanguageProvider>().tr('common.required')}"
        : null;
  }

  Widget _buildImageUploadWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasImage =
        _invitationImage != null ||
        _existingImageUrl != null ||
        _uploadedImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.read<LanguageProvider>().tr('upcomingFunctions.invitation'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
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
                        child: _invitationImage != null
                            ? Image.file(
                                _invitationImage!,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            context.read<LanguageProvider>().tr(
              'upcomingFunctions.selectImage',
            ),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary.withValues(alpha: 0.7),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(languageProvider.tr('common.delete') ?? 'Delete'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _invitationImage = null;
                  _uploadedImageUrl = null;
                  _existingImageUrl = null;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                languageProvider.tr('upcomingFunctions.chooseFromGallery') ??
                    'Choose from gallery',
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(
                languageProvider.tr('upcomingFunctions.takePhoto') ??
                    'Take photo',
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // void _viewFullSizeImage() {
  //   final imageUrl = _invitationImage != null
  //       ? _invitationImage!.path
  //       : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
  //       ? _existingImageUrl!
  //       : null;
  //   if (imageUrl == null) return;

  //   showDialog(
  //     context: context,
  //     barrierColor: Colors.black87,
  //     builder: (context) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       insetPadding: EdgeInsets.zero,
  //       child: Stack(
  //         children: [
  //           Center(
  //             child: InteractiveViewer(
  //               minScale: 0.5,
  //               maxScale: 4.0,
  //               child: _invitationImage != null
  //                   ? Image.file(_invitationImage!, fit: BoxFit.contain)
  //                   : Image.network(
  //                       _existingImageUrl!,
  //                       fit: BoxFit.contain,
  //                       errorBuilder: (context, error, stackTrace) {
  //                         return const Center(
  //                           child: Icon(
  //                             Icons.error,
  //                             color: Colors.white,
  //                             size: 48,
  //                           ),
  //                         );
  //                       },
  //                     ),
  //             ),
  //           ),
  //           Positioned(
  //             top: 40,
  //             right: 20,
  //             child: IconButton(
  //               icon: const Icon(Icons.close, color: Colors.white, size: 30),
  //               onPressed: () => Navigator.pop(context),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Future<void> _downloadAndSaveImage() async {
  //   try {
  //     String? imageUrl = _existingImageUrl;
  //     if (imageUrl == null || imageUrl.isEmpty) {
  //       _alertServices.errorToast("படம் கிடைக்கவில்லை");
  //       return;
  //     }

  //     _alertServices.showLoading();

  //     if (_invitationImage != null) {
  //       await _saveLocalImage(_invitationImage!);
  //     } else {
  //       final response = await http.get(Uri.parse(imageUrl));
  //       if (response.statusCode == 200) {
  //         final tempDir = await getTemporaryDirectory();
  //         final file = File(
  //           path.join(
  //             tempDir.path,
  //             '${DateTime.now().millisecondsSinceEpoch}.jpg',
  //           ),
  //         );
  //         await file.writeAsBytes(response.bodyBytes);
  //         await _saveLocalImage(file);
  //       } else {
  //         _alertServices.hideLoading();
  //         _alertServices.errorToast("படத்தைப் பதிவிறக்க முடியவில்லை");
  //       }
  //     }
  //   } catch (e) {
  //     _alertServices.hideLoading();
  //     _alertServices.errorToast("படத்தைச் சேமிக்க முடியவில்லை");
  //     printContent("Error saving image: $e");
  //   }
  // }

  // Future<void> _saveLocalImage(File imageFile) async {
  //   try {
  //     if (Platform.isAndroid) {
  //       // Read the image file as bytes
  //       final Uint8List imageBytes = await imageFile.readAsBytes();
  //       // Convert to base64
  //       final String base64Image = base64Encode(imageBytes);

  //       // Generate unique filename with timestamp
  //       final timestamp = DateTime.now().millisecondsSinceEpoch;
  //       final fileExtension = path
  //           .extension(imageFile.path)
  //           .replaceFirst('.', ''); // Remove the dot
  //       final fileName = 'Moi_Kanakku_$timestamp';

  //       // Use flutter_file_downloader's writeFile method to save to public Downloads folder
  //       // This package handles Android 10+ scoped storage properly without MANAGE_EXTERNAL_STORAGE
  //       FileDownloader.writeFile(
  //         content: base64Image,
  //         fileName: fileName,
  //         extension: fileExtension,
  //         subPath:
  //             'Moi Kanakku', // Creates "Moi Kanakku" subfolder in Downloads
  //         downloadDestination: DownloadDestinations.publicDownloads,
  //         onCompleted: (String savedPath) {
  //           _alertServices.hideLoading();
  //           _alertServices.successToast("படம் வெற்றிகரமாக சேமிக்கப்பட்டது");
  //           printContent("Image saved to: $savedPath");
  //         },
  //         onError: (String error) {
  //           _alertServices.hideLoading();
  //           _alertServices.errorToast("படத்தைச் சேமிக்க முடியவில்லை");
  //           printContent("Error saving image: $error");
  //         },
  //       );
  //     } else if (Platform.isIOS) {
  //       // For iOS, use the app's Documents directory
  //       final documentsDir = await getApplicationDocumentsDirectory();
  //       final downloadsDir = Directory(
  //         path.join(documentsDir.path, 'Downloads', 'Moi Kanakku'),
  //       );
  //       if (!await downloadsDir.exists()) {
  //         await downloadsDir.create(recursive: true);
  //       }

  //       final timestamp = DateTime.now().millisecondsSinceEpoch;
  //       final extension = path.extension(imageFile.path);
  //       final fileName = 'Moi_Kanakku_$timestamp$extension';
  //       final destinationPath = path.join(downloadsDir.path, fileName);

  //       final savedFile = await imageFile.copy(destinationPath);
  //       _alertServices.hideLoading();
  //       _alertServices.successToast("படம் வெற்றிகரமாக சேமிக்கப்பட்டது");
  //       printContent("Image saved to: ${savedFile.path}");
  //     }
  //   } catch (e) {
  //     _alertServices.hideLoading();
  //     _alertServices.errorToast("படத்தைச் சேமிக்க முடியவில்லை");
  //     printContent("Error saving image: $e");
  //   }
  // }

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
            toolbarTitle: context.read<LanguageProvider>().tr(
              'upcomingFunctions.cropImage',
            ),
            statusBarLight: true,
            // statusBarColor: Theme.of(context).colorScheme.primary,
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

  Future<void> _selectDate(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final DateTime? picked = await showDatePicker(
      context: context,
      barrierColor: Colors.black54,
      locale: const Locale("en", "US"),
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 50),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme,
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            headerBackgroundColor: colorScheme.primary,
            headerForegroundColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd-MMM-yyyy').format(picked);
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

    // Step 1: Upload image if a new one is selected
    String imageUrl = _uploadedImageUrl ?? _existingImageUrl ?? "";
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

    var params = {
      if (isEditing) "id": _requestModel.id,
      "title": _titleController.text.trim(),
      "functionDate": _convertDate(_dateController.text),
      "location": _locationController.text.trim(),
      "description": _descriptionController.text.trim(),
      "invitationUrl": imageUrl,
      if (!isEditing) "status": "ACTIVE",
    };

    try {
      final response = !isEditing
          ? await _upcomingFunctionServices.createUpcomingFunction(params)
          : await _upcomingFunctionServices.updateUpcomingFunction(params);

      _alertServices.hideLoading();

      if (response != null &&
          response is Map &&
          response['responseType'] == "S") {
        final message =
            response['responseValue']?["message"]?.toString() ??
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
      printContent("Error saving upcoming function: $error");
    }
  }

  Future<String?> _uploadInvitationImage(File imageFile) async {
    try {
      // Get userId from secure storage
      final userData = await _secureStorage.get(AppVariables.userInformation);
      final userId = userData?['id'] ?? "";

      if (userId.isEmpty) {
        printContent("Error: User ID not found");
        return null;
      }

      final params = {"userId": userId, "path": "upcoming-function"};

      final response = await _upcomingFunctionServices
          .uploadUpcomingFunctionImage(params, imageFile.path);

      if (response != null && response['responseType'] == "S") {
        String uploadedUrl = "";

        // responseValue can be either a String (direct URL) or an object with imageUrl/url
        if (response['responseValue'] is String) {
          uploadedUrl = response['responseValue'].toString();
        } else if (response['responseValue'] is Map) {
          uploadedUrl =
              response['responseValue']?['imageUrl']?.toString() ??
              response['responseValue']?['url']?.toString() ??
              response['responseValue']?.toString() ??
              "";
        }

        if (uploadedUrl.isNotEmpty) {
          printContent("Image uploaded successfully: $uploadedUrl");
          return uploadedUrl;
        } else {
          printContent("Image upload failed: Invalid response format");
          return null;
        }
      } else {
        printContent("Image upload failed: $response");
        return null;
      }
    } catch (e) {
      printContent("Error uploading image: $e");
      return null;
    }
  }

  String _convertDate(String inputDate) {
    try {
      // If input is already in dd-MMM-yyyy format, convert to dd-MMM-yyyy
      final parsed = DateFormat("dd-MMM-yyyy").parse(inputDate);
      return DateFormat("dd-MMM-yyyy").format(parsed);
    } catch (e) {
      return inputDate;
    }
  }
}
