import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlucoseGraph extends StatelessWidget {
  final List<Map<String, dynamic>> unformatted_spots;

  GlucoseGraph(this.unformatted_spots);

  @override
  Widget build(BuildContext context) {
    // Initialize the spots list
    List<Map<String, double>> spots = [];

    // Extract glucose values for statistical calculations
    List<double> glucoseValues = unformatted_spots
        .map<double>((element) => double.parse(element['glucose'].toString()))
        .toList();

    // Calculate mean and standard deviation
    double mean = glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;
    double stddev = math.sqrt(glucoseValues.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / glucoseValues.length);

    // Convert unformatted spots to Map<String, double>
    unformatted_spots.forEach((element) {
      double timeInSeconds = _parseTime(element['time'].toString());
      Map<String, double> convertedMap = {
        'time': timeInSeconds,
        'glucose': double.parse(element['glucose'].toString()),
      };
      spots.add(convertedMap);
    });

    // Convert the list of maps to a list of FlSpot
    List<FlSpot> flSpots = spots.map((spotMap) {
      double x = double.parse(spotMap['time']!.toString().length >= 5 ? spotMap['time']!.toString().substring(0, 4) : spotMap['time']!.toString()); // Extract time
      double y = double.parse(spotMap['glucose']!.toStringAsFixed(5)); // Extract glucose and round to 5 decimal places
      return FlSpot(x, y);
    }).toList();

    // Calculate minY and maxY with standard deviation
    double minY = glucoseValues.reduce(math.min) - stddev;
    double maxY = glucoseValues.reduce(math.max) + stddev;

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey[300]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: SideTitles(showTitles: false),
              topTitles: SideTitles(showTitles: false),
              bottomTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontSize: 12), // Customize text style
                getTitles: (value) {
                  return '${value.toInt()} s'; // Customize x-axis labels
                },
                margin: 8,
              ),
              leftTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 4, // Adjust interval for 4 ticks
                getTextStyles: (context, value) => const TextStyle(color: Colors.black, fontSize: 12), // Customize text style
                getTitles: (value) {
                  return '${value.toStringAsFixed(3)} V'; // Customize y-axis labels
                },
                reservedSize: 42,
                margin: 12,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey[300]!),
            ),
            minX: 0,
            maxX: flSpots.length.toDouble() - 1, // Adjust according to your data
            minY: minY,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: flSpots,
                isCurved: true,
                colors: [
                  Colors.cyan,
                  Colors.blue,
                ],
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
    double seconds = 0;
    if (parts.length == 3) {
      seconds = double.parse(parts[2]);
    }
    return seconds;
  }
}
