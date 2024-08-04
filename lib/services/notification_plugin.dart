import 'dart:async';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings androidInitializationSettings =
  const AndroidInitializationSettings('app_notf_icon');
  final DarwinInitializationSettings iosInitializationSettings =
  const DarwinInitializationSettings();

  initialiseNotifications() async {
    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      ),
    );
  }

  void sendNotification(String title, String body) async {
    AndroidNotificationDetails androidNotificationDetails =
    const AndroidNotificationDetails('channelId', 'channelName',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xffeb4034));

    const iosNotificatonDetail = DarwinNotificationDetails();

    NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails, iOS: iosNotificatonDetail);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'daily_reminder_channel_id',
      'Daily Reminder',
      channelDescription: 'Reminder to record daily expenses',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosNotificatonDetail = DarwinNotificationDetails();

    DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, 21, 30);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    tz.TZDateTime scheduledTime = tz.TZDateTime.from(
      scheduledDate,
      tz.local,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosNotificatonDetail,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'This title is for testing purpose in simple notification',
      'This body is for besting purpose in simple notification',
tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)),      notificationDetails, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode:AndroidScheduleMode.exactAllowWhileIdle
    );
  }
}
