import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'logger_service.dart';

/// Schedules the end-of-day calorie summary as a local notification.
///
/// Mobile only: local notifications are a no-op on web and desktop targets.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!_supported || _initialized) return;
    try {
      tz.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _initialized = true;
    } catch (e, stack) {
      LoggerService()
          .error(e, stack, reason: 'NotificationService.init failed');
    }
  }

  Future<void> requestPermissions() async {
    if (!_supported || !_initialized) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e, stack) {
      LoggerService()
          .error(e, stack, reason: 'Notification permission request failed');
    }
  }

  /// Schedules tonight's one-shot summary (10 PM if dinner was logged,
  /// otherwise midnight). Re-invoked on every dashboard load, so the id-0
  /// notification is always replaced with up-to-date totals.
  ///
  /// ponytail: one-shot instead of a repeating schedule — if the app isn't
  /// opened that day no summary fires. For true daily repeats add
  /// flutter_timezone + matchDateTimeComponents with a real local Location.
  Future<void> scheduleDailySummary(
      int caloriesConsumed, int calorieTarget, bool ateDinner) async {
    if (!_supported || !_initialized) return;

    final now = DateTime.now();
    final targetHour = ateDinner ? 22 : 0;

    var scheduledDate = DateTime(now.year, now.month, now.day, targetHour);
    if (targetHour == 0) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final message = ateDinner
        ? "You've logged dinner! You consumed $caloriesConsumed / $calorieTarget kcal today."
        : 'End of day summary: You consumed $caloriesConsumed / $calorieTarget kcal today.';

    try {
      await _plugin.zonedSchedule(
        id: 0,
        title: 'CalorAI Daily Summary',
        body: message,
        // scheduledDate is a local DateTime, which already carries the correct
        // instant; converting to the UTC location preserves it. tz.local is NOT
        // used because it defaults to UTC and would shift the wall-clock time.
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary_channel',
            'Daily Summary',
            channelDescription: 'Daily calorie summary notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // Inexact avoids the SCHEDULE_EXACT_ALARM permission; a summary that
        // arrives within a few minutes of 10 PM is fine.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e, stack) {
      LoggerService()
          .error(e, stack, reason: 'Failed to schedule daily summary');
    }
  }
}
