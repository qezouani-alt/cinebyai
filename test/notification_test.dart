import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  IOSFlutterLocalNotificationsPlugin.registerWith();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezone = MethodChannel('flutter_timezone');
  final calls = <MethodCall>[];
  var failInitialization = true;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    calls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      timezone,
      (_) async => {'identifier': 'Africa/Casablanca'},
    );
    messenger.setMockMethodCallHandler(notifications, (call) async {
      calls.add(call);
      if (call.method == 'initialize') {
        if (failInitialization) {
          failInitialization = false;
          throw PlatformException(code: 'temporary_failure');
        }
        // Darwin reports false when permissions are intentionally deferred.
        return false;
      }
      if (call.method == 'requestPermissions') return true;
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(notifications, null);
    messenger.setMockMethodCallHandler(timezone, null);
  });

  test(
    'failed notification initialization can retry with deferred permissions',
    () async {
      await expectLater(
        NotificationService().initialize(),
        throwsA(isA<PlatformException>()),
      );
      await NotificationService().initialize();
      expect(calls.where((c) => c.method == 'initialize').length, 2);
    },
  );

  test(
    'iOS reminders use real timezone and fire once at selected date',
    () async {
      await NotificationService().scheduleNotification(
        id: 42,
        title: 'Time to watch',
        body: 'Your film',
        scheduledTime: DateTime.now().add(const Duration(days: 1)),
      );
      final args =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(args['timeZoneName'], 'Africa/Casablanca');
      expect(args.containsKey('matchDateTimeComponents'), isFalse);
      expect(args['id'], 42);
    },
  );

  test('daily movie reminder repeats at 20:00 local time', () async {
    final scheduled = await NotificationService().scheduleDailyMovieReminder();

    expect(scheduled, isTrue);
    final args =
        calls.singleWhere((c) => c.method == 'zonedSchedule').arguments as Map;
    expect(args['id'], 90000);
    expect(args['title'], 'Tonight is movie time 🎬');
    expect(
      args['body'],
      "Don't miss your movie tonight — discover something great on Cineby.",
    );
    expect(args['matchDateTimeComponents'], DateTimeComponents.time.index);
  });

  test('past reminder is rejected without sending a native schedule', () async {
    await expectLater(
      NotificationService().scheduleNotification(
        id: 43,
        title: 'Time to watch',
        body: 'Your film',
        scheduledTime: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
      throwsArgumentError,
    );
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });
}
