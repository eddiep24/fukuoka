import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlucoseGraph extends StatelessWidget {
  final List<Map<String, dynamic>> unformattedSpots;
  final List<Map<String, dynamic>> predictedData;

  GlucoseGraph(this.unformattedSpots, this.predictedData);
  // GlucoseGraph(this.unformattedSpots);

  @override
  Widget build(BuildContext context) {
    // Initialize the spots list
    List<Map<String, double>> spots = [];

    // Extract glucose values for statistical calculations
    List<double> glucoseValues = unformattedSpots
        .map<double>((element) => double.parse(element['glucose'].toString()))
        .toList();

    // Calculate mean and standard deviation
    double mean = glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;
    double stddev = math.sqrt(glucoseValues.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / glucoseValues.length);

    // Calculate minY and maxY
    double minY = glucoseValues.reduce(math.min) - stddev;
    double maxY = glucoseValues.reduce(math.max) + stddev;

    // Convert unformatted spots to Map<String, double>
    unformattedSpots.forEach((element) {
      double timeInSeconds = _parseTime(element['time'].toString());
      Map<String, double> convertedMap = {
        'time': timeInSeconds,
        'glucose': double.parse(element['glucose'].toString()),
      };
      spots.add(convertedMap);
    });

    // Sort spots by time
    spots.sort((a, b) => a['time']!.compareTo(b['time']!));

    // Find the first chronological date
    double firstDate = spots.isNotEmpty ? spots.first['time']! : 0.0;

    // Adjust x-axis values to make the first chronological date correspond to time = 0
    spots.forEach((spot) {
      spot['time'] = spot['time']! - firstDate;
    });

    bool displayInMinutes = spots.isNotEmpty && spots.last['time']! > 360;

    // Convert time to hours if time range exceeds 3 hours
    bool displayInHours = spots.isNotEmpty && spots.last['time']! > 21600;

    // Calculate interval for x-axis labels
    double range = spots.last['time']! - spots.first['time']!;
    double interval = (spots.last['time']! - spots.first['time']!) / 4;
    interval = interval > 0 ? interval : 1; // Ensure interval is greater than zero

    // Calculate interval for y-axis labels
    double yInterval = (maxY - minY) / 5;
    yInterval = yInterval > 0 ? yInterval : 1; // Ensure interval is greater than zero

    // Convert the list of maps to a list of FlSpot
    List<FlSpot> flSpots = spots.map((spotMap) {
      double x = spotMap['time']!;
      double y = spotMap['glucose']!;
      return FlSpot(x, y);
    }).toList();

    // Calculate minX and maxX
    double minX = flSpots.first.x;
    double maxX = flSpots.last.x;

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 22,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              verticalInterval: (maxX - minX) / 4 > 0 ? (maxX - minX) / 4 : 1,
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            // titlesData: FlTitlesData(
            //   bottomTitles: AxisTitles(
            //     showTitles: true,
            //     reservedSize: 30,
            //     interval: interval > 0 ? interval : 1,
            //     getTitlesWidget: (value, meta) {
            //       String text;
            //       if (displayInHours) {
            //         text = '${(value / 3600).toInt()} h';
            //       } else if (displayInMinutes) {
            //         text = '${(value / 60).toInt()} min';
            //       } else {
            //         text = '${value.toInt()} s';
            //       }
            //       return SideTitleWidget(
            //         axisSide: meta.axisSide,
            //         child: Text(
            //           text,
            //           style: const TextStyle(color: Colors.black, fontSize: 12), // Customize text style
            //         ),
            //       );
            //     },
            //   ),
            //   leftTitles: AxisTitles(
            //     showTitles: true,
            //     interval: yInterval,
            //     getTitlesWidget: (value, meta) {
            //       return SideTitleWidget(
            //         axisSide: meta.axisSide,
            //         child: Text(
            //           '${value.toStringAsFixed(3)} V', // Customize y-axis labels
            //           style: const TextStyle(color: Colors.black, fontSize: 12), // Customize text style
            //         ),
            //       );
            //     },
            //     reservedSize: 42,
            //   ),
            // ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey[300]!),
            ),
            minX: minX,
            maxX: maxX,
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: flSpots,
                isCurved: true,
                color: Colors.cyan, // Adjusted
                barWidth: 5,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: false, // Disable area below line
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to parse time string into seconds
  double _parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      double seconds = double.parse(parts[2]);
      return hours * 3600 + minutes * 60 + seconds;
    } else {
      // Handle invalid time format
      print('Invalid time format: $timeString');
      return 0; // Return a default value or handle the error as needed
    }
  }
}
