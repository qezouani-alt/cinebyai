import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder_model.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  ReminderNotifier() : super([]) {
    _cleanupExpired();
  }

  void _cleanupExpired() {
    final now = DateTime.now();
    state = state.where((r) => r.scheduledTime.isAfter(now)).toList();
  }

  void addReminder(Reminder reminder) {
    _cleanupExpired(); // Clean up before adding new one
    // Allow multiple reminders for the same media, but prevent exact duplicates (same time)
    if (!state.any(
      (r) =>
          r.mediaId == reminder.mediaId &&
          r.mediaType == reminder.mediaType &&
          r.scheduledTime.isAtSameMomentAs(reminder.scheduledTime),
    )) {
      state = [...state, reminder];
    }
  }

  void removeReminder(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  bool isReminderSet(int mediaId, String mediaType) {
    return state.any((r) => r.mediaId == mediaId && r.mediaType == mediaType);
  }

  void clearReminders() {
    state = [];
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
      return ReminderNotifier();
    });
