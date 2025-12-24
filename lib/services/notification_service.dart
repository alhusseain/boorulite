import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'preferences_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static final PreferencesService _preferencesService = PreferencesService();
  
  static bool _notificationsEnabled = true;
  
  static bool get notificationsEnabled => _notificationsEnabled;
  
  static Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _preferencesService.setBool('notifications_enabled', enabled);
  }
  
  static Future<void> _loadSettings() async {
    _notificationsEnabled = await _preferencesService.getBool('notifications_enabled', true);
  }

  static final List<Map<String, String>> _missYouMessages = [
    {
      'title': "Your Booru's Miss You! 💔",
      'body': "Come look at some art or else....",
    },
    {
      'title': "Please Come Back! 🥺",
      'body': "We miss you so much...",
    },
    {
      'title': "HEY! 🎨",
      'body': "NEW BOORU'S dropped! Come check them out!",
    },
  ];

  static Future<void> initialize() async {
    try {
      await Future.wait([
        _loadSettings(),
      ]).timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('NotificationService: Settings load timed out, using defaults');
        return [];
      });
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('NotificationService: Plugin init timed out');
      });
      
      _requestPermissions();
      
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Initialization failed: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // later later 
  }

  static Future<void> showMissYouNotification() async {
    if (!_notificationsEnabled) return;
    
    final random = Random();
    final message = _missYouMessages[random.nextInt(_missYouMessages.length)];
    
    await _showNotification(
      title: message['title']!,
      body: message['body']!,
    );
  }

  static Future<void> showMissYouNotificationByIndex(int index) async {
    if (!_notificationsEnabled) return;
    if (index < 0 || index >= _missYouMessages.length) return;
    
    final message = _missYouMessages[index];
    
    await _showNotification(
      title: message['title']!,
      body: message['body']!,
    );
  }

  static Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'booru_miss_you_channel',
      'Miss You Notifications',
      channelDescription: 'Notifications sent when you leave the app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  static Future<void> scheduleMissYouNotification(Duration delay) async {
    if (!_notificationsEnabled) return;
    
    final random = Random();
    final message = _missYouMessages[random.nextInt(_missYouMessages.length)];
    
    const androidDetails = AndroidNotificationDetails(
      'booru_miss_you_channel',
      'Miss You Notifications',
      channelDescription: 'Notifications sent when you leave the app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    Future.delayed(delay, () async {
      if (_notificationsEnabled) {
        await _notifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          message['title']!,
          message['body']!,
          details,
        );
      }
    });
  }
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
