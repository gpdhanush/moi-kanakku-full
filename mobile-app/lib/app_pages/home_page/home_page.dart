import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:moi/app_pages/home_page/widgets/home_app_header.dart';
import 'package:moi/app_pages/home_page/widgets/home_function_totals_section.dart';
import 'package:moi/app_pages/home_page/widgets/home_greeting_header.dart';
import 'package:moi/app_pages/home_page/widgets/home_moi_overview_card.dart';
import 'package:moi/app_pages/home_page/widgets/home_section_reveal.dart';
import 'package:moi/app_pages/home_page/widgets/modern_upgrade_alert.dart';
import 'package:moi/app_pages/app_alerts/app_alert_dialog.dart';
import 'package:moi/app_utils/app_widgets/email_verify_card.dart';
import 'package:moi/app_services/moi_services.dart';
import 'package:moi/app_services/notification_services.dart';
import 'package:moi/app_services/transaction_services.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_themes/index.dart';
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
  /// When true, system back is handled by [MainShellPage].
  final bool isShellTab;

  /// Bumped by [MainShellPage] when the Home tab becomes active again.
  final ValueNotifier<int>? refreshSignal;

  const HomePage({
    super.key,
    this.isShellTab = false,
    this.refreshSignal,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SecureStorageService _secureStorage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final MoiServices _moiServices = MoiServices();
  final NotificationServices _notificationServices = NotificationServices();
  final TransactionServices _transactionServices = TransactionServices();
  final UserServices _userServices = UserServices();

  int totalAmount = 0;
  int totalMOAmount = 0;
  List<Map<String, dynamic>> _functionSummaries = [];
  bool _isLoadingFunctionSummaries = false;

  bool _isInitialized = false;
  bool _needsRefresh = false;
  DateTime? _lastFetchTime;
  int _unreadNotificationCount = 0;

  late final Upgrader _upgrader;
  static bool _upgradeCheckedThisLaunch = false;
  static bool _appAlertCheckedThisLaunch = false;
  late final bool _shouldRunUpgradeCheck;

  static const Duration _cacheDuration = Duration(minutes: 5);
  static final NumberFormat _numberFormatter = NumberFormat('#,##,000.00');

  @override
  void initState() {
    super.initState();

    _shouldRunUpgradeCheck = !_upgradeCheckedThisLaunch;
    _upgradeCheckedThisLaunch = true;

    _upgrader = Upgrader(
      debugLogging: kDebugMode,
      durationUntilAlertAgain: const Duration(days: 3),
      storeController: UpgraderStoreController(
        onAndroid: () => UpgraderPlayStore(),
      ),
    );

    widget.refreshSignal?.addListener(_onShellRefreshSignal);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initHomePage();
    });
  }

  void _onShellRefreshSignal() {
    if (!mounted || !_isInitialized) return;
    unawaited(_refreshHomeData(showLoading: false));
  }

  Future<void> _refreshHomeData({bool showLoading = false}) async {
    if (!mounted) return;
    await Future.wait([
      getTotalAmount(showLoading: showLoading),
      _loadFunctionSummaries(),
      checkNotificationStatus(),
    ]);
  }

  Future<void> initHomePage() async {
    try {
      final userInfo = await _secureStorage.get(AppVariables.userInformation);
      if (userInfo != null && mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.updateUserDetails(userInfo);
      }
    } catch (e) {
      debugPrint('Error loading user information: $e');
    }

    try {
      final List<Future<void>> initialTasks = [];

      if (!_isDataCached() || _isCacheExpired()) {
        initialTasks.add(getTotalAmount(showLoading: false));
      }

      initialTasks.add(checkNotificationStatus());
      initialTasks.add(_loadFunctionSummaries());
      initialTasks.add(_syncProfileImageFromServer());

      await Future.wait(initialTasks);
      unawaited(_initializeNotificationPipeline());
      unawaited(_maybeShowAppAlert());

      if (mounted) {
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (mounted) {
        _alertServices.errorToast(
          context.read<LanguageProvider>().tr('home.startupError'),
        );
      }
    }
  }

  /// Keep local profile photo in sync so deleted server files don't 404 forever.
  Future<void> _syncProfileImageFromServer() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userDetails.isEmpty) return;
      final user = Map<String, dynamic>.from(userProvider.userDetails[0] as Map);
      final userId = user['id']?.toString();
      if (userId == null || userId.isEmpty) return;

      final response = await _userServices.getUserImportantDetails(userId);
      if (response == null || response['responseType'] != 'S') return;

      final responseValue = response['responseValue'];
      if (responseValue is Map) {
        if (responseValue['is_verified'] != null) {
          user['is_verified'] = responseValue['is_verified'];
        }
        if (responseValue.containsKey('email_verified_at')) {
          user['email_verified_at'] = responseValue['email_verified_at'];
        }
        if (responseValue['email'] != null) {
          user['email'] = responseValue['email'];
        }
        if (responseValue['name'] != null) {
          user['name'] = responseValue['name'];
        }
      }

      final profile = responseValue is Map ? responseValue['profile'] : null;
      final serverPath = profile is Map
          ? profile['profile_image_url']?.toString().trim()
          : null;

      if (serverPath == null ||
          serverPath.isEmpty ||
          userProvider.isRejectedProfileImage(serverPath)) {
        await userProvider.clearProfileImage(
          fromMissingFile: userProvider.isRejectedProfileImage(serverPath),
          missingUrl: serverPath,
        );
        // Still persist verification flags even when photo is cleared.
        if (responseValue is Map) {
          final refreshed = userProvider.userDetails.isNotEmpty
              ? Map<String, dynamic>.from(userProvider.userDetails[0] as Map)
              : user;
          refreshed['is_verified'] = user['is_verified'];
          refreshed['email_verified_at'] = user['email_verified_at'];
          userProvider.updateUserDetails(refreshed);
          await _secureStorage.save(AppVariables.userInformation, refreshed);
        }
        return;
      }

      user['profile_image'] = serverPath;
      user['profile_image_url'] = serverPath;
      userProvider.updateUserDetails(user);
      await _secureStorage.save(AppVariables.userInformation, user);
    } catch (e) {
      debugPrint('Error syncing profile image: $e');
    }
  }

  Future<void> _initializeNotificationPipeline() async {
    try {
      await PushNotificationService.instance.syncTokenForCurrentUser();
    } catch (e) {
      debugPrint('Background notification setup error: $e');
    }
  }

  /// Show admin in-app popup once after splash/home (per app launch).
  Future<void> _maybeShowAppAlert() async {
    if (_appAlertCheckedThisLaunch) return;
    _appAlertCheckedThisLaunch = true;
    if (!mounted) return;
    // Let home paint first, then present the alert.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await AppAlertDialog.showIfNeeded(context);
  }

  bool _isDataCached() => _lastFetchTime != null;

  bool _isCacheExpired() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  Future<void> _refreshAfterNavigation() async {
    if (!mounted) return;
    _needsRefresh = true;
    await _refreshHomeData(showLoading: true);
  }

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
    if (_isInitialized && _needsRefresh) {
      _needsRefresh = false;
      unawaited(
        _refreshHomeData(showLoading: false).catchError((e) {
          debugPrint('Error refreshing data in didChangeDependencies: $e');
        }),
      );
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onShellRefreshSignal);
    _upgrader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildModernUpgradeAlert();
    if (widget.isShellTab) return content;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          backButtonExit();
        }
      },
      child: content,
    );
  }

  Widget _buildModernUpgradeAlert() {
    if (!_shouldRunUpgradeCheck) {
      return bodyContentWidget();
    }

    return ModernUpgradeAlert(
      upgrader: _upgrader,
      shouldPopScope: () => false,
      showIgnore: false,
      showLater: false,
      showReleaseNotes: true,
      child: bodyContentWidget(),
    );
  }

  Widget bodyContentWidget() {
    final netBalance = totalAmount - totalMOAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HomeAppHeader(
        unreadNotificationCount: _unreadNotificationCount,
        notificationsTooltip:
            context.read<LanguageProvider>().tr('home.notifications'),
        onNotificationsTap: () async {
          await Navigator.pushNamed(context, "notifications");
          if (mounted) {
            await checkNotificationStatus();
          }
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPad = constraints.maxWidth >= 480
              ? AppSpacing.xl
              : AppSpacing.page;

          return MoiRefreshIndicator(
            onRefresh: () => _refreshHomeData(showLoading: false),
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 180,
                      left: -50,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.moiReceived.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 120,
                      right: -40,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentViolet.withValues(alpha: 0.07),
                        ),
                      ),
                    ),
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPad,
                        AppSpacing.md,
                        horizontalPad,
                        MediaQuery.paddingOf(context).bottom + AppSpacing.md,
                      ),
                      children: [
                        HomeSectionReveal(
                          index: 0,
                          child: HomeGreetingHeader(
                            formatLastLogin: getLastLoginTime,
                            onProfileTap: () {
                              Navigator.pushNamed(context, 'profile');
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final user = userProvider.userDetails.isNotEmpty
                                ? Map<String, dynamic>.from(
                                    userProvider.userDetails[0] as Map,
                                  )
                                : null;
                            if (isUserEmailVerified(user)) {
                              return const SizedBox.shrink();
                            }
                            return const Column(
                              children: [
                                HomeSectionReveal(
                                  index: 1,
                                  child: EmailVerifyCard(),
                                ),
                                SizedBox(height: AppSpacing.section),
                              ],
                            );
                          },
                        ),
                        HomeSectionReveal(
                          index: 2,
                          child: HomeMoiOverviewCard(
                            netBalance: netBalance,
                            receivedAmount: totalAmount,
                            givenAmount: totalMOAmount,
                            formatAmount: numberFormat,
                            onViewTransactions: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                "transaction-dashboard",
                              );
                              if (result == true) {
                                await _refreshAfterNavigation();
                              }
                            },
                            onReceivedTap: () {
                              Navigator.pushNamed(
                                context,
                                'all-transactions',
                                arguments: {'type': 'INVEST'},
                              );
                            },
                            onGivenTap: () {
                              Navigator.pushNamed(
                                context,
                                'all-transactions',
                                arguments: {'type': 'RETURN'},
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        HomeSectionReveal(
                          index: 3,
                          child: HomeFunctionTotalsSection(
                            summaries: _functionSummaries,
                            isLoading: _isLoadingFunctionSummaries,
                            formatAmount: (amount) =>
                                _numberFormatter.format(amount),
                            onViewAll: () async {
                              await Navigator.pushNamed(
                                context,
                                'functions-list',
                              );
                              if (mounted) {
                                await _refreshHomeData(showLoading: false);
                              }
                            },
                            onItemTap: (summary) async {
                              await Navigator.pushNamed(
                                context,
                                'view-functions-list',
                                arguments: [summary['function']],
                              );
                              if (mounted) {
                                await _refreshHomeData(showLoading: false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
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
      // Functions list includes server-side invest totals — no full txn fetch.
      final functionsResponse = await _transactionServices.listTransactionFunctions({
        'userId': userId,
      }, showLoading: false);

      final rawFunctions =
          functionsResponse is Map && functionsResponse['responseType'] == 'S'
          ? functionsResponse['responseValue']
          : null;

      // Always replace local state so deletes/creates never leave stale rows.
      if (rawFunctions is! List) {
        if (mounted) setState(() => _functionSummaries = []);
        return;
      }

      final summaries = rawFunctions.whereType<Map>().map((function) {
        final invest = double.tryParse(
              function['totalInvest']?.toString() ??
                  function['total_invest']?.toString() ??
                  '0',
            ) ??
            0;
        return {
          'function': Map<String, dynamic>.from(function),
          'name': function['functionName']?.toString() ?? '-',
          'date': formatFunctionDate(function['functionDate']?.toString()),
          'invest': invest,
        };
      }).toList();

      if (mounted) {
        setState(() => _functionSummaries = summaries);
      }
    } finally {
      if (mounted) setState(() => _isLoadingFunctionSummaries = false);
    }
  }

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
      FlutterExitApp.exitApp();
    }
  }

  Future<void> getTotalAmount({bool showLoading = true}) async {
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

  String numberFormat(int amt) {
    if (amt != 0) {
      return _numberFormatter.format(amt.toDouble());
    }
    return "0";
  }

  String getLastLoginTime(String time) {
    if (time.isEmpty) {
      return context.read<LanguageProvider>().tr('home.notAvailable');
    }
    try {
      DateTime dateTime = DateTime.parse(time).toLocal();
      return DateFormat("dd-MMM-yyyy hh:mm a").format(dateTime);
    } catch (e) {
      debugPrint('Error parsing last login time: $e');
      return context.read<LanguageProvider>().tr('home.invalidDate');
    }
  }

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
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }
}
