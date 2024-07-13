import 'package:expense_manager/services/notification_plugin.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'analytics_page.dart';
import 'compare_expenses_page.dart';
import 'db/database_helper.dart';
import 'expense_bottomsheet.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'expense_list.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request notification permission

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  NotificationService notificationService = NotificationService();

  static final List<Widget> _pages = <Widget>[
    ExpensesListPage(),
    AnalyticsPage(),
    CompareExpensesPage(), // New page for comparing expenses
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    _requestNotificationPermission(); // Request notification permission

    super.initState();
  }

  Future<void> _requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      // You can show a dialog to explain why you need the permission
      if (await Permission.notification.request().isGranted) {
        notificationService.initialiseNotifications();
        notificationService.scheduleNotification();
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    notificationService.scheduleNotification();

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare),
            label: 'Compare',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
