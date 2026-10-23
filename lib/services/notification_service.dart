
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationDetails _androidDetails =
  AndroidNotificationDetails(
    'borrowit_notifications',
    'BorrowIT Notifications',
    channelDescription:
    'Borrowing status updates and equipment return reminders.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _notificationDetails =
  NotificationDetails(android: _androidDetails);

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Manila'));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: settings);
  }

  static Future<void> requestPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
  }

  // Generates a consistent ID from a Firestore request ID.
  // Two IDs are reserved for the request's return reminders.
  static int notificationIdFor(String requestId) {
    var hash = 0x811c9dc5;

    for (final codeUnit in requestId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }

    // Keep the ID within a positive 30-bit range.
    return (hash & 0x1fffffff) + 1;
  }

  static Future<void> showStatusNotification({
    required String requestId,
    required String equipmentName,
    required String status,
  }) async {
    final normalizedStatus = status.toLowerCase();

    final message = switch (normalizedStatus) {
      'approved' => 'Your borrowing request has been approved.',
      'rejected' => 'Your borrowing request has been rejected.',
      'borrowed' => 'Your equipment has been marked as borrowed.',
      'returned' => 'Your equipment has been marked as returned.',
      _ => 'Your borrowing request status is now $status.',
    };

    await _notifications.show(
      id: notificationIdFor(requestId) + 2,
      title: 'BorrowIT: $equipmentName',
      body: message,
      notificationDetails: _notificationDetails,
    );
  }

  // Schedules reminders for one day before and on the return date.
  static Future<void> scheduleReturnReminders({
    required String requestId,
    required String equipmentName,
    required DateTime returnDate,
  }) async {
    final notificationId = notificationIdFor(requestId);
    final now = tz.TZDateTime.now(tz.local);

    final returnDay = tz.TZDateTime(
      tz.local,
      returnDate.year,
      returnDate.month,
      returnDate.day,
      9,
    );

    final dayBefore = returnDay.subtract(
      const Duration(days: 1),
    );

    if (dayBefore.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: notificationId,
        title: 'Equipment Return Reminder',
        body: 'Your $equipmentName is due tomorrow.',
        scheduledDate: dayBefore,
        notificationDetails: _notificationDetails,
        androidScheduleMode:
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else {
      await _notifications.cancel(id: notificationId);
    }

    if (returnDay.isAfter(now)) {
      await _notifications.zonedSchedule(
        id: notificationId + 1,
        title: 'Equipment Due Today',
        body: 'Today is the return date for $equipmentName.',
        scheduledDate: returnDay,
        notificationDetails: _notificationDetails,
        androidScheduleMode:
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } else {
      await _notifications.cancel(id: notificationId + 1);
    }
  }

  static Future<void> cancelReturnReminders(
      String requestId,
      ) async {
    final notificationId = notificationIdFor(requestId);

    await _notifications.cancel(id: notificationId);
    await _notifications.cancel(id: notificationId + 1);
  }
  static Future<void> showTestNotification() async {
    await _notifications.show(
      id: 999999,
      title: 'BorrowIT Notifications',
      body: 'Notifications are working correctly!',
      notificationDetails: _notificationDetails,
    );
  }
}
