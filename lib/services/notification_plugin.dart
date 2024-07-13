import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService{
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final AndroidInitializationSettings androidInitializationSettings =  const AndroidInitializationSettings('app_notf_icon');

   initialiseNotifications() async{
    InitializationSettings initializationSettings = InitializationSettings(android:  androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void sendNotification(String title, String body) async{
    AndroidNotificationDetails androidNotificationDetails = const AndroidNotificationDetails('channelId', 'channelName', importance: Importance.max, priority: Priority.high, color: Color(0xffeb4034));

    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
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
    NotificationDetails notificationDetails = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.showDailyAtTime(
      0,
      'Record Daily Expense',
      'Don\'t forget to record your expenses for today!',
      const Time(20, 0, 0), // Schedule for 8 PM
      notificationDetails,
    );
  }
}