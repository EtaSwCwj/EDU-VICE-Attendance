// lib/features/student_assignments/student_assignment_local_notes.dart
import 'package:shared_preferences/shared_preferences.dart';

class StudentAssignmentLocalNotes {
  StudentAssignmentLocalNotes._();

  static const String _prefix = 'student_assignment_note::';

  static String _key({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$_prefix$studentUsername::$assignmentId';
  }

  /// 디버그용: 실제로 사용되는 SharedPreferences 키 문자열을 그대로 만든다.
  static String debugKey({
    required String studentUsername,
    required String assignmentId,
  }) {
    return _key(studentUsername: studentUsername, assignmentId: assignmentId);
  }

  /// 앱 재실행 후에도 유지되는 로컬 메모 로드
  static Future<String> load({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(studentUsername: studentUsername, assignmentId: assignmentId)) ?? '';
  }

  /// 앱 재실행 후에도 유지되는 로컬 메모 저장
  static Future<void> save({
    required String studentUsername,
    required String assignmentId,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(studentUsername: studentUsername, assignmentId: assignmentId),
      note,
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
