import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import FirebaseFirestore
import 'firebase_options.dart';
import 'analytics.dart'; // Import the AnalyticsPage class

class MenuPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    FirebaseFirestore db = FirebaseFirestore.instance; // Declare and initialize db variable
    
    // Dummy menu items
    List<String> menuItems = [
      'Pig 1',
      'Pig 2',
      'Pig 3',
      'Pig 4',
      'Pig 5',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Page'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 10.0),
              Expanded(
                child: ListView.builder(
                  itemCount: menuItems.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      title: Text(menuItems[index]),
                      onTap: () {
                        // Navigate to the analytics page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AnalyticsPage(pigName: menuItems[index])),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
