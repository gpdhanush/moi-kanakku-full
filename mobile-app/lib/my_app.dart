import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/connectivity_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  /// Preserves the single EasyLoading Host across MaterialApp rebuilds.
  final GlobalKey _easyLoadingHostKey = GlobalKey(
    debugLabel: 'EasyLoadingHost',
  );

  final SystemUiOverlayStyle _overlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setSystemUIOverlayStyle(_overlayStyle);
      unawaited(
        StartupTiming.timeAsync(
          'PushNotificationService.initialize',
          () => PushNotificationService.instance.initialize(),
        ),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(PushNotificationService.instance.syncTokenForCurrentUser());
    }
  }

  @override
  void dispose() {
    PushNotificationService.instance.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return OrientationBuilder(
                builder: (context, orientation) {
                  SizeConfig().get(constraints, orientation);

                  return MaterialApp(
                    theme: themeProvider.getThemeForLanguage(
                      languageProvider.currentLanguage,
                    ),
                    locale: Locale(languageProvider.currentLanguage),
                    title: appName,
                    debugShowCheckedModeBanner: false,
                    initialRoute: 'splash',
                    // Keep a single FlutterEasyLoading Host (GlobalKey) so
                    // theme/language rebuilds do not remount it. Apply Tamil
                    // text scale on the child only — never wrap the Host.
                    builder: (context, child) {
                      final langScale = AppThemes.textScaleForLanguage(
                        languageProvider.currentLanguage,
                      );
                      final media = MediaQuery.of(context);
                      final systemFactor = media.textScaler.scale(14) / 14;
                      return FlutterEasyLoading(
                        key: _easyLoadingHostKey,
                        child: MediaQuery(
                          data: media.copyWith(
                            textScaler: TextScaler.linear(
                              systemFactor * langScale,
                            ),
                          ),
                          child: child ?? const SizedBox.shrink(),
                        ),
                      );
                    },
                    onGenerateRoute: AppRoute.allRoutes,
                    navigatorKey: navigatorKey,
                    scaffoldMessengerKey: scaffoldMessengerKey,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
