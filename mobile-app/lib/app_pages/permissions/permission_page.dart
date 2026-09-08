import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.watch<LanguageProvider>();

    if (_isChecking || _controller == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: ChangeNotifierProvider.value(
              value: _controller!,
              child: Consumer<PermissionController>(
                builder: (context, controller, child) {
                  final totalCount = controller.permissions.length;
                  final grantedCount = controller.grantedPermissions.length;
                  final allGranted = totalCount > 0 && grantedCount == totalCount;

                  return Column(
                    children: [
                      // Header & Permission Cards Section
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Hero Header Card
                              _buildHeaderCard(
                                context,
                                languageProvider,
                                grantedCount,
                                totalCount,
                                allGranted,
                              ),

                              const SizedBox(height: 24.0),

                              // Section Header Label
                              Row(
                                children: [
                                  Text(
                                    "App Permissions",
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurfaceVariant,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  const Spacer(),
                                  if (controller.isLoadingPermissions)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12.0),

                              // Permission List Cards
                              if (controller.isLoadingPermissions)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              else
                                _buildPermissionList(context, controller),
                            ],
                          ),
                        ),
                      ),

                      // Sticky Bottom Action Bar
                      _buildBottomActionBar(
                        context,
                        languageProvider,
                        controller,
                        allGranted,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build modern Header Card with logo and progress counter
  Widget _buildHeaderCard(
    BuildContext context,
    LanguageProvider languageProvider,
    int grantedCount,
    int totalCount,
    bool allGranted,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle decoration shapes
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),

          // Main Header Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              children: [
                // App Logo Badge
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppImages.appLogoImage,
                    height: 48.0,
                    width: 48.0,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Title
                Text(
                  languageProvider.tr('permissions.title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    fontFamily: "tamilFont",
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8.0),

                // Subtitle Description
                Text(
                  languageProvider.tr('permissions.subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontFamily: "tamilFont",
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Progress Badge Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    color: allGranted
                        ? const Color(0xFF10B981).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allGranted ? Icons.check_circle : Icons.shield_outlined,
                        color: Colors.white,
                        size: 16.0,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        allGranted
                            ? "All Permissions Granted"
                            : "$grantedCount of $totalCount Allowed",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          fontFamily: "tamilFont",
                        ),
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

  /// Permission list with modern card items
  Widget _buildPermissionList(
    BuildContext context,
    PermissionController controller,
  ) {
    final List<Color> accentColors = [
      const Color(0xFF2563EB), // Blue for Notifications
      const Color(0xFF7C3AED), // Purple for Camera
      const Color(0xFFE11D48), // Rose for Microphone
      const Color(0xFF059669), // Emerald for Photos/Storage
    ];

    return Column(
      children: controller.permissions.asMap().entries.map((entry) {
        final index = entry.key;
        final permission = entry.value;
        final isGranted = controller.grantedPermissions.contains(permission.id);
        final isPermanentlyDenied =
            controller.permanentlyDeniedPermissions.contains(permission.id);
        final accentColor = accentColors[index % accentColors.length];

        return _buildPermissionCard(
          context: context,
          permission: permission,
          isGranted: isGranted,
          isPermanentlyDenied: isPermanentlyDenied,
          accentColor: accentColor,
          onTap: () => controller.requestSinglePermission(permission),
        );
      }).toList(),
    );
  }

  /// Individual permission card UI
  Widget _buildPermissionCard({
    required BuildContext context,
    required PermissionInfo permission,
    required bool isGranted,
    required bool isPermanentlyDenied,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isGranted
        ? (isDark
            ? const Color(0xFF065F46).withValues(alpha: 0.15)
            : const Color(0xFFECFDF5))
        : (isDark ? colorScheme.surfaceContainer : Colors.white);

    final borderColor = isGranted
        ? const Color(0xFF10B981).withValues(alpha: 0.5)
        : (isDark
            ? colorScheme.outline.withValues(alpha: 0.2)
            : colorScheme.outlineVariant.withValues(alpha: 0.5));

    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: borderColor, width: isGranted ? 1.5 : 1.0),
          boxShadow: [
            if (!isGranted && !isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8.0,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon Badge Container
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: isGranted
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                isGranted ? Icons.check_circle_rounded : permission.icon,
                color: isGranted ? const Color(0xFF10B981) : accentColor,
                size: 22.0,
              ),
            ),
            const SizedBox(width: 14.0),

            // Middle Name & Description Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          permission.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                            fontFamily: "tamilFont",
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    permission.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontFamily: "tamilFont",
                      color: colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),

            // Right Status Badge or Action Chip
            _buildStatusChip(
              context: context,
              isGranted: isGranted,
              isPermanentlyDenied: isPermanentlyDenied,
              accentColor: accentColor,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }

  /// Status badge (Allowed / Settings / Enable)
  Widget _buildStatusChip({
    required BuildContext context,
    required bool isGranted,
    required bool isPermanentlyDenied,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    if (isGranted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFF10B981),
              size: 14.0,
            ),
            SizedBox(width: 4.0),
            Text(
              "Allowed",
              style: TextStyle(
                color: Color(0xFF047857),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isPermanentlyDenied) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: const Color(0xFFF59E0B), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.settings_outlined,
                color: Color(0xFFD97706),
                size: 14.0,
              ),
              SizedBox(width: 4.0),
              Text(
                "Settings",
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default Allow button for ungranted item
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: accentColor, width: 1),
        ),
        child: Text(
          "Allow",
          style: TextStyle(
            color: accentColor,
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Sticky Bottom Action Bar
  Widget _buildBottomActionBar(
    BuildContext context,
    LanguageProvider languageProvider,
    PermissionController controller,
    bool allGranted,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 16.0),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action Button
          controller.isRequesting || controller.isLoadingPermissions
              ? const SizedBox(
                  height: 48.0,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 52.0,
                  child: ElevatedButton(
                    onPressed: () => controller.requestAllPermissions(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allGranted
                          ? const Color(0xFF10B981)
                          : colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          allGranted
                              ? "Continue"
                              : languageProvider.tr('permissions.allow'),
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: "tamilFont",
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Icon(
                          allGranted
                              ? Icons.arrow_forward_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: 8.0),

          // Skip Button
          if (!controller.isRequesting && !controller.isLoadingPermissions)
            TextButton(
              onPressed: () => controller.skipPermissions(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              child: Text(
                languageProvider.tr('permissions.skip'),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14.0,
                  fontFamily: "tamilFont",
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
