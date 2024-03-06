import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatelessWidget {
  final String pigName;

  const AnalyticsPage({Key? key, required this.pigName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('$pigName Analytics'),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('Data').doc(pigName).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Error: ${snapshot.error}'),
                  ),
                );
              } else if (!snapshot.hasData) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('No data available for $pigName.'),
                  ),
                );
              } else {
                var data = snapshot.data!.data() as Map<String, dynamic>?;

                if (data != null && data.isNotEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        var entry = data.entries.toList()[index];
                        return ListTile(
                          title: Text('${entry.key}: ${entry.value}'),
                        );
                      },
                      childCount: data.length,
                    ),
                  );
                } else {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text('No data available for $pigName.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
