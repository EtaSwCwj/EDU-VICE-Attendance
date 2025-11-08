import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

import '../models/account.dart';
import '../models/academy.dart';

// 플랫폼별 MockStorage 구현 선택
import 'storage/mock_storage_io.dart'
  if (dart.library.html) 'storage/mock_storage_web.dart' as storage;

class MockDb {
  static Future<String> _readJsonText() async {
    if (kIsWeb) {
      // 웹은 assets만
      return await rootBundle.loadString('assets/mock/accounts.json');
    }
    // 모바일/데스크톱: 문서폴더 우선
    try {
      final path = await storage.MockStorage.filePath();
      final f = File(path);
      if (await f.exists()) {
        return await f.readAsString();
      }
    } catch (_) {}
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
