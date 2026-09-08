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
    int netBalance = totalAmount - totalMOAmount;
    return Scaffold(
      appBar: AppBarWidget(
        title: '',
        action: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
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
              // Refresh notification status when returning from notifications page
              if (mounted) {
                await checkNotificationStatus();
              }
            },
            tooltip: context.read<LanguageProvider>().tr('home.notifications'),
          ),
        ],
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
        onRefresh: () async {
          await Future.wait([
            getTotalAmount(showLoading: false),
            _loadFunctionSummaries(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildWelcomeHeader(),
                  const SizedBox(height: 16),
                  _buildTransactionNote(context, languageProvider),
                  const SizedBox(height: 16),

                  // Net Balance Summary Card
                  _buildNetBalanceCard(netBalance),
                  const SizedBox(height: 16),

                  // Main Amount Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              'all-transactions',
                              arguments: {'type': 'INVEST'},
                            );
                          },
                          child: _buildAmountCard(
                            context: context,
                            title: languageProvider.tr('moi.moiIn'),
                            amount: totalAmount,
                            icon: Icons.arrow_downward_outlined,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              'all-transactions',
                              arguments: {'type': 'RETURN'},
                            );
                          },
                          child: _buildAmountCard(
                            context: context,
                            title: languageProvider.tr('moi.moiOut'),
                            amount: totalMOAmount,
                            icon: Icons.arrow_upward_outlined,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  const Divider(thickness: 1, height: 2),
                  const SizedBox(height: 16.0),

                  // Function totals section
                  _buildFunctionSummaries(context, languageProvider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Welcome Header Widget
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

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              ClipOval(
                child: profileImageUrl.isEmpty
                    ? Container(
                        width: 48,
                        height: 48,
                        color: theme.colorScheme.primary,
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 23,
                        ),
                      )
                    : Image.network(
                        profileImageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            color: theme.colorScheme.primary,
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white,
                              size: 23,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${languageProvider.tr('home.welcome')}, ${userName.toUpperCase()}.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${languageProvider.tr('home.lastLogin')}: ${getLastLoginTime(lastLogin)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Net Balance Card Widget
  Widget _buildNetBalanceCard(int netBalance) {
    final colorScheme = Theme.of(context).colorScheme;
    final languageProvider = context.read<LanguageProvider>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              "transaction-dashboard",
            );
            if (result == true) {
              await _refreshAfterNavigation();
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        languageProvider.tr('home.netBalance'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹ ${numberFormat(netBalance.abs())}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontFamily: 'Arimo',
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        languageProvider.tr('home.viewTransactions'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 19,
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

  // Amount Card Widget
  Widget _buildAmountCard({
    required BuildContext context,
    required String title,
    required int amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '₹ ${numberFormat(amount)}',
                style: TextStyle(
                  fontSize: 17,
                  color: color,
                  fontFamily: "Arimo",
                  fontWeight: FontWeight.w700,
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

  Widget _buildFunctionSummaries(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                languageProvider.tr('home.functionTotals'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Most active functions',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        if (_isLoadingFunctionSummaries && _functionSummaries.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_functionSummaries.isEmpty)
          Text(
            languageProvider.tr('home.noFunctionTotals'),
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ..._functionSummaries.asMap().entries.map(
            (entry) => _buildFunctionSummaryCard(context, entry.value),
          ),
      ],
    );
  }

  Widget _buildFunctionSummaryCard(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final invest = summary['invest'] as double? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            'view-functions-list',
            arguments: [summary['function']],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 13, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.56),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary['name']?.toString() ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        summary['date']?.toString() ?? '-',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹ ${_numberFormatter.format(invest)}',
                      style: TextStyle(
                        // color: colorScheme.primary,
                        color: invest >= 0 ? Colors.green : Colors.red,
                        fontFamily: 'Arimo',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    // const SizedBox(height: 7),
                    // Icon(
                    //   Icons.arrow_forward_rounded,
                    //   size: 17,
                    //   color: colorScheme.onSurfaceVariant,
                    // ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 21,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              languageProvider.tr('home.transactionNote'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
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
      return DateFormat("dd-MMM-yyyy hh:mm:ss a").format(dateTime);
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
