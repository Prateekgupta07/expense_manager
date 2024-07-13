import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings androidInitializationSettings =
      const AndroidInitializationSettings('app_notf_icon');
  final DarwinInitializationSettings iosInitializationSettings = const DarwinInitializationSettings();

  initialiseNotifications() async {
    InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings, iOS: iosInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
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
        0, title, body, notificationDetails);
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


    NotificationDetails notificationDetails =
    const NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosNotificatonDetail);

    await flutterLocalNotificationsPlugin.zonedSchedule(

      0,
      'Record Daily Expense',
      'Don\'t forget to record your expenses for today!',
      _nextInstanceOf8PM(),
      notificationDetails, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  tz.TZDateTime _nextInstanceOf8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
