import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:moi/app_pages/home_page/widgets/build_side_drawer.dart';
import 'package:moi/app_services/moi_services.dart';
import 'package:moi/app_services/notification_services.dart';
import 'package:moi/app_services/transaction_services.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Service instances - made final for better performance
  final SecureStorageService _secureStorage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final MoiServices _moiServices = MoiServices();
  final NotificationServices _notificationServices = NotificationServices();
  final TransactionServices _transactionServices = TransactionServices();

  // State variables
  int totalAmount = 0;
  int totalMOAmount = 0;
  List<Map<String, dynamic>> _functionSummaries = [];
  bool _isLoadingFunctionSummaries = false;

  bool _isInitialized = false;
  bool _needsRefresh = false;
  DateTime? _lastFetchTime;
  int _unreadNotificationCount = 0;

  late final Upgrader _upgrader;
  // Ensure upgrade check runs only once per app launch (session)
  static bool _upgradeCheckedThisLaunch = false;
  late final bool _shouldRunUpgradeCheck;

  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Cached NumberFormat instance for better performance
  static final NumberFormat _numberFormatter = NumberFormat('#,##,000.00');

  @override
  void initState() {
    super.initState();

    // Only allow Upgrader to run on the very first HomePage creation
    _shouldRunUpgradeCheck = !_upgradeCheckedThisLaunch;
    _upgradeCheckedThisLaunch = true;

    _upgrader = Upgrader(
      debugLogging: kDebugMode,
      durationUntilAlertAgain: const Duration(days: 3),
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
      ),
    );

    // Use post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initHomePage();
    });
  }

  Future<void> initHomePage() async {
    // Load user info and update provider
    try {
      final userInfo = await _secureStorage.get(AppVariables.userInformation);
      if (userInfo != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.updateUserDetails(userInfo);
      }
    } catch (e) {
      debugPrint('Error loading user information: $e');
      // Continue even if user info loading fails
    }

    try {
      final List<Future<void>> initialTasks = [];

      // Only fetch totals if data is not cached or cache is expired
      if (!_isDataCached() || _isCacheExpired()) {
        initialTasks.add(getTotalAmount(showLoading: false));
      }

      // Keep unread badge current without blocking entire page for long
      initialTasks.add(checkNotificationStatus());
      initialTasks.add(_loadFunctionSummaries());

      await Future.wait(initialTasks);

      // Non-critical notification setup runs in background
      unawaited(_initializeNotificationPipeline());

      if (mounted) {
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // Show error to user if critical operations fail
      if (mounted) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('home.startupError'),
        );
      }
    }
  }

  Future<void> _initializeNotificationPipeline() async {
    try {
      await PushNotificationService.instance.syncTokenForCurrentUser();
    } catch (e) {
      debugPrint('Background notification setup error: $e');
    }
  }

  // Check if data is cached (has been fetched at least once)
  bool _isDataCached() {
    return _lastFetchTime != null;
  }

  // Check if cache is expired
  bool _isCacheExpired() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  // Helper method to refresh data after navigation
  Future<void> _refreshAfterNavigation() async {
    if (mounted) {
      _needsRefresh = true;
      await Future.wait([getTotalAmount(), _loadFunctionSummaries()]);
    }
  }

  /// REQUEST NECESSARY PERMISSIONS
  Future<void> getPermission() async {
    try {
      await [
        Permission.microphone,
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.notification,
      ].request();
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      rethrow;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible if needed
    if (_isInitialized && _needsRefresh) {
      _needsRefresh = false;
      getTotalAmount().catchError((e) {
        debugPrint('Error refreshing data in didChangeDependencies: $e');
      });
    }
  }

  @override
  void dispose() {
    _upgrader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          backButtonExit();
        }
      },
      child: _buildModernUpgradeAlert(),
    );
  }

  Widget _buildModernUpgradeAlert() {
    final colorScheme = Theme.of(context).colorScheme;

    // If we've already run the upgrade check this app launch, don't wrap the
    // page with UpgradeAlert again (prevents repeated checks/dialogs).
    if (!_shouldRunUpgradeCheck) {
      return bodyContentWidget();
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            fontFamily: "englishFont",
          ),
          contentTextStyle: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontFamily: "englishFont",
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: "englishFont",
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            elevation: 5,
          ),
        ),
      ),
      child: UpgradeAlert(
        upgrader: _upgrader,
        shouldPopScope: () => false,
        showIgnore: false,
        showLater: false,
        showReleaseNotes: true,
        dialogStyle: UpgradeDialogStyle.material,
        child: bodyContentWidget(),
      ),
    );
  }

  Widget bodyContentWidget() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final netBalance = totalAmount - totalMOAmount;

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFF4F7FB),
      appBar: AppBarWidget(
        title: context.watch<LanguageProvider>().tr('home.title'),
        action: [_buildNotificationAction()],
      ),
      drawer: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return BuildSideDrawer(
            userDetails: userProvider.userDetails,
            context: context,
          );
        },
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          await Future.wait([
            getTotalAmount(showLoading: false),
            _loadFunctionSummaries(),
            checkNotificationStatus(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeHeader(),
                  const SizedBox(height: 16),
                  _buildNetBalanceCard(netBalance),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAmountCard(
                          context: context,
                          title: languageProvider.tr('moi.moiIn'),
                          amount: totalAmount,
                          icon: Icons.south_west_rounded,
                          color: const Color(0xFF1B9E4B),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              'all-transactions',
                              arguments: {'type': 'INVEST'},
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAmountCard(
                          context: context,
                          title: languageProvider.tr('moi.moiOut'),
                          amount: totalMOAmount,
                          icon: Icons.north_east_rounded,
                          color: const Color(0xFFE23D4D),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              'all-transactions',
                              arguments: {'type': 'RETURN'},
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildQuickActions(languageProvider),
                  const SizedBox(height: 22),
                  _buildFunctionSummaries(context, languageProvider),
                  const SizedBox(height: 16),
                  _buildTransactionNote(context, languageProvider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationAction() {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (_unreadNotificationCount > 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  _unreadNotificationCount > 99
                      ? '99+'
                      : '$_unreadNotificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        await Navigator.pushNamed(context, "notifications");
        if (mounted) {
          await checkNotificationStatus();
        }
      },
      tooltip: context.read<LanguageProvider>().tr('home.notifications'),
    );
  }

  Widget _buildWelcomeHeader() {
    return Consumer2<UserProvider, LanguageProvider>(
      builder: (context, userProvider, languageProvider, _) {
        final theme = Theme.of(context);
        final currentUserDetails = userProvider.userDetails;
        final userName = currentUserDetails.isNotEmpty
            ? currentUserDetails[0]['name']?.toString() ?? 'User'
            : 'User';
        final lastLogin = currentUserDetails.isNotEmpty
            ? currentUserDetails[0]['last_login']?.toString() ?? ""
            : "";
        final profileImagePath = currentUserDetails.isNotEmpty
            ? (currentUserDetails[0]['profile_image_url'] ??
                          currentUserDetails[0]['profile_image'])
                      ?.toString()
                      .trim() ??
                  ''
            : '';
        final profileImageUrl = profileImagePath.isEmpty
            ? ''
            : profileImagePath.startsWith('http://') ||
                  profileImagePath.startsWith('https://')
            ? profileImagePath
            : '$appImageUrl/${profileImagePath.replaceFirst(RegExp(r'^/+'), '')}';
        final displayName = _displayName(userName);

        return Row(
          children: [
            _buildProfileAvatar(
              name: displayName,
              imageUrl: profileImageUrl,
              colorScheme: theme.colorScheme,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.tr(_greetingKey()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      height: 1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${languageProvider.tr('home.lastLogin')}: ${getLastLoginTime(lastLogin)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileAvatar({
    required String name,
    required String imageUrl,
    required ColorScheme colorScheme,
  }) {
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    final fallback = Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? fallback
            : Image.network(
                imageUrl,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }

  Widget _buildNetBalanceCard(int netBalance) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();
    final isPositive = netBalance >= 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            "transaction-dashboard",
          );
          if (result == true) {
            await _refreshAfterNavigation();
          }
        },
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                Color.lerp(colorScheme.primary, const Color(0xFF042A63), 0.42)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  top: -36,
                  right: -24,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -48,
                  left: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              languageProvider.tr('home.netBalance'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              languageProvider.tr(
                                isPositive
                                    ? 'home.positiveBalance'
                                    : 'home.negativeBalance',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '₹ ${numberFormat(netBalance.abs())}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontFamily: 'Arimo',
                              fontWeight: FontWeight.w800,
                              fontSize: 32,
                              letterSpacing: -0.6,
                              height: 1,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                languageProvider.tr('home.viewTransactions'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.92,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
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
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard({
    required BuildContext context,
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹ ${numberFormat(amount)}',
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontFamily: "Arimo",
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(LanguageProvider languageProvider) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageProvider.tr('home.quickActions'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildQuickActionTile(
              icon: Icons.celebration_outlined,
              label: languageProvider.tr('home.myFunctions'),
              color: theme.colorScheme.primary,
              onTap: () {
                Navigator.pushNamed(context, 'functions-list');
              },
            ),
            _buildQuickActionTile(
              icon: Icons.add_rounded,
              label: languageProvider.tr('home.addFunction'),
              color: const Color(0xFF1B9E4B),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  'add-edit-functions',
                  arguments: [],
                );
                if (mounted) {
                  await _refreshAfterNavigation();
                }
              },
            ),
            _buildQuickActionTile(
              icon: Icons.bar_chart_rounded,
              label: languageProvider.tr('menu.moiDashboard'),
              color: const Color(0xFFE5672F),
              onTap: () async {
                final result = await Navigator.pushNamed(
                  context,
                  'transaction-dashboard',
                );
                if (result == true) {
                  await _refreshAfterNavigation();
                }
              },
            ),
            _buildQuickActionTile(
              icon: Icons.event_available_outlined,
              label: languageProvider.tr('home.upcomingFunctions'),
              color: const Color(0xFF5C2292),
              onTap: () {
                Navigator.pushNamed(context, 'upcoming-function-list');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionSummaries(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const visibleCount = 6;
    final visibleSummaries = _functionSummaries.take(visibleCount).toList();
    final hasMore = _functionSummaries.length > visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.tr('home.functionTotals'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    languageProvider.tr('home.mostActiveFunctions'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (hasMore)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'functions-list');
                },
                child: Text(languageProvider.tr('home.viewAll')),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingFunctionSummaries && _functionSummaries.isEmpty)
          ...List.generate(3, (index) => _buildFunctionSummarySkeleton())
        else if (_functionSummaries.isEmpty)
          _buildEmptyFunctionsState(languageProvider)
        else
          ...visibleSummaries.asMap().entries.map(
            (entry) =>
                _buildFunctionSummaryCard(context, entry.value, entry.key),
          ),
      ],
    );
  }

  Widget _buildEmptyFunctionsState(LanguageProvider languageProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_outlined,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            languageProvider.tr('home.noFunctionTotals'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionSummarySkeleton() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildFunctionSummaryCard(
    BuildContext context,
    Map<String, dynamic> summary,
    int index,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final invest = summary['invest'] as double? ?? 0;
    final name = summary['name']?.toString() ?? '-';
    final accent = _functionAccent(index);
    final letter = name.isNotEmpty ? name.characters.first.toUpperCase() : 'F';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            'view-functions-list',
            arguments: [summary['function']],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              summary['date']?.toString() ?? '-',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹ ${_numberFormatter.format(invest)}',
                      style: TextStyle(
                        color: invest >= 0
                            ? const Color(0xFF1B9E4B)
                            : const Color(0xFFE23D4D),
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadFunctionSummaries() async {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userDetails = userProvider.userDetails;
    if (userDetails.isEmpty) return;

    final userId = userDetails[0]['id']?.toString();
    if (userId == null || userId.isEmpty) return;

    setState(() => _isLoadingFunctionSummaries = true);
    try {
      final response = await _transactionServices.listTransactionFunctions({
        'userId': userId,
      }, showLoading: false);
      final rawFunctions = response is Map && response['responseType'] == 'S'
          ? response['responseValue']
          : null;
      if (rawFunctions is! List) return;

      final summaries = await Future.wait(
        rawFunctions.whereType<Map>().map((function) async {
          double invest = 0;
          final functionId = function['id']?.toString();
          if (functionId != null && functionId.isNotEmpty) {
            final transactionResponse = await _transactionServices
                .listTransactions({
                  'userId': userId,
                  'transactionFunctionId': functionId,
                }, showLoading: false);
            final transactions =
                transactionResponse is Map &&
                    transactionResponse['responseType'] == 'S'
                ? transactionResponse['responseValue']
                : null;
            if (transactions is List) {
              for (final transaction in transactions.whereType<Map>()) {
                final amount =
                    double.tryParse(transaction['amount']?.toString() ?? '0') ??
                    0;
                if (transaction['type']?.toString().toUpperCase() == 'INVEST') {
                  invest += amount;
                }
              }
            }
          }
          return {
            'function': Map<String, dynamic>.from(function),
            'name': function['functionName']?.toString() ?? '-',
            'date': formatFunctionDate(function['functionDate']?.toString()),
            'invest': invest,
          };
        }),
      );

      if (mounted) {
        summaries.sort((a, b) {
          final aAmt = (a['invest'] as num?)?.toDouble() ?? 0;
          final bAmt = (b['invest'] as num?)?.toDouble() ?? 0;
          return bAmt.compareTo(aAmt);
        });
        setState(() => _functionSummaries = summaries);
      }
    } finally {
      if (mounted) setState(() => _isLoadingFunctionSummaries = false);
    }
  }

  Widget _buildTransactionNote(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface
            : colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              languageProvider.tr('home.transactionNote'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.goodMorning';
    if (hour < 17) return 'home.goodAfternoon';
    return 'home.goodEvening';
  }

  String _displayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'User';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((part) => part.toCapitalized())
        .join(' ');
  }

  Color _functionAccent(int index) {
    const palette = [
      Color(0xFF075BCB),
      Color(0xFF009C3B),
      Color(0xFFE5672F),
      Color(0xFF5C2292),
      Color(0xFF13D0C1),
      Color(0xFFD23156),
    ];
    return palette[index % palette.length];
  }

  /// HANDLE BACK BUTTON EXIT
  Future<void> backButtonExit() async {
    try {
      final message = context.read<LanguageProvider>().tr(
        'common.exitConfirmation',
      );
      final confirm = await _alertServices.confirmExitSheet(context, message);
      if (confirm == true) {
        FlutterExitApp.exitApp();
      }
    } catch (e) {
      debugPrint('Error in backButtonExit: $e');
      // If there's an error, just exit the app
      FlutterExitApp.exitApp();
    }
  }

  /// FETCH TOTAL AMOUNTS FROM THE SERVER
  Future<void> getTotalAmount({bool showLoading = true}) async {
    // Get user details from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserDetails = userProvider.userDetails;

    if (currentUserDetails.isEmpty) return;

    try {
      final params = {"userId": currentUserDetails[0]['id'].toString()};
      final response = await _moiServices.getTotalAmount(
        params,
        showLoading: showLoading,
      );
      if (response != null && response['responseType'] == "S" && mounted) {
        final responseValue = response['responseValue'];
        if (responseValue.isNotEmpty) {
          setState(() {
            totalAmount = responseValue['amounts']['invest'] ?? 0;
            totalMOAmount = responseValue['amounts']['return'] ?? 0;
            _lastFetchTime = DateTime.now();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching total amount: $e');
      if (mounted && showLoading) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('home.fetchDataError'),
        );
      }
    }
  }

  /// FORMAT NUMBERS FOR DISPLAY
  String numberFormat(int amt) {
    if (amt != 0) {
      return _numberFormatter.format(amt.toDouble());
    }
    return "0";
  }

  /// GET LAST LOGIN TIME
  String getLastLoginTime(String time) {
    if (time.isEmpty) {
      return context.read<LanguageProvider>().tr('home.notAvailable');
    }
    try {
      DateTime dateTime = DateTime.parse(time).toLocal();
      return DateFormat("dd MMM yyyy · hh:mm a").format(dateTime);
    } catch (e) {
      debugPrint('Error parsing last login time: $e');
      return context.read<LanguageProvider>().tr('home.invalidDate');
    }
  }

  // --- END OF notification badge helpers ---

  // Check unread notification badge via lightweight count endpoint
  Future<void> checkNotificationStatus() async {
    if (!mounted) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userDetails.isEmpty) return;

      final response = await _notificationServices.getUnreadCount();

      if (!mounted) return;

      int unreadCount = 0;
      if (response != null && response['responseType'] == 'S') {
        final value = response['responseValue'];
        if (value is Map) {
          final countValue = value['count'] ?? value['unreadCount'];
          unreadCount = int.tryParse(countValue?.toString() ?? '0') ?? 0;
        } else if (value is num) {
          unreadCount = value.toInt();
        }
      }

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount.clamp(0, 9999);
        });
      }
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      // On error, don't show badge
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }
}
