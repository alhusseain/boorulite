import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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
      tz.initializeTimeZones();
      
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
      
      debugPrint('NotificationService: Initialized successfully');
    } catch (e) {
      debugPrint('NotificationService: Initialization failed: $e');
    }
  }

  /// Request notification permission - call this after UI is visible
  static Future<void> requestPermission() async {
    final status = await Permission.notification.status;
    debugPrint('NotificationService: Initial permission status: $status');
    
    if (status.isDenied) {
      final result = await Permission.notification.request();
      debugPrint('NotificationService: Permission request result: $result');
    } else if (status.isPermanentlyDenied) {
      debugPrint('NotificationService: Permission permanently denied, opening settings');
      await openAppSettings();
    } else if (status.isGranted) {
      debugPrint('NotificationService: Permission already granted');
    }
    
    // iOS permissions handled by flutter_local_notifications init
    final iosGranted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    debugPrint('NotificationService: iOS permission granted: $iosGranted');
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
      icon: '@mipmap/launcher_icon',
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
      icon: '@mipmap/launcher_icon',
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
    
    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);
    
    await _notifications.zonedSchedule(
      0,
      message['title']!,
      message['body']!,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
