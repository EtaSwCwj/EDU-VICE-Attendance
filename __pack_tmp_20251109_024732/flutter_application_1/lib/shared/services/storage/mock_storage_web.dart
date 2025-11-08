// Flutter Web: 로컬 파일시스템이 없으므로 assets만 사용(읽기 전용 구현)
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MockStorage {
  static Future<void> ensureSeeded() async {
    // 웹은 시드 불필요 (assets만 사용)
  }

  static Future<Map<String, dynamic>> readJson() async {
    final text = await rootBundle.loadString('assets/mock/accounts.json');
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static Future<void> writeJson(Map<String, dynamic> data) async {
    // 웹은 문서폴더가 없으니 no-op (원하면 후에 IndexedDB/localStorage로 확장)
    // ignore: avoid_print
    print('[MockStorage/Web] writeJson is a no-op');
  }

  static Future<DateTime?> lastModified() async {
    return null;
  }

  static Future<String> filePath() async {
    return 'web-assets: assets/mock/accounts.json';
  }
}
