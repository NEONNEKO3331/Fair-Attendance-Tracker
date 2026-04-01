// lib/services/participation_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ParticipationService {
  static const String _key = 'participation_history';

  // Add participation record
  static Future<void> addParticipation(String fairName, int points) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    List<String> history = prefs.getStringList(_key) ?? [];

    Map<String, dynamic> entry = {
      'fairName': fairName,
      'points': points,
      'timestamp': timestamp,
    };

    history.add(jsonEncode(entry));
    await prefs.setStringList(_key, history);
  }

  // Retrieve history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyStrings = prefs.getStringList(_key) ?? [];
    
    return historyStrings
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList(); // Most recent entries appear first
  }

  // Get total points
  static Future<int> getTotalPoints() async {
    final history = await getHistory();
    int total = 0;
    for (var item in history) {
      total += (item['points'] as int);
    }
    return total;
  }
}