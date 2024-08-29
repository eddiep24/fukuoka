// analytics.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'glucose_graph.dart';

class AnalyticsPage extends StatefulWidget {
  final String childKey;

  AnalyticsPage(this.childKey);

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late DataSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // Parse timestamps in the format HH:MM:SS
    DateTime parseTimestamp(String timestamp) {
      List<String> parts = timestamp.split(':');
      if (parts.length == 3) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);
        return DateTime(1970, 1, 1, hours, minutes, seconds);
      } else {
        // Handle invalid timestamp format
        print('Invalid timestamp format: $timestamp');
        // Return a default value or handle the error as needed
        return DateTime.now(); // Returning current time as default
      }
    }

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
                  // Update UI with the latest data
                  setState(() {
                    snapshot = event.snapshot;
                  });
                }).catchError((error) {
                  // Handle error if any
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

            // Parse timestamps and group data by date
            Map<String, List<Map<String, dynamic>>> groupedData = {};

            data.entries.forEach((entry) {
              DateTime timestamp = parseTimestamp(entry.key); // Parse timestamp using custom function
              String dateKey = '${timestamp.year}-${timestamp.month}-${timestamp.day}';

              if (!groupedData.containsKey(dateKey)) {
                groupedData[dateKey] = [];
              }

              groupedData[dateKey]!.add({'time': entry.key, 'glucose': entry.value['voltage']});
            });

            // Flatten grouped data for plotting
            groupedData.forEach((date, dataList) {
              glucoseData.addAll(dataList);
            });

            return Column(
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
                  aspectRatio: 1.5, // Adjust the aspect ratio as needed
                  child: GlucoseGraph(glucoseData),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Glucose: ${((glucoseData.last['glucose'] as double) * 800).toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        'REF: 80 - 120 mg/dl',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bluetooth Status: Connected',
                        style: TextStyle(fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Implement connect/disconnect functionality here
                        },
                        child: Text('DISCONNECT'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
