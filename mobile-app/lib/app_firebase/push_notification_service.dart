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
import 'package:moi/app_themes/app_colors.dart';
import 'package:moi/app_utils/device_info_service.dart';
import 'package:moi/app_utils/device_heartbeat.dart';

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

  /// White-on-transparent silhouette from [moi_kanakku_monochrome.png].
  static const String androidSmallIcon = '@drawable/ic_stat_moi_kanakku';

  /// Full-color app logo from [moi_kanakku.png] shown as the large icon.
  static const String androidLargeIcon = '@drawable/ic_notification_logo';

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
  DateTime? _lastHeartbeatAt;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    if (_initialized) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings(androidSmallIcon),
    );
    await _localNotifications.initialize(settings: initSettings);

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
      await _syncTokenWithBackend(force: true);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_logOpenedMessage);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _logOpenedMessage(initialMessage);
    }

    _initialized = true;
    printContent('PushNotificationService initialized');
  }

  Future<void> syncTokenForCurrentUser({bool force = false}) async {
    await _syncTokenWithBackend(force: force);
  }

  Future<void> _syncTokenWithBackend({bool force = false}) async {
    try {
      if (!shouldSendDeviceHeartbeat(
        force: force,
        lastSentAt: _lastHeartbeatAt,
      )) {
        return;
      }

      final user = await _secureStorage.get(AppVariables.userInformation);
      if (user == null || user['id'] == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token unavailable');
        return;
      }

      await _secureStorage.saveNotificationToken(token);
      final device = await DeviceService.getDeviceInfo();
      _userServices ??= UserServices();
      await _userServices!.updateUserNotificationToken(
        {
          'token': token,
          'device_id': device.device_id,
          'device_name': device.device_name,
          'brand': device.brand,
          'model': device.model,
          'manufacturer': device.manufacturer,
          'android_version': device.android_version,
          'ram_size': device.ram_size,
          'platform': device.platform,
          'app_version': device.app_version,
        },
        showLoading: false,
      );
      _lastHeartbeatAt = DateTime.now();
    } catch (e) {
      debugPrint('Error syncing device heartbeat');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await showMessageNotification(message, fromForeground: true);
  }

  static Future<void> showMessageNotification(
    RemoteMessage message, {
    bool fromForeground = false,
  }) async {
    if (kIsWeb) return;
    if (message.data['type'] == 'device_health_check') return;

    // FCM already displays notification-payload messages in the system tray
    // when the app is backgrounded or killed. Showing another local
    // notification here makes the same alert appear twice.
    if (!fromForeground && message.notification != null) return;

    final title = _resolveTitle(message);
    final body = _resolveBody(message);
    if (title == null && body == null) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings(androidSmallIcon),
    );
    await plugin.initialize(settings: initSettings);

    final androidPlugin = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);

    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
    final resolvedTitle = title ?? 'Moi Kanakku';
    final resolvedBody = body ?? '';

    await plugin.show(
      id: notificationId,
      title: resolvedTitle,
      body: resolvedBody,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Important alerts such as feedback replies',
          importance: Importance.high,
          priority: Priority.high,
          icon: androidSmallIcon,
          largeIcon: const DrawableResourceAndroidBitmap(androidLargeIcon),
          color: AppColors.logoGreen,
          styleInformation: BigTextStyleInformation(
            resolvedBody,
            contentTitle: resolvedTitle,
          ),
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
