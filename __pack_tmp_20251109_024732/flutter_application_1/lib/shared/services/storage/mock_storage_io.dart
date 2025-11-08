// 앱 문서 폴더에 mock JSON 배치/관리 (모바일/데스크톱: dart:io 사용)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class MockStorage {
  static const String _fileName = 'accounts.json';

  static Future<String> _docPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<File> _jsonFile() async {
    final path = await _docPath();
    return File('$path/$_fileName');
  }

  static Future<void> ensureSeeded() async {
    final f = await _jsonFile();
    if (!await f.exists()) {
      final bytes = await rootBundle.load('assets/mock/accounts.json');
      final content = utf8.decode(bytes.buffer.asUint8List());
      await f.writeAsString(content);
      // ignore: avoid_print
      print('[MockStorage/IO] seeded accounts.json');
    }
  }

  static Future<Map<String, dynamic>> readJson() async {
    final f = await _jsonFile();
    final text = await f.readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  static Future<void> writeJson(Map<String, dynamic> data) async {
    final f = await _jsonFile();
    final text = const JsonEncoder.withIndent('  ').convert(data);
    await f.writeAsString(text);
    // ignore: avoid_print
    print('[MockStorage/IO] saved accounts.json');
  }

  static Future<DateTime?> lastModified() async {
    final f = await _jsonFile();
    return (await f.exists()) ? (await f.stat()).modified : null;
  }

  static Future<String> filePath() async {
    final f = await _jsonFile();
    return f.path;
  }
}
