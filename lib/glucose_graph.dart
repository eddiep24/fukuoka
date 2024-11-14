import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class GlucoseGraph extends StatelessWidget {
  final List<Map<String, dynamic>> unformattedSpots;
  final List<Map<String, dynamic>> predictedData;

  GlucoseGraph(this.unformattedSpots, this.predictedData);

  @override
  Widget build(BuildContext context) {
    // Process and sort data points chronologically
    List<GlucoseReading> actualReadings = unformattedSpots.map((spot) {
      DateTime time = _parseDateTime(spot['time'].toString());
      return GlucoseReading(
        time: time,
        glucose: double.parse(spot['glucose'].toString()),
        isPredicted: false,
      );
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    List<GlucoseReading> predictedReadings = predictedData.map((spot) {
      DateTime time = _parseDateTime(spot['time'].toString());
      return GlucoseReading(
        time: time,
        glucose: double.parse(spot['glucose'].toString()),
        isPredicted: true,
      );
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    // Add last actual reading to predicted data for continuity if both lists have data
    if (actualReadings.isNotEmpty && predictedReadings.isNotEmpty) {
      predictedReadings.insert(0, actualReadings.last.copyWith(isPredicted: true));
    }

    // Set default Y-axis range for empty or single-point graphs
    double minY = 0;
    double maxY = 20; // Default max for glucose readings
    double buffer = 2;

    // Calculate statistics for Y-axis range if we have data
    if (actualReadings.isNotEmpty) {
      List<double> allGlucose = actualReadings.map((r) => r.glucose).toList();
      double mean = allGlucose.reduce((a, b) => a + b) / allGlucose.length;
      double stddev = allGlucose.length > 1 
          ? math.sqrt(
              allGlucose.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / allGlucose.length
            )
          : 2.0; // Default standard deviation for single point

      minY = (allGlucose.reduce(math.min) - stddev).clamp(0, double.infinity);
      maxY = allGlucose.reduce(math.max) + stddev;
      buffer = (maxY - minY) * 0.1;
    }
    
    return AspectRatio(
      aspectRatio: 1.70,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SfCartesianChart(
            legend: Legend(
              isVisible: true,
              position: LegendPosition.top,
              orientation: LegendItemOrientation.horizontal,
              overflowMode: LegendItemOverflowMode.wrap,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (data, point, series, pointIndex, seriesIndex) {
                GlucoseReading reading = data as GlucoseReading;
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reading.isPredicted)
                        Text(
                          'Predicted',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      Text(
                        DateFormat('HH:mm').format(reading.time),
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '${reading.glucose.toStringAsFixed(1)} mmol/L',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
            zoomPanBehavior: ZoomPanBehavior(
              enablePinching: true,
              enableDoubleTapZooming: true,
              enablePanning: true,
              zoomMode: ZoomMode.x,
            ),
            primaryXAxis: DateTimeAxis(
              dateFormat: DateFormat.Hm(),
              intervalType: DateTimeIntervalType.hours,
              majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[300]),
              title: AxisTitle(text: 'Time'),
            ),
            primaryYAxis: NumericAxis(
              minimum: minY - buffer,
              maximum: maxY + buffer,
              interval: (maxY - minY) / 6,
              majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey[300]),
              title: AxisTitle(text: 'Glucose (mmol/L)'),
              numberFormat: NumberFormat('#0.0'),
            ),
            series: <CartesianSeries>[
              // Actual readings
              LineSeries<GlucoseReading, DateTime>(
                name: 'Actual',
                dataSource: actualReadings,
                xValueMapper: (GlucoseReading reading, _) => reading.time,
                yValueMapper: (GlucoseReading reading, _) => reading.glucose,
                color: Colors.blue,
                width: 3,
                opacity: 0.8,
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  height: 8,
                  width: 8,
                  shape: DataMarkerType.circle,
                ),
                enableTooltip: true,
              ),
              // Predicted readings
              LineSeries<GlucoseReading, DateTime>(
                name: 'Predicted',
                dataSource: predictedReadings,
                xValueMapper: (GlucoseReading reading, _) => reading.time,
                yValueMapper: (GlucoseReading reading, _) => reading.glucose,
                color: Colors.red,
                width: 3,
                opacity: 0.8,
                dashArray: [5, 5],
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  height: 8,
                  width: 8,
                  shape: DataMarkerType.diamond,
                ),
                enableTooltip: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _parseDateTime(String timeString) {
    List<String> parts = timeString.split(':');
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = double.parse(parts[2]).round();
      
      // Create a DateTime for today with the specified time
      DateTime now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        hours,
        minutes,
        seconds,
      );
    } else {
      print('Invalid time format: $timeString');
      return DateTime.now();
    }
  }
}

class GlucoseReading {
  final DateTime time;
  final double glucose;
  final bool isPredicted;

  GlucoseReading({
    required this.time,
    required this.glucose,
    required this.isPredicted,
  });

  GlucoseReading copyWith({
    DateTime? time,
    double? glucose,
    bool? isPredicted,
  }) {
    return GlucoseReading(
      time: time ?? this.time,
      glucose: glucose ?? this.glucose,
      isPredicted: isPredicted ?? this.isPredicted,
    );
  }
}