import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moi/app_firebase/firebase_options.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_configs/startup_timing.dart';
import 'package:moi/app_themes/theme_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/my_app.dart';
import 'package:provider/provider.dart';

void main() {
  var firebaseInitialized = false;

  runZonedGuarded(
    () async {
      pageTitleLogs("MAIN FILE");
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        printContent("ENV LOAD ERROR: ${e.toString()}");
      }
      apiSecretKey = dotenv.env['API_SECRET_KEY']?.trim() ?? '';
      StartupTiming.markAppStart();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      // Initialize Firebase
      try {
        await StartupTiming.timeAsync('Firebase.initializeApp', () async {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          firebaseInitialized = true;
        });
      } catch (e, stack) {
        printContent("FIREBASE INIT ERROR: ${e.toString()}");
        if (firebaseInitialized) {
          await FirebaseCrashlytics.instance.recordError(e, stack);
        }
      }

      // Set up system UI
      await StartupTiming.timeAsync('setPreferredOrientations', () async {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      });

      // Configure Firebase services
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (firebaseInitialized) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        if (firebaseInitialized) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };
      if (firebaseInitialized) {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          kReleaseMode,
        );
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Build providers
      final themeProvider = ThemeProvider();
      final languageProvider = LanguageProvider();
      await StartupTiming.timeAsync('ThemeProvider.ensureLoaded', () async {
        await themeProvider.ensureLoaded();
      });

      StartupTiming.log('runApp');
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
      unawaited(initializeDateFormatting('en', null));
      unawaited(initializeDateFormatting('ta', null));
    },
    (error, stack) {
      if (firebaseInitialized) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
      printContent("FIREBASE ERROR CATCH: ${error.toString()}");
    },
  );
}
