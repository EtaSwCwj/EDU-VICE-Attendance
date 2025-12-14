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

  /// 디버그용: 실제로 사용되는 SharedPreferences 키 문자열
  static String debugKey({
    required String studentUsername,
    required String assignmentId,
  }) {
    return _key(studentUsername: studentUsername, assignmentId: assignmentId);
  }

  // ---------------------------
  // ✅ Canonical API (StringList)
  // ---------------------------

  /// 로컬 첨부(사진) 경로들 로드
  /// - 우선순위: StringList(정상) → String(레거시)
  /// - 레거시 String이 있으면: 자동으로 StringList로 마이그레이션한다.
  static Future<List<String>> loadPaths({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(studentUsername: studentUsername, assignmentId: assignmentId);

    // 1) 정상 케이스: StringList
    final list = prefs.getStringList(key);
    if (list != null) {
      return _uniqueNonEmpty(list);
    }

    // 2) 레거시: String 1개
    final legacy = prefs.getString(key);
    if (legacy != null) {
      final p = legacy.trim();
      if (p.isNotEmpty) {
        // ✅ 마이그레이션: String -> StringList
        await prefs.setStringList(key, <String>[p]);
        await prefs.remove(key); // 동일 키에 남아있을 가능성 제거(안전망)
        // (SharedPreferences 구현상 setStringList가 setString을 덮어쓰지만,
        //  여기서는 의도 명확하게 remove도 해둔다.)
        return <String>[p];
      }
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

    final cleaned = _uniqueNonEmpty(paths);
    await prefs.setStringList(key, cleaned);
  }

  /// 단일 path 추가 (append, 중복 방지)
  static Future<List<String>> addPath({
    required String studentUsername,
    required String assignmentId,
    required String path,
  }) async {
    final current = await loadPaths(studentUsername: studentUsername, assignmentId: assignmentId);
    final p = path.trim();
    if (p.isEmpty) return current;

    if (!current.contains(p)) {
      final next = <String>[...current, p];
      await savePaths(studentUsername: studentUsername, assignmentId: assignmentId, paths: next);
      return next;
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

    final next = <String>[...current]..removeAt(index);
    await savePaths(studentUsername: studentUsername, assignmentId: assignmentId, paths: next);
    return next;
  }

  static Future<void> clear({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(studentUsername: studentUsername, assignmentId: assignmentId));
  }

  // ---------------------------------------
  // ✅ Legacy API (기존 호출부 호환용)
  // ---------------------------------------

  /// (레거시) 단일 첨부 경로 로드: 첫 번째만 반환
  static Future<String?> loadPath({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final list = await loadPaths(studentUsername: studentUsername, assignmentId: assignmentId);
    if (list.isEmpty) return null;
    return list.first;
  }

  /// (레거시) 단일 첨부 경로 저장: 리스트 1개로 저장
  static Future<void> savePath({
    required String studentUsername,
    required String assignmentId,
    required String path,
  }) async {
    final p = path.trim();
    await savePaths(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
      paths: p.isEmpty ? <String>[] : <String>[p],
    );
  }

  static List<String> _uniqueNonEmpty(List<String> src) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in src) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (seen.add(p)) out.add(p);
    }
    return out;
  }
}
