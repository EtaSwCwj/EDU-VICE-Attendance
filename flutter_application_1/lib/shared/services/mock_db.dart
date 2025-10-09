import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/account.dart';
import '../models/academy.dart';

class MockDb {
  static Future<Map<String, dynamic>> _loadRaw() async {
    final text = await rootBundle.loadString('assets/mock/accounts.json');
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static Future<List<Account>> loadAccounts() async {
    final raw = await _loadRaw();
    final list = (raw['accounts'] as List? ?? []);
    return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Academy>> loadAcademies() async {
    final raw = await _loadRaw();
    final list = (raw['academies'] as List? ?? []);
    return list.map((e) => Academy.fromJson(e as Map<String, dynamic>)).toList();
  }
}
