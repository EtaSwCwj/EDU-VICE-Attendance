// lib/shared/services/kv_store.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// 간단 Key-Value 로컬 스토어 (SharedPreferences 래퍼)
class KvStore {
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
