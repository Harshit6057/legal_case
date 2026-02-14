import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? navigatorKey; // For navigation from background

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
          // ✅ Navigate to the details page when notification is clicked
          navigatorKey?.currentState?.pushNamed('/caseDetails', arguments: response.payload);
        }
      },
    );
  }

  // Inside lib/services/notification_service.dart

  static Future<void> scheduleAlarm({
    required int id,
    required String clientName,
    required String caseNumber,
    required String description,
    required DateTime scheduledTime,
    required String caseId,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      'Upcoming Case: $clientName', // Title in collapsed view
      'Case #$caseNumber', // Body in collapsed view
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'case_alarm_channel',
          'Case Alarms',
          channelDescription: 'Detailed case reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          // ✅ UPDATED: Gmail-style expandable content
          styleInformation: BigTextStyleInformation(
            description, // The full description shown when expanded
            contentTitle: '<b>$clientName</b>', // Bold title when expanded
            summaryText: 'Case No: $caseNumber', // Small text above the description
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