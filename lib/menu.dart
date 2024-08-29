import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'analytics.dart';
import 'manage_users.dart'; 

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();
  late Future<DataSnapshot> _dataSnapshotFuture;

  @override
  void initState() {
    super.initState();
    _dataSnapshotFuture = _dbRef.once().then((event) => event.snapshot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageUsersPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.blue, // Customize the color of the refresh indicator
        notificationPredicate: (notification) {
          // Control when to trigger the refresh indicator
          return notification.metrics.pixels >= 0;
        },
        displacement: 20.0, // Limit the displacement of the refresh indicator
        onRefresh: _refreshData,
        child: _buildChildrenList(context),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _dataSnapshotFuture = _dbRef.once().then((event) => event.snapshot);
    });
  }

  Widget _buildChildrenList(BuildContext context) {
    return FutureBuilder<DataSnapshot>(
      future: _dataSnapshotFuture,
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
            physics: AlwaysScrollableScrollPhysics(), // Ensure the list is always scrollable
            itemCount: childrenKeys.length,
            itemBuilder: (context, index) {
              final childKey = childrenKeys[index];
              
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    childKey,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
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
