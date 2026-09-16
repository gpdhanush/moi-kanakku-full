import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:moi/app_pages/home_page/widgets/build_side_drawer.dart';
import 'package:moi/app_pages/home_page/widgets/home_app_header.dart';
import 'package:moi/app_pages/home_page/widgets/home_function_totals_section.dart';
import 'package:moi/app_pages/home_page/widgets/home_greeting_header.dart';
import 'package:moi/app_pages/home_page/widgets/home_moi_overview_card.dart';
import 'package:moi/app_pages/home_page/widgets/home_section_reveal.dart';
import 'package:moi/app_pages/home_page/widgets/home_upcoming_section.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_services/moi_services.dart';
import 'package:moi/app_services/notification_services.dart';
import 'package:moi/app_services/transaction_services.dart';
import 'package:moi/app_services/upcoming_function_services.dart';
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SecureStorageService _secureStorage = SecureStorageService();
  final AlertServices _alertServices = AlertServices();
  final MoiServices _moiServices = MoiServices();
  final NotificationServices _notificationServices = NotificationServices();
  final TransactionServices _transactionServices = TransactionServices();
  final UpcomingFunctionServices _upcomingFunctionServices =
      UpcomingFunctionServices();

  int totalAmount = 0;
  int totalMOAmount = 0;
  List<Map<String, dynamic>> _functionSummaries = [];
  bool _isLoadingFunctionSummaries = false;
  List<UpcomingFunction> _upcomingFunctions = [];
  bool _isLoadingUpcoming = false;

  bool _isInitialized = false;
  bool _needsRefresh = false;
  DateTime? _lastFetchTime;
  int _unreadNotificationCount = 0;

  late final Upgrader _upgrader;
  static bool _upgradeCheckedThisLaunch = false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initHomePage();
    });
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
      initialTasks.add(_loadUpcomingFunctions());

      await Future.wait(initialTasks);
      unawaited(_initializeNotificationPipeline());

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

  Future<void> _initializeNotificationPipeline() async {
    try {
      await PushNotificationService.instance.syncTokenForCurrentUser();
    } catch (e) {
      debugPrint('Background notification setup error: $e');
    }
  }

  bool _isDataCached() => _lastFetchTime != null;

  bool _isCacheExpired() {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  Future<void> _refreshAfterNavigation() async {
    if (mounted) {
      _needsRefresh = true;
      await Future.wait([
        getTotalAmount(),
        _loadFunctionSummaries(),
        _loadUpcomingFunctions(),
      ]);
    }
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
            fontFamily: 'Inter',
          ),
          contentTextStyle: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
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
      drawer: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return BuildSideDrawer(
            userDetails: userProvider.userDetails,
            context: context,
          );
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPad = constraints.maxWidth >= 480
              ? AppSpacing.xl
              : AppSpacing.page;

          return MoiRefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                getTotalAmount(showLoading: false),
                _loadFunctionSummaries(),
                _loadUpcomingFunctions(),
              ]);
            },
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
                        AppSpacing.xxl,
                      ),
                      children: [
                        HomeSectionReveal(
                          index: 0,
                          child: HomeGreetingHeader(
                            formatLastLogin: getLastLoginTime,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        HomeSectionReveal(
                          index: 1,
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
                          index: 2,
                          child: HomeUpcomingSection(
                            items: _upcomingFunctions,
                            isLoading: _isLoadingUpcoming,
                            formatDate: formatFunctionDate,
                            onViewAll: () async {
                              await Navigator.pushNamed(
                                context,
                                'upcoming-function-list',
                              );
                              if (mounted) await _loadUpcomingFunctions();
                            },
                            onItemTap: (item) {
                              Navigator.pushNamed(
                                context,
                                'upcoming-function-details',
                                arguments: item,
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
                            onItemTap: (summary) {
                              Navigator.pushNamed(
                                context,
                                'view-functions-list',
                                arguments: [summary['function']],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        HomeSectionReveal(
                          index: 4,
                          child: HomeTipNote(
                            message:
                                languageProvider.tr('home.transactionNote'),
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

  Future<void> _loadUpcomingFunctions() async {
    if (!mounted) return;
    setState(() => _isLoadingUpcoming = true);
    try {
      final response = await _upcomingFunctionServices.getUpcomingFunctions(
        showLoading: false,
      );
      if (!mounted) return;

      if (response != null && response['responseType'] == 'S') {
        final list = response['responseValue'] ?? [];
        final parsed = List<UpcomingFunction>.from(
          list.map((item) => UpcomingFunction.fromJson(item)),
        );
        parsed.sort((a, b) {
          final aDate = DateTime.tryParse(a.functionDate) ?? DateTime(2100);
          final bDate = DateTime.tryParse(b.functionDate) ?? DateTime(2100);
          return aDate.compareTo(bDate);
        });
        final active = parsed
            .where((item) => item.status.toUpperCase() == 'ACTIVE')
            .toList();
        setState(() {
          _upcomingFunctions = active.isNotEmpty ? active : parsed;
        });
      } else {
        setState(() => _upcomingFunctions = []);
      }
    } catch (e) {
      debugPrint('Error loading upcoming functions: $e');
      if (mounted) setState(() => _upcomingFunctions = []);
    } finally {
      if (mounted) setState(() => _isLoadingUpcoming = false);
    }
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
