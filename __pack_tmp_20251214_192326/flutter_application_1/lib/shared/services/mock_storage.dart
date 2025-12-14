import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class MockStorage {
  static const String _fileName = 'accounts.json';

  // 1) 앱 문서 폴더 경로
  static Future<String> _docPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  // 2) JSON 파일 핸들
  static Future<File> _jsonFile() async {
    final path = await _docPath();
    return File('$path/$_fileName');
  }

  // 3) 최초 1회: assets 내용으로 시드
  static Future<void> ensureSeeded() async {
    final f = await _jsonFile();
    final exists = await f.exists();
    if (!exists) {
      // assets에서 읽어와 문서 폴더에 복사
      final bytes = await rootBundle.load('assets/mock/accounts.json');
      final content = utf8.decode(bytes.buffer.asUint8List());
      await f.writeAsString(content);
      // 로그
      // ignore: avoid_print
      print('[MockStorage] seeded accounts.json to app documents.');
    } else {
      // ignore: avoid_print
      print('[MockStorage] accounts.json already exists.');
    }
  }

  // 4) 읽기
  static Future<Map<String, dynamic>> readJson() async {
    final f = await _jsonFile();
    final text = await f.readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  // 5) 저장
  static Future<void> writeJson(Map<String, dynamic> data) async {
    final f = await _jsonFile();
    final text = const JsonEncoder.withIndent('  ').convert(data);
    await f.writeAsString(text);
    // ignore: avoid_print
    print('[MockStorage] accounts.json saved.');
  }

  // 6) 외부 교체를 대비한 최근 수정 시각(디버그용)
  static Future<DateTime?> lastModified() async {
    final f = await _jsonFile();
    if (await f.exists()) {
      return (await f.stat()).modified;
    }
    return null;
  }

  // 7) 파일 경로(ADB push/pull용)
  static Future<String> filePath() async {
    final f = await _jsonFile();
    return f.path;
  }
}
