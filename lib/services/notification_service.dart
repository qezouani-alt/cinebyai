import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    String timeZoneName = 'UTC';
    try {
      final dynamic result = await FlutterTimezone.getLocalTimezone();
      final String raw = result.toString();

      if (raw.startsWith('TimezoneInfo')) {
        // It's the object dumped as a string, we need to parse it
        // Example: TimezoneInfo(Africa/Casablanca, (locale: fr...))
        if (raw.contains('(') && raw.contains(',')) {
          timeZoneName = raw.split('(')[1].split(',')[0].trim();
        }
      } else {
        // It's likely just the ID (e.g. "Africa/Casablanca")
        timeZoneName = raw;
      }
    } catch (e) {
      // Fallback
      timeZoneName = 'UTC';
    }

    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // If the parsed name is still invalid, fallback to UTC
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (e) {
        // Should never happen if data is loaded, but just in case
        debugPrint('Error setting UTC fallback: $e');
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );
  }

  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? exactAlarmResult = await androidImplementation
          ?.requestExactAlarmsPermission();
      final bool? notificationResult = await androidImplementation
          ?.requestNotificationsPermission();

      return (exactAlarmResult ?? false) && (notificationResult ?? false);
    }
    return false;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Generate a unique integer ID from the string ID if possible, or pass an int.
    // For simplicity, we'll assume the caller generates a unique hash or int.
    // However, the plugin requires an int ID.
    // We will use the hashCode of the string ID or the media ID if unique enough.

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'Channel for movie and TV show reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents
          .time, // Optional: useful for recurring, but okay here
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
