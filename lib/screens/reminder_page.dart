import 'dart:ui';
import 'package:flutter/cupertino.dart';
// For some material widgets if needed, but mainly Cupertino
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../services/notification_service.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ReminderPage extends ConsumerStatefulWidget {
  final int mediaId;
  final String mediaType;
  final String title;
  final String posterUrl;

  const ReminderPage({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    required this.posterUrl,
  });

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  final AdService _adService = AdService();
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 5));

  Future<void> _setReminder() async {
    // 1. Request Permissions
    final granted = await NotificationService().requestPermissions();
    if (!granted && mounted) {
      // Show permission denied dialog
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Please allow notifications to receive reminders for your movies.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Create Reminder Object
    final reminder = Reminder(
      id: const Uuid().v4(),
      mediaId: widget.mediaId,
      mediaType: widget.mediaType,
      title: widget.title,
      posterUrl: widget.posterUrl,
      scheduledTime: _selectedDateTime,
    );

    // 3. Add to Application State
    ref.read(reminderProvider.notifier).addReminder(reminder);

    // 4. Schedule Native Notification
    try {
      // Use reminder.id.hashCode for unique notification ID
      final notificationId = reminder.id.hashCode;

      await NotificationService().scheduleNotification(
        id: notificationId,
        title: 'Time to watch!',
        body: 'It\'s time to watch "${widget.title}" as you scheduled.',
        scheduledTime: _selectedDateTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }

    // 5. Show Confirmation Dialog
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.sunsetOrange),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sunsetOrange.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.bell_fill,
                      color: AppTheme.sunsetOrange,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reminder Programmed',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We will remind you to watch "${widget.title}" on ${_formatDate(_selectedDateTime)}.',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                        decoration: TextDecoration.none,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        // Show Interstitial Ad before closing
                        await _adService.showInterstitialAd();
                        if (context.mounted) {
                          Navigator.pop(context); // Close dialog
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.sunsetOrange,
                              AppTheme.sunsetOrange.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.sunsetOrange.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: CupertinoColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    // Cancel native notification
    await NotificationService().cancelNotification(reminder.id.hashCode);
    // Remove from state
    ref.read(reminderProvider.notifier).removeReminder(reminder.id);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Fetch existing reminders for this media
    final allReminders = ref.watch(reminderProvider);
    final existingReminders = allReminders
        .where(
          (r) => r.mediaId == widget.mediaId && r.mediaType == widget.mediaType,
        )
        .toList();
    // Sort by time
    existingReminders.sort(
      (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
    );

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.7),
        middle: const Text(
          'Set Reminder',
          style: TextStyle(color: CupertinoColors.white),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Media Info Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: widget.posterUrl,
                        width: 60,
                        height: 90,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 90,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.mediaType == 'movie' ? 'Movie' : 'TV Show',
                            style: TextStyle(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Existing Reminders List
              if (existingReminders.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Scheduled Reminders',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  flex:
                      3, // Give some space, but prioritize picker if list is short
                  child: ListView.builder(
                    itemCount: existingReminders.length,
                    itemBuilder: (context, index) {
                      final reminder = existingReminders[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.sunsetOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.clock,
                                color: AppTheme.sunsetOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatDate(reminder.scheduledTime),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _deleteReminder(reminder),
                                child: const Icon(
                                  CupertinoIcons.trash,
                                  color: CupertinoColors.systemRed,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              const Text(
                'When do you want to watch?',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              // Date Picker
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: _selectedDateTime,
                      minimumDate: DateTime.now(),
                      onDateTimeChanged: (DateTime newDateTime) {
                        setState(() {
                          _selectedDateTime = newDateTime;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Set Button
              GestureDetector(
                onTap: _setReminder,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.neonRed,
                        AppTheme.neonRed.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonRed.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Set Reminder',
                    style: TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
