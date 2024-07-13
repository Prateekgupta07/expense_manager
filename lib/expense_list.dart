import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import 'db/database_helper.dart';
import 'expense_bottomsheet.dart';

class ExpensesListPage extends StatefulWidget {
  @override
  _ExpensesListPageState createState() => _ExpensesListPageState();
}

class _ExpensesListPageState extends State<ExpensesListPage> {
  Map<String, List<Map<String, dynamic>>> _groupedExpenses = {};
  String currency = "\$";

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    currency = preferences.getString("selected_currency") ?? "\$";

    final expenses = await DatabaseHelper().getExpensesForPeriod('weekly'); // Default to weekly for now
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

      // Adding headers
      // sheetObject.appendRow(['Date', 'Category', 'Amount', 'Currency']);
      sheetObject.appendRow([TextCellValue("Date"),TextCellValue("Category"),TextCellValue("Amount")]);

      // Adding expense data
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Expense Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadExcelFile,
          ),
        ],
      ),
      body: _groupedExpenses.isEmpty
          ? Center(child: Text('No expenses recorded yet.'))
          : ListView.builder(
        itemCount: _groupedExpenses.keys.length,
        itemBuilder: (context, index) {
          final date = _groupedExpenses.keys.elementAt(index);
          final expenses = _groupedExpenses[date]!;
          return ExpansionTile(
            title: Text(date),
            children: expenses.map((expense) {
              return ListTile(
                title: Text('${expense['category']}'),
                trailing: Text('$currency${expense['amount']}'),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRecordExpensePage(context),
        child: Icon(Icons.add),
      ),
    );
  }
}
