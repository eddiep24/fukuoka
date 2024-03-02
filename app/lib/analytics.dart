import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  final String pigName;

  const AnalyticsPage({Key? key, required this.pigName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$pigName Analytics'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Analytics for $pigName',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(height: 20.0),
              // Add your analytics widgets here
            ],
          ),
        ),
      ),
    );
  }
}
