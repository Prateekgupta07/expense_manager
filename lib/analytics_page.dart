import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'db/database_helper.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Analytics'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            AnalyticsTabView(period: 'weekly'),
            AnalyticsTabView(period: 'monthly'),
            AnalyticsTabView(period: 'yearly'),
          ],
        ),
      ),
    );
  }
}

class AnalyticsTabView extends StatelessWidget {
  final String period;

  const AnalyticsTabView({required this.period});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<ChartData>>(
          future: _getChartDataForPeriod(period),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No data available for $period.');
            } else {
              return SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                title: ChartTitle(text: '$period Expenses'),
                series: <LineSeries<ChartData, String>>[
                  LineSeries<ChartData, String>(
                    dataSource: snapshot.data!,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                  )
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Future<List<ChartData>> _getChartDataForPeriod(String period) async {
    final expenses = await DatabaseHelper().getExpensesForPeriod(period);

    // Use a Map to aggregate expenses by date
    Map<String, double> dailyTotals = {};

    // Aggregate expenses by date
    for (var expense in expenses) {
      final date = DateTime.parse(expense['date']);
      String formattedDate;

      // Format date based on period
      if (period == 'weekly') {
        // Calculate start of week (assuming week starts on Monday)
        formattedDate = DateFormat('E').format(date); // e.g., Jan 01
      } else if (period == 'monthly') {
        formattedDate = DateFormat('MMM dd').format(date); // e.g., Jan 01
      } else {
        formattedDate = DateFormat('yyyy MMM').format(date); // e.g., 2024 Jan
      }

      // Aggregate expenses by formatted date
      if (dailyTotals.containsKey(formattedDate)) {
        // Retrieve current value
        double currentValue = dailyTotals[formattedDate]!;

        // Update with new value
        dailyTotals[formattedDate] = currentValue + expense['amount'];
      } else {
        // Add new entry
        dailyTotals[formattedDate] = expense['amount'];
      }
    }

    // Print dailyTotals for debugging purposes
    dailyTotals.forEach((date, amount) {
      print('Date: $date, Amount: $amount');
    });

    // Convert aggregated data to ChartData objects
    List<ChartData> chartData = [];

    // Create ChartData objects and add them to chartData list
    dailyTotals.forEach((date, amount) {
      chartData.add(ChartData(date, amount));
    });

    return chartData;
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}
