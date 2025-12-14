import 'package:shared_preferences/shared_preferences.dart';

class StudentAssignmentLocalAttachments {
  StudentAssignmentLocalAttachments._();

  static const String _prefix = 'student_assignment_attachment::';

  static String _key({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$_prefix$studentUsername::$assignmentId';
  }

  // ---------------------------
  // ✅ New API (multi attachments)
  // ---------------------------

  /// 로컬 첨부(사진) 경로들 로드 (StringList 우선)
  static Future<List<String>> loadPaths({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(studentUsername: studentUsername, assignmentId: assignmentId);

    // 1) 정상 케이스: StringList로 저장된 경우
    final list = prefs.getStringList(key);
    if (list != null) {
      return list.where((e) => e.trim().isNotEmpty).toList();
    }

    // 2) 레거시: String 1개로 저장된 경우
    final legacy = prefs.getString(key);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return [legacy.trim()];
    }

    return <String>[];
  }

  /// 로컬 첨부(사진) 경로들 저장 (StringList)
  static Future<void> savePaths({
    required String studentUsername,
    required String assignmentId,
    required List<String> paths,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(studentUsername: studentUsername, assignmentId: assignmentId);

    final cleaned = paths.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await prefs.setStringList(key, cleaned);
  }

  /// 단일 path 추가 (append)
  static Future<List<String>> addPath({
    required String studentUsername,
    required String assignmentId,
    required String path,
  }) async {
    final current = await loadPaths(studentUsername: studentUsername, assignmentId: assignmentId);
    final p = path.trim();
    if (p.isEmpty) return current;

    if (!current.contains(p)) {
      current.add(p);
      await savePaths(studentUsername: studentUsername, assignmentId: assignmentId, paths: current);
    }
    return current;
  }

  /// 인덱스로 제거
  static Future<List<String>> removeAt({
    required String studentUsername,
    required String assignmentId,
    required int index,
  }) async {
    final current = await loadPaths(studentUsername: studentUsername, assignmentId: assignmentId);
    if (index < 0 || index >= current.length) return current;

    current.removeAt(index);
    await savePaths(studentUsername: studentUsername, assignmentId: assignmentId, paths: current);
    return current;
  }

  // ---------------------------------------
  // ✅ Legacy API (기존 호출부 깨짐 방지용)
  // ---------------------------------------

  /// (레거시) 단일 첨부 경로 로드
  /// - 내부적으로는 loadPaths()를 호출하고 첫 번째만 반환
  static Future<String?> loadPath({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final list = await loadPaths(studentUsername: studentUsername, assignmentId: assignmentId);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// (레거시) 단일 첨부 경로 저장
  /// - 내부적으로는 "리스트 1개"로 savePaths()
  static Future<void> savePath({
    required String studentUsername,
    required String assignmentId,
    required String path,
  }) async {
    await savePaths(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
      paths: [path],
    );
  }

  static Future<void> clear({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(studentUsername: studentUsername, assignmentId: assignmentId));
  }
}
