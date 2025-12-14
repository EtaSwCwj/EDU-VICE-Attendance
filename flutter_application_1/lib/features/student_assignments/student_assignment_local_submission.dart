import 'package:shared_preferences/shared_preferences.dart';

class StudentAssignmentLocalSubmission {
  StudentAssignmentLocalSubmission._();

  static const String _prefixSubmitted = 'student_assignment_submitted::';
  static const String _prefixSubmittedAt = 'student_assignment_submitted_at::';

  static String _keySubmitted({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$_prefixSubmitted$studentUsername::$assignmentId';
  }

  static String _keySubmittedAt({
    required String studentUsername,
    required String assignmentId,
  }) {
    return '$_prefixSubmittedAt$studentUsername::$assignmentId';
  }

  static Future<bool> isSubmitted({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySubmitted(studentUsername: studentUsername, assignmentId: assignmentId)) ?? false;
  }

  /// epochMillis (UTC)
  static Future<int?> submittedAtEpochMillis({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_keySubmittedAt(studentUsername: studentUsername, assignmentId: assignmentId));
    return v;
  }

  static Future<void> submit({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySubmitted(studentUsername: studentUsername, assignmentId: assignmentId), true);
    await prefs.setInt(
      _keySubmittedAt(studentUsername: studentUsername, assignmentId: assignmentId),
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  static Future<void> unsubmit({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySubmitted(studentUsername: studentUsername, assignmentId: assignmentId), false);
    await prefs.remove(_keySubmittedAt(studentUsername: studentUsername, assignmentId: assignmentId));
  }
}
