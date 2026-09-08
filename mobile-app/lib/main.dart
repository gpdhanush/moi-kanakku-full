import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:moi/app_firebase/firebase_options.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_themes/theme_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/my_app.dart';
import 'package:provider/provider.dart';

void main() {
  runZonedGuarded(
    () async {
      pageTitleLogs("MAIN FILE");
      WidgetsFlutterBinding.ensureInitialized();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Initialize Firebase
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e, stack) {
        printContent("FIREBASE INIT ERROR: ${e.toString()}");
        await FirebaseCrashlytics.instance.recordError(e, stack);
      }

      // Set up system UI
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      // Configure Firebase services
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      };
      FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        kReleaseMode,
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Build providers
      final themeProvider = ThemeProvider();
      final languageProvider = LanguageProvider();

      // Start app quickly; non-critical tasks continue in background
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: themeProvider),
            ChangeNotifierProvider.value(value: languageProvider),
          ],
          child: const MyApp(),
        ),
      );

      // Non-blocking startup tasks
      unawaited(themeProvider.ensureLoaded());
      unawaited(initializeDateFormatting('en', null));
      unawaited(initializeDateFormatting('ta', null));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      printContent("FIREBASE ERROR CATCH: ${error.toString()}");
    },
  );
}
