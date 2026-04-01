// lib/services/participation_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ParticipationService {
  static const String _key = 'participation_history';

  // ✅ Add participation (prevent duplicate)
  static Future<bool> addParticipation(String fairName, int points) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    List<String> history = prefs.getStringList(_key) ?? [];

    // Check for duplicate
    for (String item in history) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      if (map['fairName'] == fairName) {
        return false; // Already joined
      }
    }

    Map<String, dynamic> entry = {
      'fairName': fairName,
      'points': points,
      'timestamp': timestamp,
    };

    history.add(jsonEncode(entry));
    await prefs.setStringList(_key, history);
    return true;
  }

  // ✅ Get history
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = prefs.getStringList(_key) ?? [];
    return data
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList()
        .reversed
        .toList();
  }

  // ✅ FIXED: Get total points
  static Future<int> getTotalPoints() async {
    final history = await getHistory();        // ← 加上 await
    int total = 0;
    for (var item in history) {
      total += (item['points'] as int);
    }
    return total;
  }

  // ✅ Delete record
  static Future<int> deleteParticipation(int index) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    if (index < 0 || index >= history.length) return 0;

    final deletedItem = jsonDecode(history[index]) as Map<String, dynamic>;
    final deletedPoints = deletedItem['points'] as int;

    history.removeAt(index);
    await prefs.setStringList(_key, history);

    return deletedPoints;
  }
}