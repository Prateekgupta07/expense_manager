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
  String currency = "";

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    final now = DateTime.now();
    SharedPreferences preferences = await SharedPreferences.getInstance();
    currency = preferences.getString("selected_currency") ?? "\$";

    // Date calculations
    final currentWeekStartDate = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final currentWeekEndDate = now;

    final lastWeekStart = currentWeekStartDate.subtract(Duration(days: 7));
    final lastWeekEnd = lastWeekStart.add(Duration(days: 6));

    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(Duration(days: 1));

    final currentMonthStart = DateTime(now.year, now.month, 1);

    // Fetch expenses
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
      DateFormat('yyyy-MM-dd').format(currentMonthStart),
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
    return expenses.fold(0.0, (total, expense) => total + expense['amount']);
  }

  double _calculateDifference(double currentTotal, double lastTotal) {
    return currentTotal - lastTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87.withOpacity(0.9),
      appBar: AppBar(
        title: Text('Compare Expenses', style: TextStyle(color: Colors.yellow)),
        backgroundColor: Colors.black87,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
      color: Colors.yellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 10),
            Text(
              'Last Period Total: $currency ${lastTotal.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.black,                 fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Current Period Total: $currency ${currentTotal.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.black,                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Difference: $currency ${difference.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: difference >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
