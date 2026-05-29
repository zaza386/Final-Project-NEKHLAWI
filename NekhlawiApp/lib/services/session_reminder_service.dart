import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SessionReminderService {
  static final SessionReminderService _instance =
  SessionReminderService._internal();
  factory SessionReminderService() => _instance;
  SessionReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  final List<Timer> _activeTimers = [];

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _notifications.initialize(settings);
  }

  /// Call this when a session is confirmed/booked.
  /// [sessionStart] = the DateTime the session begins
  /// [sessionId]    = unique ID for this session
  /// [isExpert]     = true if current user is the expert
  void scheduleReminders({
    required DateTime sessionStart,
    required String sessionId,
    required bool isExpert,
  }) {
    cancelAll();

    final now = DateTime.now();

    // Safe unique IDs from session ID hash
    final baseId =
        sessionId.hashCode.abs() % 100000;

    final reminders = [
      _Reminder(
        fireAt: sessionStart.subtract(const Duration(hours: 1)),
        title: 'الجلسة بعد ساعة',
        body: isExpert
            ? 'لديك جلسة تبدأ بعد ساعة. كن مستعداً!'
            : 'جلستك مع الخبير تبدأ بعد ساعة.',
        id: baseId + 1,
      ),
      _Reminder(
        fireAt: sessionStart.subtract(const Duration(minutes: 15)),
        title: 'الجلسة بعد 15 دقيقة',
        body: isExpert
            ? 'جلستك تبدأ بعد 15 دقيقة. كن مستعدًا.'
            : 'جلستك مع الخبير تبدأ بعد 15 دقيقة!',
        id: baseId + 2,
      ),
      _Reminder(
        fireAt: sessionStart.subtract(const Duration(minutes: 5)),
        title: 'الجلسة على وشك البدء!',
        body: isExpert
            ? 'الجلسة تبدأ بعد 5 دقائق. انضم الآن!'
            : 'جلستك تبدأ بعد 5 دقائق. استعد للانضمام!',
        id: baseId + 3,
      ),
    ];

    for (final reminder in reminders) {
      final delay = reminder.fireAt.difference(now);
      if (delay.isNegative) continue;

      final timer = Timer(delay, () => _showNotification(reminder));
      _activeTimers.add(timer);
      debugPrint(
          'SessionReminderService: scheduled "${reminder.title}" in ${delay.inMinutes} min');
    }
  }

  Future<void> _showNotification(_Reminder reminder) async {
    const androidDetails = AndroidNotificationDetails(
      'session_reminders',
      'Session Reminders',
      channelDescription: 'Reminders before your sessions',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
    NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      reminder.id,
      reminder.title,
      reminder.body,
      details,
    );
  }

  void cancelAll() {
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
    debugPrint('SessionReminderService: all timers cancelled');
  }
}

class _Reminder {
  final DateTime fireAt;
  final String title;
  final String body;
  final int id;

  const _Reminder({
    required this.fireAt,
    required this.title,
    required this.body,
    required this.id,
  });
}