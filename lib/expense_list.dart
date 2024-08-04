import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'db/database_helper.dart';
import 'expense_bottomsheet.dart';

class ExpensesListPage extends StatefulWidget {
  @override
  _ExpensesListPageState createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  Map<String, List<Map<String, dynamic>>> _groupedExpenses = {};
  String currency = "\$";
  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    _loadBannerAd();
  }

  Future<void> _fetchExpenses() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    currency = preferences.getString("selected_currency") ?? "\$";

    final expenses = await DatabaseHelper().getAllExpenses(); // Fetch all expenses
    _groupExpensesByDate(expenses);
  }

  void _groupExpensesByDate(List<Map<String, dynamic>> expenses) {
    final Map<String, List<Map<String, dynamic>>> groupedExpenses = {};

    for (var expense in expenses) {
      final date = DateTime.parse(expense['date']);
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      if (!groupedExpenses.containsKey(formattedDate)) {
        groupedExpenses[formattedDate] = [];
      }
      groupedExpenses[formattedDate]!.add(expense);
    }

    setState(() {
      _groupedExpenses = groupedExpenses;
    });
  }

  Future<void> _downloadExcelFile() async {
    var excel = Excel.createExcel();
    var sheetObject = excel['Sheet1'];

    sheetObject.appendRow([TextCellValue("Date"), TextCellValue("Category"), TextCellValue("Amount")]);

    _groupedExpenses.forEach((date, expenses) {
      for (var expense in expenses) {
        sheetObject.appendRow([
          TextCellValue(date),
          TextCellValue(expense['category']),
          TextCellValue("$currency ${expense['amount']}"),
        ]);
      }
    });

    var time = DateTime.now().millisecondsSinceEpoch;
    var path = '/storage/emulated/0/Download/$time/Expenses.xlsx';
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel file saved to $path')),
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      return result == PermissionStatus.granted;
    }
  }

  void _navigateToRecordExpensePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RecordExpensePage()),
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        _fetchExpenses(); // Refresh the list after returning from the record expense page
      }
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/6300978111',
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load a banner ad: ${error.message}');
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87.withOpacity(0.9),
      appBar: AppBar(
        title: Text('Expense Management', style: TextStyle(color: Colors.yellow)),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Colors.yellow),
            onPressed: _downloadExcelFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _groupedExpenses.isEmpty
                ? Center(
              child: Text(
                'No expenses recorded yet.',
                style: TextStyle(color: Colors.yellow),
              ),
            )
                : ListView.builder(
              itemCount: _groupedExpenses.keys.length,
              itemBuilder: (context, index) {
                final date = _groupedExpenses.keys.elementAt(index);
                final expenses = _groupedExpenses[date]!;
                return ExpansionTile(
                  iconColor: Colors.yellow,
                  collapsedIconColor: Colors.yellow,
                  title: Text(date, style: TextStyle(color: Colors.yellow)),
                  children: expenses.map((expense) {
                    return ListTile(
                      title: Text('${expense['category']}', style: TextStyle(color: Colors.white)),
                      trailing: Text('$currency${expense['amount']}', style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          if (_isBannerAdReady)
            Container(
              width: _bannerAd.size.width.toDouble(),
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToRecordExpensePage(context);
        },
        backgroundColor: Colors.yellow,
        child: Icon(Icons.add, color: Colors.black87),
      ),
    );
  }
}
