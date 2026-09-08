import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/users/models/login_model.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/device_info_service.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final SignUpRequestModel requestModel = SignUpRequestModel();
  final AlertServices alertServices = AlertServices();
  final UserServices userServices = UserServices();
  final SecureStorageService secureStorage = SecureStorageService();
  bool showPass = true;
  bool showCPass = true;
  String confirmPass = "";

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // Header Section with Logo and Title
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pattern - geometric shapes
                      Positioned(
                        top: -15,
                        right: -15,
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -20,
                        left: -20,
                        child: Transform.rotate(
                          angle: -0.3,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: -10,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Content
                      Column(
                        children: [
                          const SizedBox(height: 15),

                          // App Logo with container
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              AppImages.appLogoImage,
                              height: 45,
                              width: 45,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  languageProvider.tr(
                                    'auth.createAccountTitle',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Full Name Input
                TextFormWidget(
                  prefixIcon: Icons.account_circle_outlined,
                  title: languageProvider.tr('auth.fullName'),
                  required: true,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 20,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z]+|\s")),
                  ],
                  onSaved: (value) {
                    requestModel.name = value.toString().trim();
                  },
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return languageProvider.tr('auth.fullNameRequired');
                    }
                    if (value.toString().length < 3) {
                      return languageProvider.tr('auth.nameMinLength');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Email Input
                TextFormWidget(
                  title: languageProvider.tr('login.email'),
                  prefixIcon: Icons.email_outlined,
                  required: true,
                  keyboardType: TextInputType.emailAddress,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  onSaved: (value) {
                    requestModel.email = value.toString();
                  },
                  validator: (value) {
                    return EmailValidator.validateEmail(value);
                  },
                ),
                const SizedBox(height: 12),
                // Mobile Number Input
                TextFormWidget(
                  title: languageProvider.tr('profile.mobile'),
                  prefixIcon: Icons.phone_outlined,
                  required: true,
                  maxLength: 10,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onSaved: (value) {
                    requestModel.mobile = value.toString();
                  },
                  validator: (value) {
                    return PhoneValidator.validatePhone(value, required: true);
                  },
                ),
                const SizedBox(height: 12),
                // City Input
                TextFormWidget(
                  title: cityLabel,
                  prefixIcon: Icons.location_city_outlined,
                  required: true,
                  textCapitalization: TextCapitalization.characters,
                  onSaved: (value) {
                    requestModel.city = value.toString().trim();
                  },
                  validator: (value) {
                    if (value.toString().trim().isEmpty) {
                      return languageProvider.tr('auth.cityRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Password Input
                TextFormWidget(
                  title: languageProvider.tr('login.password'),
                  prefixIcon: Icons.lock_outlined,
                  required: true,
                  maxLines: 1,
                  maxLength: 16,
                  obscuringCharacter: "●",
                  obscureText: showPass,
                  suffixIconTrue: true,
                  suffixIcon: showPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  suffixIconOnPressed: () {
                    setState(() {
                      showPass = !showPass;
                    });
                  },
                  onSaved: (value) {
                    requestModel.password = value.toString();
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  validator: (value) {
                    confirmPass = value.toString();
                    if (value.toString().isEmpty) {
                      return languageProvider.tr('auth.passwordRequired');
                    }
                    if (value.toString().length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Confirm Password Input
                TextFormWidget(
                  title: languageProvider.tr('auth.confirmPassword'),
                  prefixIcon: Icons.lock_outlined,
                  required: true,
                  maxLines: 1,
                  maxLength: 16,
                  obscuringCharacter: "●",
                  textInputAction: TextInputAction.done,
                  obscureText: showCPass,
                  suffixIconTrue: true,
                  suffixIcon: showCPass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  suffixIconOnPressed: () {
                    setState(() {
                      showCPass = !showCPass;
                    });
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  validator: (value) {
                    if (value.toString().isEmpty) {
                      return languageProvider.tr('auth.passwordRequired');
                    }
                    if (value.toString().length < 8) {
                      return languageProvider.tr('auth.passwordMinLength');
                    } else if (value.toString() != confirmPass) {
                      return languageProvider.tr('auth.passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Submit Button
                AppButton(
                  title: languageProvider.tr('common.save'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      _formKey.currentState!.save();
                      submitForm();
                    }
                  },
                ),
                const SizedBox(height: 25),
                // Navigate to Login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, "login");
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        languageProvider.tr('auth.backToLogin'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to handle form submission
  void submitForm() async {
    // Get FCM token
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      final device = await DeviceService.getDeviceInfo();
      requestModel.device_id = device.device_id;
      requestModel.device_name = device.device_name;
      requestModel.brand = device.brand;
      requestModel.model = device.model;
      requestModel.manufacturer = device.manufacturer;
      requestModel.android_version = device.android_version;
      requestModel.ram_size = device.ram_size;
      if (fcmToken != null) {
        await secureStorage.saveNotificationToken(fcmToken);
        requestModel.fcm_token = fcmToken;
      } else {
        requestModel.fcm_token = "";
      }
    } catch (e) {
      // Handle error getting FCM token
      printContent("Error getting FCM token: $e");
      requestModel.fcm_token = "";
    }
    printDirect(requestModel.toJson().toString());
    var response = await userServices.signup(jsonEncode(requestModel.toJson()));
    printContent(response.toString());
    if (response != null && response['responseType'] == "S") {
      alertServices.successToast(
        response['responseValue']['message'].toString(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "login", (route) => false);
    }
  }
}
