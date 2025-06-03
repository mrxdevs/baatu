import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification channels and permissions
  Future<void> initialize(BuildContext context) async {
    // Request permission for iOS
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configure local notifications
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInitialize = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iOSInitialize,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        handleNotificationTap(details.payload, context);
      },
    );

    // Create notification channel for Android
    await createNotificationChannel();

    // Handle FCM messages
    FirebaseMessaging.onMessage.listen((message) {
      handleForegroundMessage(message, context);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleNotificationTap(message.data['route'], context);
    });

    // Check if app was opened from terminated state
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationTap(initialMessage.data['route'], context);
    }
  }

  Future<void> createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> handleForegroundMessage(
    RemoteMessage message,
    BuildContext context,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      icon: 'ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: message.data['route'],
    );
  }

  void handleNotificationTap(String? route, BuildContext context) {
    if (route == null) return;

    switch (route) {
      case 'chat_screen':
        Navigator.pushNamed(context, '/chat_screen');
        break;
      case 'profile_screen':
        Navigator.pushNamed(context, '/profile_screen');
        break;
      case 'share_screen':
        Navigator.pushNamed(context, '/share_screen');
        break;
      // Add more routes as needed
    }
  }

  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
