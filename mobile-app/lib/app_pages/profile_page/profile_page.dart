import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_forms/custom_dropdown.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/image_picker_bottom_sheet.dart';
import 'package:moi/app_utils/device_info_service.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SecureStorageService _storage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final UserServices _userServices = UserServices();

  // Personal Information Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  // Address Controllers
  final TextEditingController _addressLine1Ctrl = TextEditingController();
  final TextEditingController _addressLine2Ctrl =
      TextEditingController(); // ADD THIS
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _postalCodeCtrl = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // State variables
  dynamic _user;
  File? _profileImage;
  String? _profileImageUrl;
  bool _deviceIdIsNull = false;

  // Dropdown values
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

  // Helper function to construct full image URL
  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    // Otherwise prepend appImageUrl
    // Remove leading slash if present to avoid double slashes
    final path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    return '$appImageUrl$path';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from secure storage and API
  void _loadUserData() async {
    final userData = await _storage.get(AppVariables.userInformation);
    setState(() {
      _user = userData;
      if (_user != null) {
        _nameCtrl.text = _user?["name"] ?? "";
        _emailCtrl.text = _user?["email"] ?? "";
        _mobileCtrl.text = _user?["mobile"] ?? "";
        _selectedGender = _user?["gender"];

        // Parse date of birth using shared utility
        if (_user?["date_of_birth"] != null &&
            _user!["date_of_birth"].toString().isNotEmpty) {
          try {
            final dobString = _user?["date_of_birth"].toString();
            if (dobString != null) {
              _selectedDateOfBirth = AppDatePicker.parseDisplay(dobString);
            }
          } catch (e) {
            printContent("Error parsing date of birth: $e");
          }
        }

        // Load address fields from storage if available
        _addressLine1Ctrl.text = _user?["address_line1"] ?? "";
        _addressLine2Ctrl.text = _user?["address_line2"] ?? "";
        _cityCtrl.text = _user?["city"] ?? "";
        _stateCtrl.text = _user?["state"] ?? "";
        _countryCtrl.text = _user?["country"] ?? "";
        _postalCodeCtrl.text = _user?["postal_code"] ?? "";

        // Load profile image URL if available
        if (_user?["profile_image"] != null &&
            _user!["profile_image"].toString().isNotEmpty) {
          _profileImageUrl = _getFullImageUrl(
            _user?["profile_image"]?.toString(),
          );
        }
      }
    });

    // Fetch important details from API
    if (_user != null && _user?["id"] != null) {
      await _fetchUserImportantDetails();
    }
  }

  // Fetch user important details from API
  Future<void> _fetchUserImportantDetails() async {
    try {
      final userId = _user?["id"]?.toString();
      if (userId == null) return;

      final response = await _userServices.getUserImportantDetails(userId);

      if (response != null && response['responseType'] == "S") {
        final responseValue = response['responseValue'];

        if (responseValue != null) {
          // Extract from nested profile object
          final profileData = responseValue["profile"];

          setState(() {
            // Update basic info
            _nameCtrl.text =
                responseValue["name"]?.toString() ?? _nameCtrl.text;
            _emailCtrl.text =
                responseValue["email"]?.toString() ?? _emailCtrl.text;
            _mobileCtrl.text =
                responseValue["mobile"]?.toString() ?? _mobileCtrl.text;

            // Extract profile data (nested object)
            if (profileData != null && profileData is Map) {
              // Gender
              final gender = profileData["gender"];
              if (gender != null) {
                _selectedGender = gender.toString();
              }

              // Date of birth
              if (profileData["date_of_birth"] != null &&
                  profileData["date_of_birth"].toString().isNotEmpty) {
                try {
                  final dobString = profileData["date_of_birth"].toString();
                  _selectedDateOfBirth = AppDatePicker.parseDisplay(dobString);
                } catch (e) {
                  printContent("Error parsing date of birth: $e");
                }
              }

              // Address fields - ensure non-null values
              final addr1 = profileData["address_line1"];
              final addr2 = profileData["address_line2"];
              final city = profileData["city"];
              final state = profileData["state"];
              final country = profileData["country"];
              final postal = profileData["postal_code"];

              _addressLine1Ctrl.text = addr1?.toString() ?? "";
              _addressLine2Ctrl.text = addr2?.toString() ?? "";
              _cityCtrl.text = city?.toString() ?? "";
              _stateCtrl.text = state?.toString() ?? "";
              _countryCtrl.text = country?.toString() ?? "";
              _postalCodeCtrl.text = postal?.toString() ?? "";

              printContent(
                "Loaded address data - Line1: ${_addressLine1Ctrl.text}, City: ${_cityCtrl.text}",
              );

              // Profile image URL
              final profileImageUrl = profileData["profile_image_url"];
              if (profileImageUrl != null &&
                  profileImageUrl.toString().isNotEmpty) {
                _profileImageUrl = _getFullImageUrl(profileImageUrl.toString());
              }

              // Update _user object with flattened data
              _user?["gender"] = gender;
              _user?["date_of_birth"] = profileData["date_of_birth"];
              _user?["address_line1"] = addr1;
              _user?["address_line2"] = addr2;
              _user?["city"] = city;
              _user?["state"] = state;
              _user?["country"] = country;
              _user?["postal_code"] = postal;
              _user?["profile_image"] = profileImageUrl;
            } else {
              printContent(
                "Warning: profile object is null or not a Map in API response",
              );
            }

            // Check if device_id is null from nested device object
            final deviceData = responseValue["device"];
            _deviceIdIsNull =
                deviceData == null ||
                deviceData["device_id"] == null ||
                deviceData["device_id"].toString().isEmpty;

            // Update basic user fields
            _user?["name"] = responseValue["name"] ?? _user?["name"];
            _user?["email"] = responseValue["email"] ?? _user?["email"];
            _user?["mobile"] = responseValue["mobile"] ?? _user?["mobile"];
            _user?["status"] = responseValue["status"];
            _user?["referral_code"] = responseValue["referral_code"];
          });

          // Save flattened user data to storage for future use
          await _storage.save(AppVariables.userInformation, _user);
          printContent("Saved user data to storage after API fetch");
        }
      }
    } catch (e) {
      printContent("Error fetching user important details: $e");
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose(); // ADD THIS
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          appBar: AppBarWidget(
            title: languageProvider.tr('profile.title'),
            action: const [],
          ),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.05),
                  colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileHeader(languageProvider),
                        const SizedBox(height: 20),
                        _buildPersonalInfoCard(
                          theme,
                          colorScheme,
                          languageProvider,
                        ),
                        const SizedBox(height: 20),
                        _buildAddressInfoCard(
                          theme,
                          colorScheme,
                          languageProvider,
                        ),
                        const SizedBox(height: 20),
                        _buildAccountActionsSection(
                          theme,
                          colorScheme,
                          languageProvider,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Profile Header Card
  Widget _buildProfileHeader(LanguageProvider languageProvider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_profileImageUrl != null &&
                                    _profileImageUrl!.isNotEmpty)
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : const AssetImage(AppImages.profileImage),
                        ),
                      ),
                      // Edit icon overlay
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.primary,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.tr('profile.name'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: "appFontFamily",
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _user?["name"]?.toString() ??
                            languageProvider.tr('profile.user'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: "appFontFamily",
                          fontSize: 18,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _user?["email"]?.toString() ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: "appFontFamily",
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Personal Information Card
  Widget _buildPersonalInfoCard(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    return Card(
      elevation: 4,
      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name input field
            TextFormWidget(
              title: languageProvider.tr('profile.name'),
              controller: _nameCtrl,
              required: true,
              // prefixIcon: Icons.person_outline_outlined, // removed
              validator: (value) => value?.isEmpty == true
                  ? languageProvider.tr('profile.enterValidName')
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGenderDropdown(
                    theme,
                    colorScheme,
                    languageProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateOfBirthField(
                    theme,
                    colorScheme,
                    languageProvider,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mobile number input field
            TextFormWidget(
              title: languageProvider.tr('profile.mobile'),
              controller: _mobileCtrl,
              required: false,
              // prefixIcon: Icons.phone_outlined, // removed
              keyboardType: TextInputType.phone,
              validator: (value) {
                return PhoneValidator.validatePhone(value, required: false);
              },
            ),
            const SizedBox(height: 16),
            // Email field (read-only)
            TextFormWidget(
              title: languageProvider.tr('profile.email'),
              controller: _emailCtrl,
              required: false,
              readOnly: true,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  // Gender Dropdown
  Widget _buildGenderDropdown(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    final genderOptions = [
      DropdownMenuEntry(
        value: "MALE",
        label: languageProvider.tr('profile.male'),
      ),
      DropdownMenuEntry(
        value: "FEMALE",
        label: languageProvider.tr('profile.female'),
      ),
      DropdownMenuEntry(
        value: "OTHER",
        label: languageProvider.tr('profile.other'),
      ),
    ];

    return CustomDropdown(
      dropdownMenuEntries: genderOptions,
      onSelected: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
      required: false,
      title: languageProvider.tr('profile.gender'),
      initialSelection: _selectedGender,
      showArrow: true,
    );
  }

  // Date of Birth Picker
  Widget _buildDateOfBirthField(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    // A uniform date-of-birth field that reuses the shared picker logic
    return InkWell(
      onTap: () => _selectDate(context),
      child: TextFormWidget(
        title: languageProvider.tr('profile.dateOfBirth'),
        controller: TextEditingController(
          text: _selectedDateOfBirth != null
              ? AppDatePicker.formatForDisplay(_selectedDateOfBirth!)
              : '',
        ),
        readOnly: true,
        enabled: false,
        required: false,
      ),
    );
  }

  // Date picker handler
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await AppDatePicker.pick(
      context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  // Account Actions Section
  Widget _buildAccountActionsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Update Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: AppButton(
            title: languageProvider.tr('profile.updateProfile'),
            onPressed: _updateDetails,
          ),
        ),
        const SizedBox(height: 20),
        Divider(
          color: colorScheme.primary.withValues(alpha: 0.8),
          thickness: 1,
          indent: 0.5,
          endIndent: 0.5,
        ),
        // const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            languageProvider.tr('profile.accountActions'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: "appFontFamily",
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Change password option
        _buildActionCard(
          theme: theme,
          colorScheme: colorScheme,
          icon: Icons.lock_outline,
          title: languageProvider.tr('auth.changePassword'),
          color: colorScheme.primary,
          onTap: () => Navigator.pushNamed(context, "change-password"),
        ),
        const SizedBox(height: 12),
        // Delete account option
        _buildActionCard(
          theme: theme,
          colorScheme: colorScheme,
          icon: Icons.delete_outline_outlined,
          title: languageProvider.tr('profile.deleteAccount'),
          color: Colors.red,
          backgroundColor: Colors.red.shade50,
          onTap: () async {
            bool? confirm = await _alertServices.confirmAlert(
              context,
              languageProvider.tr('profile.deleteAccountConfirmation'),
            );
            if (confirm == true) {
              deleteUser();
            }
          },
        ),
      ],
    );
  }

  // Action Card Widget
  Widget _buildActionCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: "appFontFamily",
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_outlined, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Delete user account
  Future<void> deleteUser() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    FocusScope.of(context).unfocus();
    _alertServices.showLoading();
    final userData = await _storage.get(AppVariables.userInformation);
    var params = {'email': userData['email'].toString()};
    _userServices
        .deleteUserAccount(params)
        .then((response) {
          _alertServices.hideLoading();
          if (response != null && response['responseType'] == "S") {
            _alertServices.successToast(response['responseValue']['message']);
            _storage.clearSessionData();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, 'login', (r) => false);
          }
        })
        .catchError((error) {
          _alertServices.hideLoading();
          _alertServices.errorToast(languageProvider.tr('common.tryAgain'));
        });
  }

  // Show image picker options
  Future<void> _showImagePickerOptions() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final permissions =
        await ImagePickerPermissions.checkImagePickerPermissions();
    final hasCameraPermission = permissions['camera'] ?? false;
    final hasPhotosPermission = permissions['photos'] ?? false;

    if (!mounted) return;
    final action = await ImagePickerBottomSheet.show(
      context: context,
      title: languageProvider.tr('profile.selectImage'),
      galleryLabel: languageProvider.tr('profile.selectFromGallery'),
      cameraLabel: languageProvider.tr('profile.takePhoto'),
      deleteLabel: languageProvider.tr('profile.removePhoto'),
      permissionsMessage: languageProvider.tr('profile.permissionsNeeded'),
      canUseGallery: hasPhotosPermission,
      canUseCamera: hasCameraPermission,
      showDelete: _profileImage != null || _profileImageUrl != null,
    );

    if (!mounted || action == null) return;
    if (action == ImagePickerAction.delete) {
      setState(() {
        _profileImage = null;
        _profileImageUrl = null;
      });
    } else {
      await _pickImage(
        action == ImagePickerAction.gallery
            ? ImageSource.gallery
            : ImageSource.camera,
      );
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      final hasPermission = source == ImageSource.camera
          ? await ImagePickerPermissions.ensureCameraPermission()
          : await ImagePickerPermissions.ensureGalleryPermission();

      if (!hasPermission) {
        _alertServices.errorToast(
          source == ImageSource.camera
              ? languageProvider.tr('profile.cameraPermissionNeeded')
              : languageProvider.tr('profile.storagePermissionNeeded'),
        );
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100, // Get full quality for cropping
      );

      if (pickedFile != null) {
        // Step 1: Crop the image
        final croppedFile = await _cropImage(pickedFile.path);
        if (croppedFile == null) {
          // User cancelled cropping
          return;
        }

        // Step 2: Compress the cropped image
        final compressedFile = await _compressImage(croppedFile.path);
        if (compressedFile == null) {
          _alertServices.errorToast(
            languageProvider.tr('profile.compressFailed'),
          );
          return;
        }

        setState(() {
          _profileImage = compressedFile;
        });

        // Step 3: Upload the processed image to server
        await _uploadProfileImage(compressedFile);
      }
    } catch (e) {
      _alertServices.errorToast(languageProvider.tr('profile.imagePickFailed'));
      printContent("Error picking image: $e");
    }
  }

  // Crop image
  Future<File?> _cropImage(String imagePath) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      final primary = Theme.of(context).colorScheme.primary;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: languageProvider.tr('profile.cropImage'),
            showCropGrid: true,
            toolbarColor: primary,
            toolbarWidgetColor: Colors.white,
            // ignore: deprecated_member_use
            statusBarColor: primary,
            statusBarLight: true,
            activeControlsWidgetColor: primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: languageProvider.tr('profile.cropImage'),
            aspectRatioLockEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      printContent("Error cropping image: $e");
      // If cropping fails, return original image
      return File(imagePath);
    }
  }

  // Compress image
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
        minWidth: 512,
        minHeight: 512,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        return File(compressedFile.path);
      }
      return null;
    } catch (e) {
      printContent("Error compressing image: $e");
      // If compression fails, return original file
      return File(imagePath);
    }
  }

  // Upload profile image to server
  Future<void> _uploadProfileImage(File imageFile) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      if (_user == null || _user?["id"] == null) {
        _alertServices.errorToast(
          languageProvider.tr('profile.userInfoMissing'),
        );
        return;
      }

      // Send userId as the parameter name per API spec
      final userId = _user?["id"];
      final params = {"userId": userId is int ? userId.toString() : userId};

      final response = await _userServices.uploadProfileImage(
        params,
        imageFile.path,
      );

      if (response != null) {
        // Check if response is a Map
        if (response is Map) {
          // Check for success response with responseType
          if (response['responseType'] == "S") {
            final responseValue = response['responseValue'];

            // Update profile image URL from response
            if (responseValue != null &&
                responseValue is Map &&
                responseValue["profile_image"] != null &&
                responseValue["profile_image"].toString().isNotEmpty) {
              setState(() {
                _profileImageUrl = _getFullImageUrl(
                  responseValue["profile_image"]?.toString(),
                );
                // Clear local file since we now have the server URL
                _profileImage = null;
                // Update user object
                _user?["profile_image"] = responseValue["profile_image"];
              });

              // Save updated user data to storage
              await _storage.save(AppVariables.userInformation, _user);

              _alertServices.successToast(
                responseValue["message"]?.toString() ??
                    languageProvider.tr('profile.imageUploadSuccess'),
              );
            } else {
              // Success but no profile_image in response - fetch updated user details
              await _fetchUserImportantDetails();
              _alertServices.successToast(
                responseValue?["message"]?.toString() ??
                    languageProvider.tr('profile.imageUploadSuccess'),
              );
            }
          } else if (response['responseType'] == "E" ||
              response['responseType'] == "F" ||
              response['status'] == "error" ||
              response['success'] == false) {
            // Error response
            final errorMessage = response['responseValue'] is Map
                ? response['responseValue']['message']
                : response['message'] ?? response['responseValue']?.toString();
            _alertServices.errorToast(
              errorMessage?.toString() ??
                  languageProvider.tr('profile.uploadFailed'),
            );
          } else {
            // Response is a Map but format is unknown - assume success and fetch updated data
            // This handles cases where API returns success but in different format
            printContent("Unexpected response format: $response");

            // Try to extract profile_image directly from response
            String? profileImagePath;
            if (response["profile_image"] != null) {
              profileImagePath = response["profile_image"].toString();
            } else if (response["data"] is Map &&
                response["data"]["profile_image"] != null) {
              profileImagePath = response["data"]["profile_image"].toString();
            }

            if (profileImagePath != null && profileImagePath.isNotEmpty) {
              setState(() {
                _profileImageUrl = _getFullImageUrl(profileImagePath);
                _profileImage = null;
                _user?["profile_image"] = profileImagePath;
              });
              await _storage.save(AppVariables.userInformation, _user);
            } else {
              // Fetch updated user details to get the profile image
              await _fetchUserImportantDetails();
            }

            _alertServices.successToast(
              response["message"]?.toString() ??
                  languageProvider.tr('profile.imageUploadSuccess'),
            );
          }
        } else {
          // Response is not a Map - might be a string or other type
          // Since upload likely succeeded, fetch updated user details
          printContent(
            "Response is not a Map, type: ${response.runtimeType}, value: $response",
          );
          await _fetchUserImportantDetails();
          _alertServices.successToast(
            languageProvider.tr('profile.imageUploadSuccess'),
          );
        }
      } else {
        // Response is null - check if file was uploaded by fetching user details
        // Sometimes API returns null on success
        await _fetchUserImportantDetails();
        _alertServices.successToast(
          languageProvider.tr('profile.imageUploadSuccess'),
        );
      }
    } catch (e) {
      printContent("Error uploading profile image: $e");
      // Even if there's an error, try to fetch updated user details
      // in case the upload actually succeeded
      try {
        await _fetchUserImportantDetails();
        _alertServices.successToast(
          languageProvider.tr('profile.imageUploadSuccess'),
        );
      } catch (fetchError) {
        _alertServices.errorToast(languageProvider.tr('profile.uploadFailed'));
      }
    }
  }

  // Update user details
  Future<void> _updateDetails() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;

    _alertServices.showLoading();

    final params = {
      "id": _user?["id"]?.toString(),
      "name": _nameCtrl.text.trim(),
      "status": "ACTIVE",
      "gender": _selectedGender,
      "date_of_birth": _selectedDateOfBirth != null
          ? "${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}"
          : null,
      "mobile": _mobileCtrl.text.trim(),
      "address_line1": _addressLine1Ctrl.text.trim(),
      "address_line2": _addressLine2Ctrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "state": _stateCtrl.text.trim(),
      "country": _countryCtrl.text.trim(),
      "postal_code": _postalCodeCtrl.text.trim(),
    };

    // Add device info if device_id is null
    if (_deviceIdIsNull) {
      try {
        final mToken = await FirebaseMessaging.instance.getToken();
        final device = await DeviceService.getDeviceInfo();
        params.addAll({
          "token": mToken,
          "device_id": device.device_id,
          "device_name": device.device_name,
          "brand": device.brand,
          "model": device.model,
          "manufacturer": device.manufacturer,
          "android_version": device.android_version,
          "ram_size": device.ram_size,
        });
      } catch (e) {
        printContent("Error getting device info: $e");
      }
    }

    try {
      final response = await _userServices.updateUserDetails(params);
      _alertServices.hideLoading();

      if (response != null && response['responseType'] == "S") {
        _alertServices.successToast(
          response['responseValue']['message'] ??
              languageProvider.tr('profile.profileUpdatedSuccessfully'),
        );

        // Update user object locally
        setState(() {
          _user?["name"] = _nameCtrl.text.trim();
          _user?["mobile"] = _mobileCtrl.text.trim();
          _user?["gender"] = _selectedGender;
          _user?["date_of_birth"] = _selectedDateOfBirth != null
              ? "${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}"
              : _user?["date_of_birth"];
          _user?["address_line1"] = _addressLine1Ctrl.text.trim();
          _user?["address_line2"] = _addressLine2Ctrl.text.trim();
          _user?["city"] = _cityCtrl.text.trim();
          _user?["state"] = _stateCtrl.text.trim();
          _user?["country"] = _countryCtrl.text.trim();
          _user?["postal_code"] = _postalCodeCtrl.text.trim();
        });

        // Save updated user data to storage
        await _storage.save(AppVariables.userInformation, _user);

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "home", (route) => false);
      } else {
        final errorMessage =
            response?['responseValue']?['message'] ??
            response?["message"] ??
            languageProvider.tr('profile.failedToUpdateProfile');
        _alertServices.errorToast(errorMessage);
      }
    } catch (error) {
      _alertServices.hideLoading();
      printContent("Error updating profile: $error");
      _alertServices.errorToast(languageProvider.tr('common.tryAgain'));
    }
  }

  // Address Information Card
  Widget _buildAddressInfoCard(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    return Card(
      elevation: 4,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   "முகவரி விவரங்கள்",
            //   style: theme.textTheme.titleMedium?.copyWith(
            //     fontWeight: FontWeight.bold,
            //     fontFamily: "appFontFamily",
            //     color: colorScheme.primary,
            //   ),
            // ),
            // const SizedBox(height: 16),
            TextFormWidget(
              title: languageProvider.tr('profile.addressLine1'),
              controller: _addressLine1Ctrl,
              required: false,
              enableMic: true,
            ),
            const SizedBox(height: 12),

            TextFormWidget(
              title: languageProvider.tr('profile.addressLine2'),
              controller: _addressLine2Ctrl,
              required: false,
              enableMic: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormWidget(
                    title: languageProvider.tr('profile.city'),
                    controller: _cityCtrl,
                    required: false,
                    enableMic: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormWidget(
                    title: languageProvider.tr('profile.state'),
                    controller: _stateCtrl,
                    required: false,
                    enableMic: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormWidget(
                    title: languageProvider.tr('profile.country'),
                    controller: _countryCtrl,
                    required: false,
                    enableMic: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormWidget(
                    title: languageProvider.tr('profile.postalCode'),
                    controller: _postalCodeCtrl,
                    required: false,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
