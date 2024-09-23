import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math'; // For standard deviation calculation
import 'glucose_graph.dart';

class AnalyticsPage extends StatefulWidget {
  final String childKey;

  AnalyticsPage(this.childKey);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late DataSnapshot snapshot;

  // Parse timestamps in the format HH:MM:SS
  DateTime parseTimestamp(String timestamp) {
    List<String> parts = timestamp.split(':');
    if (parts.length == 3) {
      int hours = int.parse(parts[0]);
      int minutes = int.parse(parts[1]);
      int seconds = int.parse(parts[2]);
      return DateTime(1970, 1, 1, hours, minutes, seconds);
    } else {
      print('Invalid timestamp format: $timestamp');
      return DateTime.now();
    }
  }

  // Calculate mean of glucose values
  double calculateMean(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  // Calculate median of glucose values
  double calculateMedian(List<double> values) {
    List<double> sortedValues = List.from(values)..sort();
    int middle = sortedValues.length ~/ 2;

    if (sortedValues.length % 2 == 1) {
      return sortedValues[middle];
    } else {
      return (sortedValues[middle - 1] + sortedValues[middle]) / 2.0;
    }
  }

  // Calculate standard deviation
  double calculateStandardDeviation(List<double> values, double mean) {
    double sumOfSquaredDifferences = values
        .map((value) => pow(value - mean, 2).toDouble())
        .reduce((a, b) => a + b);

    return sqrt(sumOfSquaredDifferences / values.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.childKey),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // Fetch latest data from Firebase Database
                FirebaseDatabase.instance.reference().child(widget.childKey).once().then((event) {
                  setState(() {
                    snapshot = event.snapshot;
                  });
                }).catchError((error) {
                  print("Error fetching data: $error");
                });
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.reference().child(widget.childKey).once().then((event) => event.snapshot),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            Map<dynamic, dynamic>? data = snapshot.data!.value as Map<dynamic, dynamic>?;

            if (data == null || data.isEmpty) {
              return Center(
                child: Text('No data available.'),
              );
            }

            // Extract glucose data from your fetched data
            List<Map<String, dynamic>> glucoseData = [];
            List<Map<String, dynamic>> predictedData = [];

            // Parse timestamps and group data by date
            data.entries.forEach((entry) {
              String timestampStr = entry.key.toString(); // Convert key to String
              DateTime timestamp = parseTimestamp(timestampStr);
              glucoseData.add({'time': timestampStr, 'glucose': entry.value['voltage']});
            });

            // Extract only glucose values for analysis
            List<double> glucoseValues = glucoseData.map((entry) => entry['glucose'] as double).toList();

            if (glucoseValues.isNotEmpty) {
              // Calculate statistics
              double mean = calculateMean(glucoseValues);
              double median = calculateMedian(glucoseValues);
              double stdDev = calculateStandardDeviation(glucoseValues, mean);
              double minGlucose = glucoseValues.reduce(min);
              double maxGlucose = glucoseValues.reduce(max);
              double range = maxGlucose - minGlucose;

              // Get the last value from glucoseData
              var lastValue = glucoseData.last;

              // Add predictions
              String lastTime = lastValue['time'] as String;
              List<String> timeParts = lastTime.split(':');
              int lastSeconds = int.parse(timeParts[0]) * 3600 + int.parse(timeParts[1]) * 60 + int.parse(timeParts[2]);
              
              String nextTime1 = '${(lastSeconds + 60) ~/ 3600}:${((lastSeconds + 60) % 3600) ~/ 60}:${(lastSeconds + 60) % 60}';
              String nextTime2 = '${(lastSeconds + 120) ~/ 3600}:${((lastSeconds + 120) % 3600) ~/ 60}:${(lastSeconds + 120) % 60}';

              predictedData.add({'time': nextTime1, 'glucose': lastValue['glucose']});
              predictedData.add({'time': nextTime2, 'glucose': lastValue['glucose']});

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Voltage (V) vs Time(s)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  AspectRatio(
                    aspectRatio: 1.5,
                    child: GlucoseGraph(glucoseData, predictedData),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Glucose: ${((glucoseData.last['glucose'] as double) * 800).toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                        Text('Mean: ${mean.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                        Text('Median: ${median.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                        Text('Range: ${range.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                        Text('Standard Deviation: ${stdDev.toStringAsFixed(2)}', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Center(child: Text('No glucose data available.'));
            }
          }
        },
      ),
    );
  }
}