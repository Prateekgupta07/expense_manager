import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/database_helper.dart';

class CompareExpensesPage extends StatefulWidget {
  @override
  _CompareExpensesPageState createState() => _CompareExpensesPageState();
}

class _CompareExpensesPageState extends State<CompareExpensesPage> {
  late List<Map<String, dynamic>> _lastWeekExpenses = [];
  late List<Map<String, dynamic>> _currentWeekExpenses = [];
  late List<Map<String, dynamic>> _lastMonthExpenses = [];
  late List<Map<String, dynamic>> _currentMonthExpenses = [];
  String currency ="";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    final now = DateTime.now();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    currency = preferences.getString("selected_currency")??"\$";
    // Current week start and end dates (Monday to now)
    final currentWeekStartDate = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final currentWeekEndDate = now;

    // Last week start and end dates (Last Monday to last Sunday)
    final lastWeekStart = currentWeekStartDate.subtract(Duration(days: 7));
    final lastWeekEnd = lastWeekStart.add(Duration(days: 6));

    // Last month start and end dates (First day of last month to last day of last month)
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(Duration(days: 1));

    final lastWeekExpenses = await DatabaseHelper().getExpensesForCustomPeriod(
      DateFormat('yyyy-MM-dd').format(lastWeekStart),
      DateFormat('yyyy-MM-dd').format(lastWeekEnd),
    );

    final currentWeekExpenses = await DatabaseHelper().getExpensesForCustomPeriod(
      DateFormat('yyyy-MM-dd').format(currentWeekStartDate),
      DateFormat('yyyy-MM-dd').format(currentWeekEndDate),
    );

    final lastMonthExpenses = await DatabaseHelper().getExpensesForCustomPeriod(
      DateFormat('yyyy-MM-dd').format(lastMonthStart),
      DateFormat('yyyy-MM-dd').format(lastMonthEnd),
    );

    final currentMonthExpenses = await DatabaseHelper().getExpensesForCustomPeriod(
      DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1)),
      DateFormat('yyyy-MM-dd').format(now),
    );

    setState(() {
      _lastWeekExpenses = lastWeekExpenses;
      _currentWeekExpenses = currentWeekExpenses;
      _lastMonthExpenses = lastMonthExpenses;
      _currentMonthExpenses = currentMonthExpenses;
      _isLoading = false;
    });
  }

  double _calculateTotalExpenses(List<Map<String, dynamic>> expenses) {
    double total = 0.0;
    for (var expense in expenses) {
      total += expense['amount'];
    }
    return total;
  }

  double _calculateDifference(double currentTotal, double lastTotal) {
    return currentTotal - lastTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Compare Expenses')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildComparisonCard(
              title: 'Weekly Comparison',
              lastExpenses: _lastWeekExpenses,
              currentExpenses: _currentWeekExpenses,
            ),
            SizedBox(height: 20),
            _buildComparisonCard(
              title: 'Monthly Comparison',
              lastExpenses: _lastMonthExpenses,
              currentExpenses: _currentMonthExpenses,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard({
    required String title,
    required List<Map<String, dynamic>> lastExpenses,
    required List<Map<String, dynamic>> currentExpenses,
  }) {
    final double lastTotal = _calculateTotalExpenses(lastExpenses);
    final double currentTotal = _calculateTotalExpenses(currentExpenses);
    final double difference = _calculateDifference(currentTotal, lastTotal);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Last Period Total: $currency ${lastTotal.toStringAsFixed(2)}'),
            Text('Current Period Total: $currency ${currentTotal.toStringAsFixed(2)}'),
            Text('Difference: $currency ${difference.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
