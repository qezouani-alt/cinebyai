import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  ReminderNotifier({
    Future<SharedPreferences> Function()? preferences,
    Future<void> Function(int)? cancelNotification,
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _cancelNotification =
           cancelNotification ?? NotificationService().cancelNotification,
       super([]) {
    ready = _restore();
  }

  static const storageKey = 'saved_reminders_v1';
  final Future<SharedPreferences> Function() _preferences;
  final Future<void> Function(int) _cancelNotification;
  late final Future<void> ready;
  Future<void> _pending = Future<void>.value();

  Future<void> _restore() async {
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(storageKey);
      if (raw == null || !mounted) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final reminders = <Reminder>[];
      for (final entry in decoded) {
        try {
          final reminder = Reminder.fromJson(entry as Map<String, dynamic>);
          if (reminder.scheduledTime.isAfter(DateTime.now())) {
            reminders.add(reminder);
          }
        } catch (error) {
          debugPrint('Ignoring an unreadable saved reminder: $error');
        }
      }
      if (mounted) state = reminders;
    } catch (error) {
      debugPrint('Unable to restore reminders: $error');
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _pending.then((_) async {
      await ready;
      if (mounted) await action();
    });
    // Keep later operations usable even if one write/cancellation fails. The
    // original future still reports its error to the initiating screen.
    _pending = operation.catchError((Object error) {});
    return operation;
  }

  Future<void> _save(List<Reminder> reminders) async {
    final prefs = await _preferences();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode(reminders.map((r) => r.toJson()).toList()),
    );
    if (!saved) throw StateError('Unable to save reminders.');
    if (mounted) state = reminders;
  }

  Future<void> addReminder(Reminder reminder) => _enqueue(() async {
    if (!reminder.scheduledTime.isAfter(DateTime.now())) {
      throw ArgumentError('Choose a reminder time in the future.');
    }
    final active = state
        .where((r) => r.scheduledTime.isAfter(DateTime.now()))
        .toList();
    if (active.any(
      (r) =>
          r.id == reminder.id ||
          (r.mediaId == reminder.mediaId &&
              r.mediaType == reminder.mediaType &&
              r.scheduledTime.isAtSameMomentAs(reminder.scheduledTime)),
    )) {
      throw StateError('A reminder is already set for this time.');
    }
    await _save([...active, reminder]);
  });

  Future<void> removeReminder(String id) => _enqueue(() async {
    final matching = state.where((r) => r.id == id);
    if (matching.isEmpty) return;
    await _cancelNotification(matching.first.notificationId);
    await _save(state.where((r) => r.id != id).toList());
  });

  bool isReminderSet(int mediaId, String mediaType) => state.any(
    (r) =>
        r.mediaId == mediaId &&
        r.mediaType == mediaType &&
        r.scheduledTime.isAfter(DateTime.now()),
  );

  Future<void> clearReminders() => _enqueue(() async {
    for (final reminder in state) {
      await _cancelNotification(reminder.notificationId);
    }
    await _save([]);
  });
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
      return ReminderNotifier();
    });
