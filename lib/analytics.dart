import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'glucose_graph.dart';
import 'glucose_prediction_service.dart';


class AnalyticsPage extends StatefulWidget {
  final String childKey;

  AnalyticsPage(this.childKey);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late DataSnapshot snapshot;

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

  double calculateCV(double standardDeviation, double mean) {
    return (standardDeviation / mean) * 100;
  }

  // Calculate rate of change
  List<double> calculateRateOfChange(List<Map<String, dynamic>> data) {
    List<double> rates = [];
    for (int i = 1; i < data.length; i++) {
      DateTime time1 = GlucosePredictionService.parseTimestamp(data[i - 1]['time']);
      DateTime time2 = GlucosePredictionService.parseTimestamp(data[i]['time']);
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
            
            data.entries.forEach((entry) {
              String timestampStr = entry.key.toString();
              DateTime timestamp = GlucosePredictionService.parseTimestamp(timestampStr);
              double voltage = (entry.value['voltage'] as num).toDouble();
              glucoseData.add({'time': timestampStr, 'glucose': voltage});
            });

            // Sort glucoseData by time
            glucoseData.sort((a, b) => 
              GlucosePredictionService.parseTimestamp(a['time'])
                .compareTo(GlucosePredictionService.parseTimestamp(b['time'])));

            // Calculate predictions using the service
            List<Map<String, dynamic>> predictedData = 
                GlucosePredictionService.calculatePredictions(glucoseData);


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