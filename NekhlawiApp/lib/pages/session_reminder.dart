import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SessionReminderService {
  static final SessionReminderService _instance = SessionReminderService._internal();
  factory SessionReminderService() => _instance;
  SessionReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
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
    cancelAll(); // clear any previous timers

    final now = DateTime.now();

    final reminders = [
      _Reminder(
        fireAt: sessionStart.subtract(const Duration(hours: 1)),
        title: 'Session in 1 hour',
        body: isExpert
            ? 'You have a session starting in 1 hour. Get ready!'
            : 'Your session with the expert starts in 1 hour.',
        id: int.parse(sessionId.hashCode.toString().replaceAll('-', '').substring(0, 5)) + 1,
      ),
      _Reminder(
        fireAt: sessionStart.subtract(const Duration(minutes: 15)),
        title: 'Session in 15 minutes',
        body: isExpert
            ? 'Your session starts in 15 minutes. Please be available.'
            : 'Your expert session starts in 15 minutes!',
        id: int.parse(sessionId.hashCode.toString().replaceAll('-', '').substring(0, 5)) + 2,
      ),
      _Reminder(
        fireAt: sessionStart.subtract(const Duration(minutes: 5)),
        title: 'Session starting soon!',
        body: isExpert
            ? 'Session starts in 5 minutes. Join now!'
            : 'Your session starts in 5 minutes. Get ready to join!',
        id: int.parse(sessionId.hashCode.toString().replaceAll('-', '').substring(0, 5)) + 3,
      ),
    ];

    for (final reminder in reminders) {
      final delay = reminder.fireAt.difference(now);
      if (delay.isNegative) continue; // already passed, skip

      final timer = Timer(delay, () => _showNotification(reminder));
      _activeTimers.add(timer);
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
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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
  }
}

class _Reminder {
  final DateTime fireAt;
  final String title;
  final String body;
  final int id;
  const _Reminder({required this.fireAt, required this.title, required this.body, required this.id});
}