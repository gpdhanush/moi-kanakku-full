import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  AlertServices alertServices = AlertServices();
  SecureStorageService secureStorage = SecureStorageService();
  bool _switchValue = false;
  bool isDarkMode = false;

  // Define thumbIcon for the Switch widget
  final thumbIcon = WidgetStateProperty.resolveWith<Icon?>((
    Set<WidgetState> states,
  ) {
    return states.contains(WidgetState.selected)
        ? const Icon(Icons.check)
        : const Icon(Icons.close);
  });

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await checkBio();
    // final darkMode = await secureStorage.get(AppVariables.isDark);
    // if (mounted) {
    //   setState(() {
    //     isDarkMode = darkMode;
    //   });
    // }
  }

  // Check biometric settings and update switch value
  Future<void> checkBio() async {
    final value = await secureStorage.get(AppVariables.appLock) ?? false;
    if (mounted) {
      setState(() {
        _switchValue = value;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _updateStatusBarColor() {
    final colorScheme = Theme.of(context).colorScheme;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: colorScheme.primary,
        statusBarIconBrightness: colorScheme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: colorScheme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStatusBarColor();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return Scaffold(
          backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          appBar: AppBarWidget(
            title: languageProvider.tr('settings.title'),
            action: const [],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // App Information Section
                  _buildSectionHeader(
                    languageProvider.tr('settings.appInformation'),
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildListTile(
                    icon: Icons.phone_iphone_outlined,
                    title: languageProvider.tr('settings.appName'),
                    trailingText: appName.toUpperCase(),
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 8),
                  _buildListTile(
                    icon: Icons.info_outline,
                    title: languageProvider.tr('settings.appVersion'),
                    trailingText: appVersion,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(height: 24),
                  // Security Section
                  _buildSectionHeader(
                    languageProvider.tr('settings.security'),
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildAppLockSwitch(theme, colorScheme),
                  const SizedBox(height: 24),
                  // Language Section
                  _buildSectionHeader(
                    languageProvider.tr('settings.language'),
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildLanguageSelector(theme, colorScheme, languageProvider),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    languageProvider.tr('settings.voiceLanguage'),
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  _buildVoiceLanguageSelector(
                    theme,
                    colorScheme,
                    languageProvider,
                  ),
                  const SizedBox(height: 28),
                  // Theme Section
                  _buildSectionHeader(
                    languageProvider.tr('settings.theme'),
                    colorScheme,
                  ),
                  // _buildDarkModeSwitch(
                  //   isDark
                  //       ? theme
                  //       : theme.copyWith(
                  //           colorScheme: theme.colorScheme.copyWith(
                  //             primary: themeProvider.seedColor,
                  //           ),
                  //         ),
                  //   colorScheme,
                  // ),
                  const SizedBox(height: 16),
                  _buildColorGrid(context, themeProvider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build section header
  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: isDark ? Colors.grey.shade300 : colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Helper method to build modern card-based ListTile widgets
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String trailingText,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark
              ? Colors.grey.shade700
              : colorScheme.primary.withValues(alpha: 0.5),
          width: 1,
        ),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        //     blurRadius: 8,
        //     offset: const Offset(0, 2),
        //     spreadRadius: 0,
        //   ),
        // ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.grey.shade200 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  trailingText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the switch for app lock with biometric authentication
  Widget _buildAppLockSwitch(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: colorScheme.primary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Provider.of<LanguageProvider>(
                        context,
                        listen: false,
                      ).tr('settings.appLock'),
                      style: TextStyle(
                        color: isDark ? Colors.grey.shade200 : Colors.black87,
                        fontSize: 15,
                        fontFamily: "appFontFamily",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                thumbIcon: thumbIcon,
                value: _switchValue,
                thumbColor: WidgetStatePropertyAll(colorScheme.primary),
                inactiveTrackColor: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300,
                trackOutlineColor: WidgetStatePropertyAll(
                  colorScheme.primary.withValues(alpha: 0.3),
                ),
                activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                inactiveThumbColor: isDark
                    ? Colors.grey.shade600
                    : Colors.white,
                activeThumbColor: Colors.white,
                overlayColor: WidgetStatePropertyAll(
                  colorScheme.primary.withValues(alpha: 0.1),
                ),
                trackOutlineWidth: const WidgetStatePropertyAll(2),
                onChanged: (value) async {
                  if (await _authenticateUser()) {
                    if (mounted) {
                      setState(() {
                        _switchValue = value;
                      });
                      await secureStorage.save(AppVariables.appLock, value);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Authenticate user using biometrics
  Future<bool> _authenticateUser() async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    try {
      final LocalAuthentication auth = LocalAuthentication();
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported =
          canCheckBiometrics || await auth.isDeviceSupported();

      if (isDeviceSupported) {
        final List<BiometricType> availableBiometrics = await auth
            .getAvailableBiometrics();
        if (availableBiometrics.isNotEmpty &&
            (availableBiometrics.contains(BiometricType.strong) ||
                availableBiometrics.contains(BiometricType.face))) {
          return await auth.authenticate(
            localizedReason: languageProvider.tr('settings.biometricReason'),
            biometricOnly: true,
            sensitiveTransaction: true,
            persistAcrossBackgrounding: false,
          );
        } else {
          alertServices.errorToast(
            languageProvider.tr('settings.biometricsEmpty'),
          );
        }
      } else {
        alertServices.errorToast(
          languageProvider.tr('settings.deviceNotSupported'),
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'no_fragment_activity') {
        alertServices.errorToast(
          languageProvider.tr('settings.authenticationUnavailable'),
        );
      } else {
        alertServices.errorToast(
          '${languageProvider.tr('settings.authenticationFailed')}: ${e.message}',
        );
      }
    } catch (e) {
      alertServices.errorToast(languageProvider.tr('settings.unexpectedError'));
    }
    return false;
  }

  // Build the switch for dark mode
  // ListTile _buildDarkModeSwitch(ThemeData theme, ColorScheme colorScheme) {
  //   return ListTile(
  //     iconColor: colorScheme.primary,
  //     contentPadding: EdgeInsets.zero,
  //     leading: Consumer<ThemeProvider>(
  //       builder: (context, themeProvider, child) {
  //         return Icon(
  //           themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
  //         );
  //       },
  //     ),
  //     title: const Text(
  //       'Dark Mode',
  //       style: TextStyle(
  //         color: Colors.black,
  //         fontSize: 16,
  //         fontFamily: "appFontFamily",
  //         fontWeight: FontWeight.normal,
  //       ),
  //     ),
  //     trailing: Consumer<ThemeProvider>(
  //       builder: (context, themeProvider, child) {
  //         return Switch(
  //           thumbIcon: thumbIcon,
  //           value: themeProvider.isDarkMode,
  //           activeColor: Colors.white,
  //           thumbColor: WidgetStatePropertyAll(colorScheme.primary),
  //           inactiveTrackColor: Colors.grey.shade200,
  //           trackOutlineColor: WidgetStatePropertyAll(colorScheme.primary),
  //           inactiveThumbColor: Colors.white,
  //           overlayColor: WidgetStatePropertyAll(colorScheme.primary),
  //           trackOutlineWidth: const WidgetStatePropertyAll(2),
  //           onChanged: (value) => themeProvider.toggleThemeMode(),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildLanguageSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : colorScheme.primary,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: languageProvider.currentLanguage,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: colorScheme.primary),
          dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          items: languageProvider.languageCodes.map((languageCode) {
            return DropdownMenuItem<String>(
              value: languageCode,
              child: Text(LanguageProvider.supportedLanguages[languageCode]!),
            );
          }).toList(),
          onChanged: (languageCode) {
            if (languageCode != null) {
              languageProvider.setLanguage(languageCode);
            }
          },
        ),
      ),
    );
  }

  Widget _buildVoiceLanguageSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    LanguageProvider languageProvider,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : colorScheme.primary,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: languageProvider.voiceLanguageCode,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: colorScheme.primary),
          dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          hint: Text(languageProvider.tr('settings.voiceLanguage')),
          items: languageProvider.voiceLanguageCodes.map((languageCode) {
            return DropdownMenuItem<String>(
              value: languageCode,
              child: Text(
                languageProvider.tr(
                  'voiceLanguages.${languageCode.substring(0, 2)}',
                ),
              ),
            );
          }).toList(),
          onChanged: (languageCode) {
            if (languageCode != null) {
              languageProvider.setVoiceLanguage(languageCode);
            }
          },
        ),
      ),
    );
  }

  /// Build individual language option button
  // Widget _buildLanguageOption({
  //   required BuildContext context,
  //   required String languageCode,
  //   required String languageLabel,
  //   required bool isSelected,
  //   required ColorScheme colorScheme,
  //   required LanguageProvider languageProvider,
  // }) {
  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   return Expanded(
  //     child: GestureDetector(
  //       onTap: () => languageProvider.setLanguage(languageCode),
  //       child: AnimatedContainer(
  //         duration: const Duration(milliseconds: 300),
  //         curve: Curves.easeInOut,
  //         margin: const EdgeInsets.symmetric(horizontal: 6),
  //         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
  //         decoration: BoxDecoration(
  //           color: isSelected
  //               ? colorScheme.primary
  //               : (isDark ? Colors.grey.shade800 : Colors.white),
  //           borderRadius: BorderRadius.circular(12),
  //           border: Border.all(
  //             color: isSelected
  //                 ? colorScheme.primary
  //                 : (isDark
  //                       ? Colors.grey.shade700
  //                       : colorScheme.primary.withValues(alpha: 0.2)),
  //             width: isSelected ? 2 : 1,
  //           ),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withValues(
  //                 alpha: isSelected ? (isDark ? 0.3 : 0.1) : 0.05,
  //               ),
  //               blurRadius: 8,
  //               spreadRadius: isSelected ? 0 : 0,
  //               offset: const Offset(0, 2),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             AnimatedScale(
  //               scale: isSelected ? 1.15 : 1.0,
  //               duration: const Duration(milliseconds: 200),
  //               child: Icon(
  //                 languageCode == 'en'
  //                     ? Icons.language_outlined
  //                     : Icons.translate_outlined,
  //                 color: isSelected
  //                     ? Colors.white
  //                     : (isDark ? Colors.grey.shade400 : colorScheme.primary),
  //                 size: 18,
  //               ),
  //             ),
  //             const SizedBox(width: 8),
  //             Expanded(
  //               child: Text(
  //                 languageLabel,
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
  //                   color: isSelected
  //                       ? Colors.white
  //                       : (isDark ? Colors.grey.shade300 : colorScheme.primary),

  //                   letterSpacing: 0.2,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Build color grid for theme selection
  Widget _buildColorGrid(BuildContext context, ThemeProvider themeProvider) {
    final colorList = ThemeProvider.availableColors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
        childAspectRatio: 1.1,
      ),
      itemCount: colorList.length,
      itemBuilder: (context, index) {
        return _buildColorOption(context, colorList[index], themeProvider);
      },
    );
  }

  // Build individual color option card
  Widget _buildColorOption(
    BuildContext context,
    Color color,
    ThemeProvider themeProvider,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.seedColor == color;
        // final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () => themeProvider.setSeedColor(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isSelected
                    ? Colors.black87
                    : color.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.check_outlined,
                        color: color,
                        size: 18,
                        weight: 700,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
