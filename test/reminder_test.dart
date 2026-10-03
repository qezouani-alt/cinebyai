import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:newmovie/models/reminder_model.dart';
import 'package:newmovie/providers/reminder_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Reminder _reminder(String id, {DateTime? time}) => Reminder(
  id: id,
  mediaId: id == 'one' ? 1 : 2,
  mediaType: 'movie',
  title: 'Film $id',
  posterUrl: '',
  scheduledTime: time ?? DateTime.now().add(const Duration(days: 1)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reminders and cancellable notification IDs survive restart', () async {
    final cancelled = <int>[];
    final reminder = _reminder('one');
    final first = ReminderNotifier(
      cancelNotification: (id) async {
        cancelled.add(id);
      },
    );
    await first.addReminder(reminder);
    first.dispose();
    final second = ReminderNotifier(
      cancelNotification: (id) async {
        cancelled.add(id);
      },
    );
    await second.ready;
    expect(second.state.single.title, reminder.title);
    expect(second.state.single.notificationId, reminder.notificationId);
    await second.removeReminder(reminder.id);
    expect(cancelled, [reminder.notificationId]);
    second.dispose();
    final third = ReminderNotifier();
    await third.ready;
    expect(third.state, isEmpty);
    third.dispose();
  });

  test(
    'mutation waits for restoration and keeps concurrent additions',
    () async {
      final stored = _reminder('one');
      SharedPreferences.setMockInitialValues({
        ReminderNotifier.storageKey: jsonEncode([stored.toJson()]),
      });
      final prefs = await SharedPreferences.getInstance();
      final gate = Completer<SharedPreferences>();
      final notifier = ReminderNotifier(preferences: () => gate.future);
      final addition = notifier.addReminder(_reminder('two'));
      gate.complete(prefs);
      await addition;
      expect(notifier.state.map((r) => r.id), ['one', 'two']);
      notifier.dispose();
    },
  );

  test(
    'clear cancels native notifications and persists empty collection',
    () async {
      final cancelled = <int>[];
      final notifier = ReminderNotifier(
        cancelNotification: (id) async {
          cancelled.add(id);
        },
      );
      final first = _reminder('one');
      final second = _reminder('two');
      await Future.wait([
        notifier.addReminder(first),
        notifier.addReminder(second),
      ]);
      await notifier.clearReminders();
      expect(cancelled, [first.notificationId, second.notificationId]);
      expect(notifier.state, isEmpty);
      notifier.dispose();
      final restored = ReminderNotifier();
      await restored.ready;
      expect(restored.state, isEmpty);
      restored.dispose();
    },
  );

  test(
    'malformed and expired entries do not hide valid saved reminders',
    () async {
      final valid = _reminder('one');
      final expired = _reminder(
        'old',
        time: DateTime.now().subtract(const Duration(days: 1)),
      );
      SharedPreferences.setMockInitialValues({
        ReminderNotifier.storageKey: jsonEncode([
          {'broken': true},
          expired.toJson(),
          valid.toJson(),
        ]),
      });
      final notifier = ReminderNotifier();
      await notifier.ready;
      expect(notifier.state.map((r) => r.id), ['one']);
      notifier.dispose();
    },
  );
}
