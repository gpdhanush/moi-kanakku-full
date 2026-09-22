import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_forms/custom_dropdown.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/app_widgets/image_picker_bottom_sheet.dart';
import 'package:moi/app_utils/app_widgets/moi_user_avatar.dart';
import 'package:moi/app_utils/app_widgets/email_verify_card.dart';
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
  final TextEditingController _dobCtrl = TextEditingController();

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

  DateTime? _validDateOfBirth(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final normalized = DateUtils.dateOnly(date);
    return normalized.isAfter(today) ? null : normalized;
  }

  // Helper function to construct full image URL
  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    final trimmed = imagePath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;

    if (appImageUrl.trim().isNotEmpty) {
      return '${appImageUrl.trim()}/$normalized';
    }

    if (bootstrapApiBaseUri.trim().endsWith('/apis')) {
      final baseWithoutApis = bootstrapApiBaseUri.trim().replaceFirst(
        RegExp(r'/apis$'),
        '',
      );
      return '$baseWithoutApis/$normalized';
    }

    return '$bootstrapApiBaseUri/$normalized';
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from secure storage and API
  void _loadUserData() async {
    final userData = await _storage.get(AppVariables.userInformation);
    if (!mounted) return;
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
              _selectedDateOfBirth = _validDateOfBirth(
                AppDatePicker.parseDisplay(dobString),
              );
              if (_selectedDateOfBirth != null) {
                _dobCtrl.text = AppDatePicker.formatForDisplay(
                  _selectedDateOfBirth!,
                );
              }
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

          if (!mounted) return;
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
                  _selectedDateOfBirth = _validDateOfBirth(
                    AppDatePicker.parseDisplay(dobString),
                  );
                  if (_selectedDateOfBirth != null) {
                    _dobCtrl.text = AppDatePicker.formatForDisplay(
                      _selectedDateOfBirth!,
                    );
                  }
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

              // Profile image URL — clear when removed/missing
              final profileImageUrl = profileData["profile_image_url"];
              if (profileImageUrl != null &&
                  profileImageUrl.toString().isNotEmpty) {
                _profileImageUrl = _getFullImageUrl(profileImageUrl.toString());
              } else {
                _profileImageUrl = null;
                _profileImage = null;
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
              if (profileImageUrl != null &&
                  profileImageUrl.toString().trim().isNotEmpty) {
                _user?["profile_image"] = profileImageUrl;
                _user?["profile_image_url"] = profileImageUrl;
              } else {
                _user?.remove("profile_image");
                _user?.remove("profile_image_url");
              }
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
            _user?["is_verified"] = responseValue["is_verified"] ?? 0;
            _user?["email_verified_at"] = responseValue["email_verified_at"];
          });

          // Save flattened user data to storage for future use
          await _storage.save(AppVariables.userInformation, _user);
          if (mounted) {
            context.read<UserProvider>().updateUserDetails(_user);
          }
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
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: MoiAppHeader(
            title: languageProvider.tr('profile.title').toTitleCase(),
            showBack: true,
            onBack: () => Navigator.pop(context),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(languageProvider),
                  if (!isUserEmailVerified(_user)) ...[
                    const SizedBox(height: AppSpacing.md),
                    EmailVerifyCard(email: _emailCtrl.text),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  MoiInfoSectionLabel(
                    title: languageProvider.tr('profile.personalInformation'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPersonalInfoCard(
                    Theme.of(context),
                    Theme.of(context).colorScheme,
                    languageProvider,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MoiInfoSectionLabel(
                    title: languageProvider.tr('profile.address'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildAddressInfoCard(
                    Theme.of(context),
                    Theme.of(context).colorScheme,
                    languageProvider,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildAccountActionsSection(
                    Theme.of(context),
                    Theme.of(context).colorScheme,
                    languageProvider,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Profile Header Card — avatar + full name + email (previous layout)
  Widget _buildProfileHeader(LanguageProvider languageProvider) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDarkMode = theme.brightness == Brightness.dark;
    final deep = AppColors.deepenAccent(
      primary,
      amount: isDarkMode ? 0.6 : 0.28,
    );
    final soft = isDarkMode
        ? Color.lerp(primary, AppColors.darkSurface, 0.24)!
        : Color.lerp(primary, Colors.white, 0.22)!;
    final glow = isDarkMode
        ? AppColors.darkSurface.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.12);
    final name =
        (_user?["name"]?.toString() ?? languageProvider.tr('profile.user'))
            .trim();
    final email = _user?["email"]?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
                  AppColors.darkSurface.withValues(alpha: 0.94),
                  AppColors.darkSurfaceVariant,
                  primary.withValues(alpha: 0.78),
                ]
              : [primary, soft, deep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? primary.withValues(alpha: 0.18)
                : primary.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle, color: glow),
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
                color: glow.withValues(alpha: isDarkMode ? 0.8 : 0.7),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? AppColors.darkSurfaceVariant.withValues(
                                  alpha: 0.90,
                                )
                              : Colors.white.withValues(alpha: 0.2),
                          border: Border.all(
                            color: isDarkMode
                                ? AppColors.darkBorder
                                : Colors.white.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: _profileImage != null
                              ? Image.file(
                                  _profileImage!,
                                  fit: BoxFit.cover,
                                  width: 68,
                                  height: 68,
                                )
                              : MoiUserAvatar(
                                  imageUrl: _profileImageUrl ?? '',
                                  gender: _selectedGender,
                                  size: 68,
                                  onImageMissing: () {
                                    if (!mounted) return;
                                    final missingUrl = _profileImageUrl;
                                    setState(() {
                                      _profileImageUrl = null;
                                      _user?.remove('profile_image');
                                      _user?.remove('profile_image_url');
                                    });
                                    _storage.save(
                                      AppVariables.userInformation,
                                      _user,
                                    );
                                    context
                                        .read<UserProvider>()
                                        .clearProfileImage(
                                          fromMissingFile: true,
                                          missingUrl: missingUrl,
                                        );
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.darkSurfaceElevated
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedPencilEdit02,
                            strokeWidth: 1.8,
                            size: 14,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   languageProvider.tr('profile.name'),
                      //   style: AppTypography.body.copyWith(
                      //     color: Colors.white.withValues(alpha: 0.82),
                      //     fontSize: 12,
                      //     fontWeight: FontWeight.w600,
                      //   ),
                      // ),
                      // const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.toUpperCase(),
                              style: AppTypography.sectionTitle.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // if (isUserEmailVerified(_user)) ...[
                      //   const EmailVerifiedBadge(size: 18),
                      //   const SizedBox(width: 6),
                      // ],
                      Text(
                        email,
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
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
    return MoiInfoCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name input field
              TextFormWidget(
                title: languageProvider.tr('profile.name'),
                controller: _nameCtrl,
                required: true,
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
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  return PhoneValidator.validatePhone(value, required: false);
                },
              ),
              const SizedBox(height: 16),
              // Email field (read-only) with verified badge before the label/value
              TextFormWidget(
                title: languageProvider.tr('profile.email'),
                controller: _emailCtrl,
                required: false,
                readOnly: true,
                enabled: false,
                prefixIcon: isUserEmailVerified(_user)
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedMail01,
                iconColor: isUserEmailVerified(_user)
                    ? colorScheme.primary
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
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
        controller: _dobCtrl,
        readOnly: true,
        enabled: false,
        required: false,
      ),
    );
  }

  // Date picker handler
  Future<void> _selectDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDate = _selectedDateOfBirth == null
        ? today
        : DateUtils.dateOnly(_selectedDateOfBirth!);
    final initialDate = selectedDate.isAfter(today) ? today : selectedDate;

    final DateTime? picked = await AppDatePicker.pick(
      context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
    );

    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
        _dobCtrl.text = AppDatePicker.formatForDisplay(picked);
      });
    }
  }

  // Account Actions Section
  Widget _buildAccountActionsSection(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    final primary = colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          title: languageProvider.tr('profile.updateProfile'),
          onPressed: _updateDetails,
          showIcon: false,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          languageProvider.tr('profile.accountActions'),
          style: AppTypography.label.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActionCard(
          icon: HugeIcons.strokeRoundedLockPassword,
          title: languageProvider.tr('auth.changePassword'),
          subtitle: languageProvider.tr('auth.passwordMinLength'),
          iconBg: primary.withValues(alpha: 0.1),
          iconColor: primary,
          onTap: () => Navigator.pushNamed(context, "change-password"),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActionCard(
          icon: HugeIcons.strokeRoundedDelete02,
          title: languageProvider.tr('profile.deleteAccount'),
          subtitle: languageProvider.tr('profile.deleteAccountConfirmation'),
          iconBg: isDark
              ? AppColors.darkError.withValues(alpha: 0.15)
              : AppColors.lightError.withValues(alpha: 0.12),
          iconColor: isDark ? AppColors.darkError : AppColors.lightError,
          isDestructive: true,
          onTap: () async {
            final confirm = await showMoiConfirmSheet(
              context: context,
              title: languageProvider.tr('profile.deleteAccount'),
              message: languageProvider.tr('profile.deleteAccountConfirmation'),
              confirmLabel: languageProvider.tr('common.yes'),
              cancelLabel: languageProvider.tr('common.no'),
              icon: HugeIcons.strokeRoundedDelete02,
              isDestructive: true,
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
    required List<List<dynamic>> icon,
    required String title,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: icon,
                  color: iconColor,
                  size: 18,
                  strokeWidth: 1.8,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.label.copyWith(
                        color: isDestructive
                            ? (isDark
                                  ? AppColors.darkError
                                  : AppColors.lightError)
                            : isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                strokeWidth: 1.9,
                size: 16,
                color: isDestructive
                    ? (isDark ? AppColors.darkError : AppColors.lightError)
                    : isDark
                    ? AppColors.darkTextSecondary
                    : const Color(0xffA1A1AA),
              ),
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
    try {
      await _alertServices.showLoading();
      final userData = await _storage.get(AppVariables.userInformation);
      var params = {'email': userData['email'].toString()};
      final response = await _userServices.deleteUserAccount(
        params,
        showLoading: false,
      );
      if (response != null && response['responseType'] == "S") {
        _alertServices.successToast(response['responseValue']['message']);
        await _storage.clearSessionData();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, 'login', (r) => false);
      }
    } catch (error) {
      _alertServices.errorToast(languageProvider.tr('common.tryAgain'));
    } finally {
      await _alertServices.hideLoading();
    }
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
      await _removeProfilePhoto();
    } else {
      await _pickImage(
        action == ImagePickerAction.gallery
            ? ImageSource.gallery
            : ImageSource.camera,
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final hadServerImage =
        _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    // Local preview only (not uploaded yet) — clear UI state.
    if (!hadServerImage) {
      setState(() {
        _profileImage = null;
        _profileImageUrl = null;
      });
      return;
    }

    if (_user == null || _user?["id"] == null) {
      _alertServices.errorToast(languageProvider.tr('profile.userInfoMissing'));
      return;
    }

    final previousUrl = _profileImageUrl;
    try {
      final userId = _user?["id"];
      final response = await _userServices.removeProfileImage({
        "userId": userId is int ? userId.toString() : userId,
      });

      if (response != null &&
          response is Map &&
          response['responseType'] == 'S') {
        if (previousUrl != null && previousUrl.isNotEmpty) {
          await NetworkImage(previousUrl).evict();
        }

        setState(() {
          _profileImage = null;
          _profileImageUrl = null;
          _user?.remove('profile_image');
          _user?.remove('profile_image_url');
        });

        await _storage.save(AppVariables.userInformation, _user);
        if (mounted) {
          await context.read<UserProvider>().clearProfileImage(
            missingUrl: previousUrl,
          );
        }

        _alertServices.successToast(
          response['responseValue'] is Map
              ? (response['responseValue']['message']?.toString() ??
                    languageProvider.tr('profile.photoRemoved'))
              : languageProvider.tr('profile.photoRemoved'),
        );
      } else {
        final errorMessage = response is Map
            ? (response['responseValue'] is Map
                  ? response['responseValue']['message']
                  : response['message'] ?? response['responseValue'])
            : null;
        _alertServices.errorToast(
          errorMessage?.toString() ??
              languageProvider.tr('profile.failedToUpdateProfile'),
        );
      }
    } catch (e) {
      printContent("Error removing profile image: $e");
      _alertServices.errorToast(
        languageProvider.tr('profile.failedToUpdateProfile'),
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
    return ImageUploadCropper.crop(
      context: context,
      imagePath: imagePath,
      title: context.read<LanguageProvider>().tr('profile.cropImage'),
      compressQuality: 85,
    );
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

    await _alertServices.showLoading();

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
      // Page owns the loader — avoid Connection double-count.
      final response = await _userServices.updateUserDetails(
        params,
        showLoading: false,
      );

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
      printContent("Error updating profile: $error");
      _alertServices.errorToast(languageProvider.tr('common.tryAgain'));
    } finally {
      await _alertServices.hideLoading();
    }
  }

  // Address Information Card
  Widget _buildAddressInfoCard(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   "முகவரி விவரங்கள்",
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     fontWeight: FontWeight.bold,
          //     fontFamily: 'Inter',
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
    );
  }
}
