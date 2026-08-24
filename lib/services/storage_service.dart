import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/routine_preset.dart';
import '../models/day_record.dart';

class StorageService {
  static const String _presetsKey = 'routine_presets';
  static const String _historyKey = 'routine_history';

  // Save Routines
  static Future<void> savePresets(List<RoutinePreset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(presets.map((p) => p.toJson()).toList());
    await prefs.setString(_presetsKey, encoded);
  }

  // Load Routines
  static Future<List<RoutinePreset>?> loadPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_presetsKey);
    if (rawJson == null) return null;

    final List decoded = jsonDecode(rawJson);
    return decoded.map((item) => RoutinePreset.fromJson(item)).toList();
  }

  // Save History Map
  static Future<void> saveHistory(Map<DateTime, DayRecord> history) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};
    history.forEach((key, value) {
      jsonMap[key.toIso8601String()] = value.toJson();
    });
    await prefs.setString(_historyKey, jsonEncode(jsonMap));
  }

  // Load History Map
  static Future<Map<DateTime, DayRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_historyKey);
    if (rawJson == null) return {};

    final Map<String, dynamic> decoded = jsonDecode(rawJson);
    final Map<DateTime, DayRecord> resultMap = {};

    decoded.forEach((key, value) {
      final parsedDate = DateTime.parse(key);
      // Normalize to UTC start-of-day so keys always match DateTime.utc(Y, M, D)
      final cleanUtcDate = DateTime.utc(parsedDate.year, parsedDate.month, parsedDate.day);
      resultMap[cleanUtcDate] = DayRecord.fromJson(value);
    });

    return resultMap;
  }



    static const String _lastCheckedKey = 'last_checked_date';

  static Future<void> saveLastCheckedDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastCheckedKey, date.toIso8601String());
  }

  static Future<DateTime?> loadLastCheckedDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastCheckedKey);
    if (raw == null) return null;
    return DateTime.parse(raw);
  }



    static const String _themeModeKey = 'theme_mode';
  static const String _targetPercentageKey = 'target_percentage';

  static Future<void> saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeModeKey, isDark);
  }

  static Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeModeKey) ?? false;
  }

  static Future<void> saveTargetPercentage(double target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_targetPercentageKey, target);
  }

  static Future<double> loadTargetPercentage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_targetPercentageKey) ?? 80.0;
  }
}