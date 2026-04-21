import 'package:flutter_streak/flutter_streak.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StreakService extends StreakDelegate {
  @override
  Future<Map?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("streak_data");
    if (data == null) return null;
    return jsonDecode(data);
  }

  @override
  Stream<Map?> listen() async* {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("streak_data");
    yield data != null ? jsonDecode(data) : null;
  }

  @override
  Future<void> set(Map<String, dynamic> props) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("streak_data", jsonEncode(props));
  }
}
