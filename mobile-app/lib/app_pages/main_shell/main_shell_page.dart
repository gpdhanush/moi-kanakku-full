import 'package:flutter/material.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_pages/feedbacks/feedbacks.dart';
import 'package:moi/app_pages/functions/functions_list.dart';
import 'package:moi/app_pages/home_page/home_page.dart';
import 'package:moi/app_pages/more/more_page.dart';
import 'package:moi/app_pages/transactions/transaction_dashboard.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_global/alert_services.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
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

  static const _tabCount = 5;

  late final List<Widget> _pages = [
    HomePage(isShellTab: true, refreshSignal: _homeRefreshSignal),
    const FunctionsList(embeddedInShell: true),
    const TransactionDashboard(embeddedInShell: true),
    const Feedbacks(embeddedInShell: true),
    const MorePage(),
  ];

  void _goToTab(int index) {
    if (index == _currentIndex) return;
    final previous = _currentIndex;
    setState(() => _currentIndex = index);
    // IndexedStack keeps Home alive — refresh when returning to Home.
    if (index == 0 && previous != 0) {
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
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final items = [
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedHome01,
            label: languageProvider.tr('nav.home'),
          ),
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedWedding,
            label: languageProvider.tr('nav.function'),
          ),
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedAnalytics01,
            label: languageProvider.tr('nav.overview'),
          ),
          MoiBottomNavItem(
            icon: HugeIcons.strokeRoundedComment01,
            label: languageProvider.tr('nav.feedbacks'),
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
            backgroundColor: AppColors.background,
            body: IndexedStack(
              index: _currentIndex.clamp(0, _tabCount - 1),
              children: _pages,
            ),
            bottomNavigationBar: MoiBottomNavBar(
              currentIndex: _currentIndex,
              items: items,
              onTap: _goToTab,
            ),
          ),
        );
      },
    );
  }
}
