import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_configs/startup_timing.dart';
import 'package:moi/app_pages/functions/functions_list.dart';
import 'package:moi/app_pages/home_page/home_page.dart';
import 'package:moi/app_pages/more/more_page.dart';
import 'package:moi/app_pages/transactions/transaction_dashboard.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_global/alert_services.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_widgets/custom_action_sheet.dart';
import 'package:moi/app_utils/app_widgets/moi_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  final AlertServices _alertServices = AlertServices();
  final ValueNotifier<int> _homeRefreshSignal = ValueNotifier<int>(0);
  int _currentIndex = 0;

  /// Home | Function | Overview | More  (Center Add + button protruding in half of border)
  static const _tabCount = 4;

  final Set<int> _visitedTabs = {0};
  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    StartupTiming.log('MainShellPage mounted');
    _pageCache[0] = HomePage(
      isShellTab: true,
      refreshSignal: _homeRefreshSignal,
    );
  }

  Widget _pageFor(int index) {
    return _pageCache.putIfAbsent(index, () {
      StartupTiming.log('MainShell tab $index first create');
      switch (index) {
        case 0:
          return HomePage(isShellTab: true, refreshSignal: _homeRefreshSignal);
        case 1:
          return const TransactionDashboard(embeddedInShell: true);
        case 2:
          return const FunctionsList(embeddedInShell: true);
        case 3:
          return const MorePage();
        default:
          return const SizedBox.shrink();
      }
    });
  }

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    final previous = _currentIndex;
    setState(() {
      _visitedTabs.add(index);
      _currentIndex = index;
    });
    if (index == 0 && previous != 0) {
      _homeRefreshSignal.value++;
    }
  }

  Future<void> _openAddMoiSheet() async {
    final languageProvider = context.read<LanguageProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    await showMoiActionSheet(
      context: context,
      title: '',
      titleColor: primary,
      actions: [
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedArrowDownLeft01,
          title: languageProvider.tr('transactions.newInvest'),
          color: primary,
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            await _openAddMoiForm('INVEST');
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedArrowUpRight01,
          title: languageProvider.tr('transactions.newReturn'),
          color: const Color(0xFFF2B84B),
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
            await _openAddMoiForm('RETURN');
          },
        ),
        ActionSheetItem(
          hugeIcon: HugeIcons.strokeRoundedCancel01,
          title: languageProvider.tr('common.cancel'),
          isCancel: true,
          onPressed: (sheetContext) async {
            Navigator.pop(sheetContext);
          },
        ),
      ],
    );
  }

  Future<void> _openAddMoiForm(String type) async {
    final result = await Navigator.pushNamed(
      context,
      'add-edit-transaction',
      arguments: {'type': type},
    );
    if (result == true && mounted) {
      _homeRefreshSignal.value++;
    }
  }

  @override
  void dispose() {
    _homeRefreshSignal.dispose();
    super.dispose();
  }

  Future<void> _onBack() async {
    if (_currentIndex != 0) {
      _goToTab(0);
      return;
    }

    try {
      final message = context.read<LanguageProvider>().tr(
        'common.exitConfirmation',
      );
      final confirm = await _alertServices.confirmExitSheet(context, message);
      if (confirm == true) {
        FlutterExitApp.exitApp();
      }
    } catch (_) {
      FlutterExitApp.exitApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final items = [
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedHome01,
            label: languageProvider.tr('nav.home'),
          ),
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedAnalytics01,
            label: languageProvider.tr('nav.overview'),
          ),
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedWedding,
            label: languageProvider.tr('nav.function'),
          ),
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedMoreHorizontal,
            label: languageProvider.tr('nav.more'),
          ),
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onBack();
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: IndexedStack(
              index: _currentIndex.clamp(0, _tabCount - 1),
              children: List.generate(_tabCount, (index) {
                if (!_visitedTabs.contains(index)) {
                  return const SizedBox.shrink();
                }
                return _pageFor(index);
              }),
            ),
            bottomNavigationBar: MoiBottomNavBar(
              currentIndex: _currentIndex,
              items: items,
              onTap: _goToTab,
              onAddTap: _openAddMoiSheet,
            ),
          ),
        );
      },
    );
  }
}
