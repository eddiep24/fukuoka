import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'glucose_graph.dart';

class AnalyticsPage extends StatelessWidget {
  final String childKey;

  AnalyticsPage(this.childKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(childKey),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                // Implement refresh functionality here
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<DataSnapshot>(
        future: FirebaseDatabase.instance.reference().child(childKey).once().then((event) => event.snapshot),
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
            List<Map<String, dynamic>> glucoseData = data.entries
                .where((entry) => entry.key.startsWith('00:')) // Assuming time keys start with '00:'
                .map((entry) => {'time': entry.key, 'glucose': entry.value['voltage']})
                .toList();

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
