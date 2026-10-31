import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:moi/app_themes/app_themes.dart';
import 'package:moi/app_utils/app_widgets/moi_bottom_nav_bar.dart';

void main() {
  testWidgets('keeps every destination labeled and marks the selected tab', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: Scaffold(
          bottomNavigationBar: MoiBottomNavBar(
            currentIndex: 0,
            items: const [
              MoiBottomNavItem(
                icon: HugeIcons.strokeRoundedHome01,
                label: 'Home',
              ),
              MoiBottomNavItem(
                icon: HugeIcons.strokeRoundedAnalytics01,
                label: 'Overview',
              ),
            ],
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    final homeSemantics = tester.getSemantics(find.text('Home'));
    final homeData = homeSemantics.getSemanticsData();
    expect(homeData.flagsCollection.isButton, isTrue);
    expect(homeData.flagsCollection.isSelected, Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('touch feedback activates the selected destination', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.lightTheme,
        home: Scaffold(
          bottomNavigationBar: MoiBottomNavBar(
            currentIndex: selectedIndex,
            items: const [
              MoiBottomNavItem(
                icon: HugeIcons.strokeRoundedHome01,
                label: 'Home',
              ),
              MoiBottomNavItem(
                icon: HugeIcons.strokeRoundedAnalytics01,
                label: 'Overview',
              ),
            ],
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Overview'));
    expect(selectedIndex, 1);
  });
}
