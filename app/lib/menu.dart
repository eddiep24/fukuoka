import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'analytics.dart';
import 'manage_users.dart'; 


class MenuPage extends StatelessWidget {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Color(0xe7e2bf), // Cream color
      appBar: AppBar(
        title: Text('Menu Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              // Navigate to the manage users page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageUsersPage()),
              );
            },
          ),
        ],
      ),
      body: _buildChildrenList(context),
    );
  }

  Widget _buildChildrenList(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: _dbRef.once().then((event) => event.snapshot),
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

          List<String> childrenKeys = data.keys.cast<String>().toList();

          return ListView.builder(
            itemCount: childrenKeys.length,
            itemBuilder: (context, index) {
              final childKey = childrenKeys[index];
              
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                // color: Color(0xFFD2B48C), // Light brown color
                child: ListTile(
                  title: Text(
                    childKey,
                    style: TextStyle(
                      // color: Colors.white, // Text color for contrast
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    // Navigate to the page to display all data under this child
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnalyticsPage(childKey)),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
