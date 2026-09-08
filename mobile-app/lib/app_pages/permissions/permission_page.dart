import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'permission_controller.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  PermissionController? _controller;
  final SecureStorageService _storage = SecureStorageService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    pageTitleLogs("PERMISSION PAGE");
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.blue,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _initializePage();
  }

  Future<void> _initializePage() async {
    final permissionsRequested = await _storage.hasPermissionsBeenRequested();
    if (!mounted) return;

    if (permissionsRequested) {
      Navigator.pushNamedAndRemoveUntil(context, 'login', (route) => false);
      return;
    }

    _controller = PermissionController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller == null) return;
      _controller!.setContext(context);
    });

    setState(() => _isChecking = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking || _controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.watch<LanguageProvider>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: ChangeNotifierProvider.value(
              value: _controller!,
              child: Consumer<PermissionController>(
                builder: (context, controller, child) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8.0),
                        // Header Section with Logo and Title
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  AppImages.appLogoImage,
                                  height: 48.0,
                                  width: 48.0,
                                ),
                              ),
                              const SizedBox(height: 16.0),
                              Text(
                                languageProvider.tr('permissions.title'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0,
                                  fontFamily: "tamilFont",
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                languageProvider.tr('permissions.subtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontFamily: "tamilFont",
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        // Permission List
                        if (controller.isLoadingPermissions)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          _buildPermissionList(context, controller),
                        const SizedBox(height: 16.0),
                        // Allow Access Button
                        controller.isRequesting ||
                                controller.isLoadingPermissions
                            ? const Center(child: CircularProgressIndicator())
                            : AppButton(
                                title: languageProvider.tr('permissions.allow'),
                                onPressed: () =>
                                    controller.requestAllPermissions(),
                              ),
                        const SizedBox(height: 12.0),
                        // Skip Button
                        controller.isRequesting ||
                                controller.isLoadingPermissions
                            ? const SizedBox.shrink()
                            : TextButton(
                                onPressed: () => controller.skipPermissions(),
                                child: Text(
                                  languageProvider.tr('permissions.skip'),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.redAccent,
                                        decoration: TextDecoration.underline,
                                        fontSize: 14.0,
                                        fontFamily: "tamilFont",
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionList(
    BuildContext context,
    PermissionController controller,
  ) {
    // final colorScheme = Theme.of(context).colorScheme;
    final List<Color> permissionColors = [
      AppColors.primaryOption2,
      AppColors.primaryOption3,
      AppColors.primaryOption5,
      AppColors.primaryOption6,
      AppColors.primaryOption8,
      AppColors.primaryOption7,
      AppColors.primaryOption9,
    ];
    return Column(
      children: controller.permissions.asMap().entries.map((entry) {
        final index = entry.key;
        final permission = entry.value;
        final isGranted = controller.grantedPermissions.contains(permission.id);
        final itemColor = permissionColors[index % permissionColors.length];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isGranted ? itemColor.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(
              color: isGranted ? itemColor : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: itemColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(permission.icon, color: Colors.white, size: 18.0),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      permission.description,
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (isGranted)
                Icon(Icons.check_circle_outlined, color: itemColor, size: 20.0),
            ],
          ),
        );
      }).toList(),
    );
  }
}
