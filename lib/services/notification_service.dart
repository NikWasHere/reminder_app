import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      await _requestPermissions();
      _isInitialized = true;
    } catch (e) {
      // If notification initialization fails, continue without notifications
      debugPrint('Notification initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse notificationResponse) {
    // Handle notification tap
  }

  // Schedule notification for class reminder (15 minutes before)
  Future<void> scheduleClassReminder({
    required int id,
    required String courseName,
    required String lecturer,
    required String room,
    required String day,
    required String startTime,
  }) async {
    if (!_isInitialized) return;

    try {
      final scheduledTime = _getNextClassTime(day, startTime);
      if (scheduledTime == null) return;

      // Schedule 15 minutes before class
      final reminderTime = scheduledTime.subtract(const Duration(minutes: 15));

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Class Reminder',
        '$courseName with $lecturer in $room starts in 15 minutes',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'class_reminders',
            'Class Reminders',
            channelDescription: 'Notifications for upcoming classes',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule class reminder: $e');
      // Continue without notifications - don't throw error
    }
  }

  // Schedule assignment deadline reminders (H-1 and H-0)
  Future<void> scheduleAssignmentReminders({
    required int assignmentId,
    required String courseName,
    required String description,
    required DateTime dueDate,
  }) async {
    if (!_isInitialized) return;

    try {
      // H-1 (24 hours before)
      final dayBefore = dueDate.subtract(const Duration(days: 1));
      if (dayBefore.isAfter(DateTime.now())) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          assignmentId * 100, // Unique ID for H-1
          'Assignment Due Tomorrow',
          '$description ($courseName) deadline tomorrow at ${DateFormat('HH:mm').format(dueDate)}',
          tz.TZDateTime.from(dayBefore, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'assignment_reminders',
              'Assignment Reminders',
              channelDescription: 'Notifications for assignment deadlines',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      // H-0 (on the day, 2 hours before)
      final dayOf = dueDate.subtract(const Duration(hours: 2));
      if (dayOf.isAfter(DateTime.now())) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          assignmentId * 100 + 1, // Unique ID for H-0
          'Assignment Due Today',
          '$description ($courseName) deadline today at ${DateFormat('HH:mm').format(dueDate)}',
          tz.TZDateTime.from(dayOf, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'assignment_reminders',
              'Assignment Reminders',
              channelDescription: 'Notifications for assignment deadlines',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule assignment reminders: $e');
    }
  }

  // Cancel class reminder
  Future<void> cancelClassReminder(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel assignment reminders
  Future<void> cancelAssignmentReminders(int assignmentId) async {
    await _flutterLocalNotificationsPlugin.cancel(assignmentId * 100); // H-1
    await _flutterLocalNotificationsPlugin.cancel(
      assignmentId * 100 + 1,
    ); // H-0
  }

  DateTime? _getNextClassTime(String day, String startTime) {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final targetWeekday = weekdays.indexOf(day) + 1;
    if (targetWeekday == 0) return null;

    final timeParts = startTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    // Find next occurrence of this day and time
    var nextClass = DateTime(now.year, now.month, now.day, hour, minute);

    // Adjust to the correct weekday
    final daysUntilTarget = (targetWeekday - now.weekday) % 7;
    if (daysUntilTarget == 0 && nextClass.isBefore(now)) {
      // If it's today but the time has passed, schedule for next week
      nextClass = nextClass.add(const Duration(days: 7));
    } else if (daysUntilTarget > 0) {
      nextClass = nextClass.add(Duration(days: daysUntilTarget));
    }

    return nextClass;
  }
}
