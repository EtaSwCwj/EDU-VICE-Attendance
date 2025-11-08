// lib/data/local/sembast_database.dart
//
// Sembast 데이터베이스 핸들러 (싱글턴)
// - 웹: IndexedDB (sembast_web)
// - 모바일/데스크톱: 파일 기반 (sembast_io)
// - 앱 전역에서 동일한 Database 인스턴스를 공유

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart';

// 웹/모바일 분기용 팩토리
import 'package:sembast_web/sembast_web.dart' show databaseFactoryWeb;
import 'package:sembast/sembast_io.dart' show databaseFactoryIo;

// 모바일/데스크톱에서만 사용 (웹에서는 호출되지 않음)
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  static const String _dbFileName = 'edu_vice_attendance.db';

  Database? _db;

  /// 사용 시 항상 이 getter로 Database 인스턴스를 받아가세요.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      // 웹: IndexedDB로 오픈
      final dbFactory = databaseFactoryWeb;
      return dbFactory.openDatabase(_dbFileName);
    } else {
      // 모바일/데스크톱: 앱 문서 폴더 아래에 파일 DB 생성
      final dir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dir.path, _dbFileName);
      final dbFactory = databaseFactoryIo;
      return dbFactory.openDatabase(dbPath);
    }
  }

  /// 필요 시 수동으로 DB를 닫고 다시 열 수 있도록 제공
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
