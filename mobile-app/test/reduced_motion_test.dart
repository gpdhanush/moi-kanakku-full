import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moi/app_pages/force_update/rotating_settings_icon.dart';
import 'package:moi/app_utils/app_widgets/voice_listening_indicator.dart';
import 'package:moi/app_utils/app_widgets/wave_bottom.dart';

void main() {
  testWidgets(
    'repeating shared animations stop when reduced motion is enabled',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Column(
                children: [
                  AnimatedWaveBottom(color: Colors.green),
                  VoiceListeningIndicator(active: true, color: Colors.green),
                  RotatingSettingsIcon(
                    color: Colors.green,
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(RotatingSettingsIcon),
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
      );
    },
  );
}
