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

  /// 로컬 첨부(사진) 경로 로드
  static Future<String?> loadPath({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key(studentUsername: studentUsername, assignmentId: assignmentId));
    if (v == null || v.trim().isEmpty) return null;
    return v;
  }

  /// 로컬 첨부(사진) 경로 저장
  static Future<void> savePath({
    required String studentUsername,
    required String assignmentId,
    required String path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(studentUsername: studentUsername, assignmentId: assignmentId),
      path,
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
