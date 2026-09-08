import 'package:flutter/material.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_pages/index.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashScreenController _splashController;

  @override
  void initState() {
    super.initState();
    _splashController = SplashScreenController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _splashController.setContext(context);
      _splashController.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider.value(
      value: _splashController,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(AppImages.appLogoImage, width: 120, height: 120),
                ],
              ),
            ),
            Positioned(
              bottom: 25,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 25),
                  Consumer<SplashScreenController>(
                    builder: (context, controller, child) {
                      return Text(
                        "App Version: ${controller.version}",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        // style: TextStyle(
                        //   color: colorScheme.primary,
                        //   fontWeight: FontWeight.bold,
                        // ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (mounted) {
      _splashController.dispose();
    }
    super.dispose();
  }
}
