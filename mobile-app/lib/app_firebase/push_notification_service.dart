import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:moi/app_configs/app_logs.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_firebase/firebase_options.dart';
import 'package:moi/app_services/user_services.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/device_info_service.dart';

/// Handles FCM background messages (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushNotificationService.showMessageNotification(message);
}

/// Centralized FCM + local notification setup for the whole app.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String channelId = 'high_importance_channel';
  static const String channelName = 'High Importance Notifications';
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    channelId,
    channelName,
    description: 'Important alerts such as feedback replies',
    importance: Importance.high,
    enableVibration: true,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SecureStorageService _secureStorage = SecureStorageService();
  UserServices? _userServices;

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    if (_initialized) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    );
    await _localNotifications.initialize(initSettings);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.requestNotificationsPermission();

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundSubscription ??=
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _secureStorage.saveNotificationToken(token);
      await _syncTokenWithBackend();
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_logOpenedMessage);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logOpenedMessage(initialMessage);
    }

    _initialized = true;
    printContent('PushNotificationService initialized');
  }

  Future<void> syncTokenForCurrentUser() async {
    await _syncTokenWithBackend();
  }

  Future<void> _syncTokenWithBackend() async {
    try {
      final user = await _secureStorage.get(AppVariables.userInformation);
      if (user == null || user['id'] == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token unavailable');
        return;
      }

      final localToken = await _secureStorage.getNotificationToken();
      if (localToken == token) return;

      await _secureStorage.saveNotificationToken(token);
      final device = await DeviceService.getDeviceInfo();
      _userServices ??= UserServices();
      await _userServices!.updateUserNotificationToken(
        {
          'userId': user['id'].toString(),
          'token': token,
          'device_id': device.device_id,
          'device_name': device.device_name,
          'brand': device.brand,
          'model': device.model,
          'manufacturer': device.manufacturer,
          'android_version': device.android_version,
          'ram_size': device.ram_size,
        },
        showLoading: false,
      );
    } catch (e) {
      debugPrint('Error syncing FCM token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await showMessageNotification(message);
  }

  static Future<void> showMessageNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final title = _resolveTitle(message);
    final body = _resolveBody(message);
    if (title == null && body == null) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
    );
    await plugin.initialize(initSettings);

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await plugin.show(
      notificationId,
      title ?? 'Moi Kanakku',
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Important alerts such as feedback replies',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
      ),
    );
  }

  static String? _resolveTitle(RemoteMessage message) {
    return message.notification?.title ??
        message.data['title']?.toString() ??
        message.data['subject']?.toString();
  }

  static String? _resolveBody(RemoteMessage message) {
    return message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        message.data['reply']?.toString();
  }

  void _logOpenedMessage(RemoteMessage message) {
    printContent(
      'Notification opened: ${_resolveTitle(message)} | ${_resolveBody(message)}',
    );
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _foregroundSubscription = null;
    _tokenRefreshSubscription = null;
  }
}
