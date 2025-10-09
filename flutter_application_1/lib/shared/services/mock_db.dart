import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import '../models/account.dart';
import '../models/academy.dart';
import 'mock_storage.dart'; // ← 문서 폴더 경로/시드용

class MockDb {
  static Future<String> _readJsonText() async {
    // 1) 문서 폴더에 accounts.json 있으면 그걸 우선
    final path = await MockStorage.filePath();
    final f = File(path);
    if (await f.exists()) {
      return await f.readAsString();
    }
    // 2) 없으면 assets로 fallback
    return await rootBundle.loadString('assets/mock/accounts.json');
  }

  static Future<Map<String, dynamic>> _loadRaw() async {
    final text = await _readJsonText();
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
