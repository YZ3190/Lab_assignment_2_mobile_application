import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/fair.dart';

class ParticipationStorage {
  static const String _key = 'fair_participation_history';

  Future<void> recordParticipation(Fair fair) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    final entry = {
      'fairName': fair.name,
      'points': fair.points,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.add(jsonEncode(entry));
    await prefs.setStringList(_key, history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyStr = prefs.getStringList(_key) ?? [];
    return historyStr
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  Future<int> getTotalPoints() async {
    final history = await getHistory();
    return history.fold<int>(0, (sum, item) => sum + (item['points'] as int));
  }

  String formatTimestamp(String isoString) {
    final date = DateTime.parse(isoString);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}