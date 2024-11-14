import 'dart:math';

class GlucosePredictionService {
  // Parse timestamps in the format HH:MM:SS
  static DateTime parseTimestamp(String timestamp) {
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

  // Calculate predictions based on data points
  static List<Map<String, dynamic>> calculatePredictions(List<Map<String, dynamic>> glucoseData) {
    if (glucoseData.length <= 2) {
      return []; // Return empty list if we don't have enough data points
    }

    List<Map<String, dynamic>> predictedData = [];
    var lastValue = glucoseData.last;
    String lastTime = lastValue['time'] as String;
    List<String> timeParts = lastTime.split(':');
    int lastSeconds = int.parse(timeParts[0]) * 3600 +
        int.parse(timeParts[1]) * 60 +
        int.parse(timeParts[2]);

    // Calculate the average time difference between points
    List<int> timeDiffs = [];
    for (int i = 1; i < glucoseData.length; i++) {
      DateTime time1 = parseTimestamp(glucoseData[i - 1]['time']);
      DateTime time2 = parseTimestamp(glucoseData[i]['time']);
      timeDiffs.add(time2.difference(time1).inSeconds);
    }
    int avgTimeDiff = (timeDiffs.reduce((a, b) => a + b) / timeDiffs.length).round();

    // Calculate the average rate of change for the last few points
    List<double> recentRates = [];
    int pointsToConsider = min(5, glucoseData.length - 1); // Consider up to last 5 points
    for (int i = glucoseData.length - pointsToConsider; i < glucoseData.length; i++) {
      double glucose1 = glucoseData[i - 1]['glucose'];
      double glucose2 = glucoseData[i]['glucose'];
      DateTime time1 = parseTimestamp(glucoseData[i - 1]['time']);
      DateTime time2 = parseTimestamp(glucoseData[i]['time']);
      double timeDiff = time2.difference(time1).inSeconds.toDouble();
      if (timeDiff > 0) {
        recentRates.add((glucose2 - glucose1) / timeDiff);
      }
    }
    double averageRate = recentRates.isEmpty ? 0 : 
        recentRates.reduce((a, b) => a + b) / recentRates.length;

    // Generate predictions based on the number of data points
    int numPredictions = (glucoseData.length / 3).round(); // One prediction for every 3 data points
    numPredictions = min(numPredictions, 5); // Cap at 5 predictions
    
    for (int i = 1; i <= numPredictions; i++) {
      int futureSeconds = lastSeconds + (avgTimeDiff * i);
      String nextTime =
          '${(futureSeconds) ~/ 3600}:${((futureSeconds) % 3600) ~/ 60}:${(futureSeconds) % 60}';
      
      // Predict future glucose value based on the average rate of change
      double predictedGlucose = lastValue['glucose'] + (averageRate * avgTimeDiff * i);
      
      predictedData.add({
        'time': nextTime,
        'glucose': predictedGlucose,
      });
    }

    return predictedData;
  }
}