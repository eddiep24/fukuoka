import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlucoseGraph extends StatelessWidget {
  final List<Map<String, dynamic>> unformattedSpots;
  final List<Map<String, dynamic>> predictedData;

  GlucoseGraph(this.unformattedSpots, this.predictedData);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> combinedSpots = [];
    List<bool> isPredicted = [];

    // Extract glucose values for statistical calculations
    List<double> glucoseValues = unformattedSpots
        .map<double>((element) => double.parse(element['glucose'].toString()))
        .toList();

    // Calculate mean and standard deviation
    double mean = glucoseValues.reduce((a, b) => a + b) / glucoseValues.length;
    double stddev = math.sqrt(glucoseValues.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / glucoseValues.length);

    // Calculate minY and maxY with a buffer
    double minY = (glucoseValues.reduce(math.min) - stddev).clamp(0, double.infinity);
    double maxY = glucoseValues.reduce(math.max) + stddev;
    double buffer = (maxY - minY) * 0.1; // Add 10% buffer
    minY = (minY - buffer).clamp(0, double.infinity);
    maxY = maxY + buffer;

    // Process actual data
    combinedSpots.addAll(unformattedSpots.map((element) => {
      'time': _parseTime(element['time'].toString()),
      'glucose': double.parse(element['glucose'].toString()),
    }));
    isPredicted.addAll(List.filled(unformattedSpots.length, false));

    // Process predicted data
    combinedSpots.addAll(predictedData.map((element) => {
      'time': _parseTime(element['time'].toString()),
      'glucose': double.parse(element['glucose'].toString()),
    }));
    isPredicted.addAll(List.filled(predictedData.length, true));

    // Sort spots by time
    combinedSpots.sort((a, b) => a['time'].compareTo(b['time']));
    
    // Find the index where prediction starts
    int predictionStartIndex = isPredicted.indexOf(true);

    // Recalculate isPredicted based on sorted combinedSpots
    if (predictionStartIndex != -1) {
      double predictionStartTime = combinedSpots[predictionStartIndex]['time'];
      isPredicted = combinedSpots.map((spot) => (spot['time'] >= predictionStartTime) as bool).toList();
    } else {
      isPredicted = List.filled(combinedSpots.length, false);
    }

    // Calculate minX and maxX
    double minX = combinedSpots.first['time'];
    double maxX = combinedSpots.last['time'];

    // Generate appropriate labels
    List<double> labelPositions = _generateLabelPositions(minX, maxX, combinedSpots);

    // Determine time display format and calculate intervals for axis labels
    double xRange = maxX - minX;
    double yInterval = (maxY - minY) / 4;

    // Convert to FlSpot
    List<FlSpot> flSpots = combinedSpots.map((spot) => FlSpot(spot['time'], spot['glucose'])).toList();

    return AspectRatio(
      aspectRatio: 1.70,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 18, left: 18, top: 24, bottom: 12),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (labelPositions.contains(value)) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(_formatTimeForAxis(value), style: const TextStyle(color: Colors.black, fontSize: 12)),
                          );
                        }
                        return SideTitleWidget(axisSide: meta.axisSide, child: const Text(''));
                      },
                      interval: 1, // Check every value
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toStringAsFixed(1)} mmol/L',
                            style: const TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        );
                      },
                      reservedSize: 60,
                      interval: yInterval,
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: flSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.red],
                      stops: predictionStartIndex != -1 
                        ? [predictionStartIndex / flSpots.length, predictionStartIndex / flSpots.length]
                        : [1.0, 1.0], // If there's no prediction, use blue for the entire line
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        bool isPredictedPoint = isPredicted[flSpot.spotIndex];
                        String prefix = isPredictedPoint ? 'Predicted\n' : '';
                        return LineTooltipItem(
                          '$prefix${_formatTime(flSpot.x)}\n${flSpot.y.toStringAsFixed(1)} mmol/L',
                          TextStyle(color: Colors.white, fontWeight: isPredictedPoint ? FontWeight.bold : FontWeight.normal),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: Colors.blue, strokeWidth: 4),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 8,
                              color: Colors.white,
                              strokeWidth: 5,
                              strokeColor: isPredicted[index] ? Colors.red : Colors.blue,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('Real', Colors.blue),
          SizedBox(width: 16),
          _buildLegendItem('Predicted', Colors.red),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  List<double> _generateLabelPositions(double minX, double maxX, List<Map<String, dynamic>> spots) {
    List<double> labelPositions = [];
    int desiredLabelCount = 5; // Adjust this number as needed

    if (spots.length <= desiredLabelCount) {
      // If we have fewer spots than desired labels, use all spots
      labelPositions = spots.map((spot) => spot['time'] as double).toList();
    } else {
      // Calculate a step to evenly distribute labels
      int step = (spots.length / desiredLabelCount).ceil();
      for (int i = 0; i < spots.length; i += step) {
        labelPositions.add(spots[i]['time'] as double);
      }
      // Always include the last spot
      if (!labelPositions.contains(spots.last['time'])) {
        labelPositions.add(spots.last['time'] as double);
      }
    }

    return labelPositions;
  }

  // Function to parse time string into seconds since midnight
  double _parseTime(String timeString) {
    List<String> parts = timeString.split(':');
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      double seconds = double.parse(parts[2]);
      return hours * 3600 + minutes * 60 + seconds;
    } else {
      print('Invalid time format: $timeString');
      return 0;
    }
  }

  // Function to format time in seconds to a readable string for tooltip
  String _formatTime(double timeInSeconds) {
    int hours = (timeInSeconds / 3600).floor();
    int minutes = ((timeInSeconds % 3600) / 60).floor();
    int seconds = (timeInSeconds % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Function to format time for x-axis labels
  String _formatTimeForAxis(double timeInSeconds) {
    int hours = (timeInSeconds / 3600).floor();
    int minutes = ((timeInSeconds % 3600) / 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}