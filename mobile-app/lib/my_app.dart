import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_firebase/push_notification_service.dart';
import 'package:moi/app_themes/index.dart';
import 'package:moi/app_utils/app_providers/connectivity_provider.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
      unawaited(PushNotificationService.instance.initialize());
    });
  }

  @override
  void dispose() {
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
                    builder: EasyLoading.init(),
                    onGenerateRoute: AppRoute.allRoutes,
                    navigatorKey: navigatorKey,
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
