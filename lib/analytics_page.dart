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
  void initState() {
    // TODO: implement initState

    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black87, // Background color for the page
        appBar: AppBar(
          title: Text('Analytics', style: TextStyle(color: Colors.yellow),),
          backgroundColor: Colors.black87, // AppBar background color
          bottom: TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
            ],
            labelColor: Colors.yellow, // Selected tab label color
            unselectedLabelColor: Colors.white, // Unselected tab label color
            indicatorColor: Colors.yellow, // Tab indicator color
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
              return Text('No data available for $period.', style: TextStyle(color: Colors.white));
            } else {
              return SfCartesianChart(
                plotAreaBorderWidth: 0,
                enableAxisAnimation: true,
                backgroundColor: Colors.black87, // Chart background color
                primaryXAxis: CategoryAxis(

                  labelStyle: TextStyle(color: Colors.white), // X-axis label color
                ),
                legend: Legend(isVisible: true),
                // Enable tooltip
                tooltipBehavior: TooltipBehavior(enable: true),

                primaryYAxis: NumericAxis(

                  labelStyle: TextStyle(color: Colors.white), // Y-axis label color
                ),
                title: ChartTitle(
                  text: '${_capitalizeFirstLetter(period)} Expenses',
                  textStyle: TextStyle(color: Colors.white), // Chart title color
                ),
                series: <LineSeries<ChartData, String>>[
                  LineSeries<ChartData, String>(
                    dataSource: snapshot.data!,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: Colors.yellow, // Line color
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(color: Colors.yellow), // Data label color
                    ),
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
        formattedDate = DateFormat('E').format(date); // e.g., Mon
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
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}
