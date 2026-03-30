import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey;

  static Future<void> init(GlobalKey<NavigatorState> key) async {
    navigatorKey = key;
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          navigatorKey?.currentState?.pushNamed('/caseDetails', arguments: response.payload);
        }
      },
    );
  }

  /// ✅ New: General function to schedule alarms for both Client and Lawyer
  static Future<void> scheduleCaseNotification({
    required String caseId,
    required String title,
    required String body,
    required String description,
    required DateTime scheduledTime,
    required int notificationId, required String clientName,
  }) async {
    // Only schedule if the time is in the future
    if (scheduledTime.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'case_alarm_channel',
          'Case Alarms',
          channelDescription: 'Reminders for upcoming legal hearings',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            description,
            contentTitle: '<b>$title</b>',
            summaryText: body,
            htmlFormatContent: true,
            htmlFormatContentTitle: true,
          ),
        ),
      ),
      payload: caseId,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}