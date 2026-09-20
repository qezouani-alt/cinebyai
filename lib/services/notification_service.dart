import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static const int _dailyMovieReminderId = 90_000;
  static const String _dailyMovieReminderTitle = 'Tonight is movie time 🎬';
  static const String _dailyMovieReminderBody =
      "Don't miss your movie tonight — discover something great on Cineby.";

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> initialize() {
    if (!_isIOS) return Future<void>.value();
    return _initialization ??= _initializeIOS().catchError((Object error) {
      _initialization = null;
      throw error;
    });
  }

  Future<void> _initializeIOS() async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 5),
      );
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error) {
      // TZDateTime.from preserves the selected instant even with UTC fallback.
      tz.setLocalLocation(tz.UTC);
      debugPrint('Unable to read device timezone: $error');
    }

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: false,
          requestBadgePermission: false,
          requestAlertPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(iOS: initializationSettingsDarwin);

    final initialized = await flutterLocalNotificationsPlugin
        .initialize(settings: initializationSettings)
        .timeout(const Duration(seconds: 10));
    // On iOS the plugin returns `false` when initialization deliberately does
    // not request permissions. We request them only when the user saves a
    // reminder, so `false` is a valid initialization result here.
    if (initialized == null) {
      throw StateError('Unable to initialize iOS notifications.');
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isIOS) return false;
    await initialize();
    final bool? result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }

  /// Requests permission, then schedules a notification that repeats every
  /// day at 20:00 in the device's current time zone.
  Future<bool> scheduleDailyMovieReminder() async {
    if (!_isIOS) return false;
    if (!await requestPermissions()) return false;

    final now = tz.TZDateTime.now(tz.local);
    var nextTwentyHundred = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20,
    );
    if (!nextTwentyHundred.isAfter(now)) {
      nextTwentyHundred = nextTwentyHundred.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: _dailyMovieReminderId,
      title: _dailyMovieReminderTitle,
      body: _dailyMovieReminderBody,
      scheduledDate: nextTwentyHundred,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    if (!_isIOS) throw UnsupportedError('Reminders require an iOS device.');
    await initialize();
    if (!scheduledTime.isAfter(DateTime.now())) {
      throw ArgumentError('Choose a reminder time in the future.');
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      // Required by the cross-platform plugin API; unused on iOS.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_isIOS) return;
    await initialize();
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
