import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
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

  // Calculate coefficient of variation
  double calculateCV(double standardDeviation, double mean) {
    return (standardDeviation / mean) * 100;
  }

  // Calculate rate of change
  List<double> calculateRateOfChange(List<Map<String, dynamic>> data) {
    List<double> rates = [];
    for (int i = 1; i < data.length; i++) {
      DateTime time1 = parseTimestamp(data[i - 1]['time']);
      DateTime time2 = parseTimestamp(data[i]['time']);
      double glucose1 = data[i - 1]['glucose'];
      double glucose2 = data[i]['glucose'];
      
      double timeDiff = time2.difference(time1).inMinutes.toDouble();
      if (timeDiff > 0) {
        rates.add((glucose2 - glucose1) / timeDiff);
      }
    }
    return rates;
  }

  // Calculate time in range percentage
  double calculateTimeInRange(List<double> values, double lowThreshold, double highThreshold) {
    int inRange = values.where((v) => v >= lowThreshold && v <= highThreshold).length;
    return (inRange / values.length) * 100;
  }

  Widget buildStatCard(String title, String value, {String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
                FirebaseDatabase.instance
                    .reference()
                    .child(widget.childKey)
                    .once()
                    .then((event) {
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
        future: FirebaseDatabase.instance
            .reference()
            .child(widget.childKey)
            .once()
            .then((event) => event.snapshot),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            Map<dynamic, dynamic>? data =
                snapshot.data!.value as Map<dynamic, dynamic>?;

            if (data == null || data.isEmpty) {
              return Center(child: Text('No data available.'));
            }

            List<Map<String, dynamic>> glucoseData = [];
            List<Map<String, dynamic>> predictedData = [];

            data.entries.forEach((entry) {
              String timestampStr = entry.key.toString();
              DateTime timestamp = parseTimestamp(timestampStr);
              double voltage = (entry.value['voltage'] as num).toDouble();
              glucoseData.add({'time': timestampStr, 'glucose': voltage});
            });

            List<double> glucoseValues =
                glucoseData.map((entry) => entry['glucose'] as double).toList();

            if (glucoseValues.isNotEmpty) {
              // Calculate all statistics
              double mean = calculateMean(glucoseValues);
              double median = calculateMedian(glucoseValues);
              double stdDev = calculateStandardDeviation(glucoseValues, mean);
              double cv = calculateCV(stdDev, mean);
              List<double> rateOfChange = calculateRateOfChange(glucoseData);
              double timeInRange = calculateTimeInRange(glucoseValues, 3.9, 10.0);
              double minGlucose = glucoseValues.reduce(min);
              double maxGlucose = glucoseValues.reduce(max);
              double range = maxGlucose - minGlucose;
              
              // Calculate predictions (same as before)
              var lastValue = glucoseData.last;
              String lastTime = lastValue['time'] as String;
              List<String> timeParts = lastTime.split(':');
              int lastSeconds = int.parse(timeParts[0]) * 3600 +
                  int.parse(timeParts[1]) * 60 +
                  int.parse(timeParts[2]);

              String nextTime1 =
                  '${(lastSeconds + 60) ~/ 3600}:${((lastSeconds + 60) % 3600) ~/ 60}:${(lastSeconds + 60) % 60}';
              String nextTime2 =
                  '${(lastSeconds + 120) ~/ 3600}:${((lastSeconds + 120) % 3600) ~/ 60}:${(lastSeconds + 120) % 60}';

              predictedData
                  .add({'time': nextTime1, 'glucose': lastValue['glucose']});
              predictedData
                  .add({'time': nextTime2, 'glucose': lastValue['glucose']});

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Voltage (V) vs Time(s)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: GlucoseGraph(glucoseData, predictedData),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          buildStatCard(
                            'Current Glucose',
                            '${(glucoseData.last['glucose'] as double).toStringAsFixed(2)} mmol/L',
                            subtitle: 'Latest reading',
                          ),
                          buildStatCard(
                            'Mean Glucose',
                            '${mean.toStringAsFixed(2)} mmol/L',
                            subtitle: 'Average over period',
                          ),
                          buildStatCard(
                            'Median Glucose',
                            '${median.toStringAsFixed(2)} mmol/L',
                            subtitle: 'Middle value',
                          ),
                          buildStatCard(
                            'Standard Deviation',
                            '${stdDev.toStringAsFixed(2)} mmol/L',
                            subtitle: 'Measure of variability',
                          ),
                          buildStatCard(
                            'Coefficient of Variation',
                            '${cv.toStringAsFixed(1)}%',
                            subtitle: 'Relative variability',
                          ),
                          buildStatCard(
                            'Time in Range',
                            '${timeInRange.toStringAsFixed(1)}%',
                            subtitle: '3.9-10.0 mmol/L',
                          ),
                          buildStatCard(
                            'Range',
                            '${range.toStringAsFixed(2)} mmol/L',
                            subtitle: 'Min-Max difference',
                          ),
                          buildStatCard(
                            'Rate of Change',
                            '${(rateOfChange.isNotEmpty ? rateOfChange.last : 0).toStringAsFixed(2)} mmol/L/min',
                            subtitle: 'Current trend',
                          ),
                          buildStatCard(
                            'Minimum',
                            '${minGlucose.toStringAsFixed(2)} mmol/L',
                            subtitle: 'Lowest reading',
                          ),
                          buildStatCard(
                            'Maximum',
                            '${maxGlucose.toStringAsFixed(2)} mmol/L',
                            subtitle: 'Highest reading',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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