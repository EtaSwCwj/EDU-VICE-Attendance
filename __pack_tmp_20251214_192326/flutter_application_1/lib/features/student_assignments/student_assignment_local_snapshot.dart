import 'package:shared_preferences/shared_preferences.dart';

import 'student_assignment_submission_repository.dart';
import 'student_assignment_submission_repository_local.dart';

class StudentAssignmentLocalSnapshot {
  final bool submitted;
  final int? submittedAtEpochMillis; // UTC epoch millis
  final String note;
  final List<String> photoPaths;

  const StudentAssignmentLocalSnapshot({
    required this.submitted,
    required this.submittedAtEpochMillis,
    required this.note,
    required this.photoPaths,
  });
}

class StudentAssignmentLocalSnapshotLoader {
  StudentAssignmentLocalSnapshotLoader._();

  static StudentAssignmentSubmissionRepository _repo = const LocalStudentAssignmentSubmissionRepository();

  /// ✅ 외부에서 repo 기능을 쓰기 위한 "공개 getter"
  static StudentAssignmentSubmissionRepository get repo => _repo;

  /// (선택) 테스트/전환용: 외부에서 Repository 교체 가능
  static void setRepository(StudentAssignmentSubmissionRepository repo) {
    _repo = repo;
  }

  static Future<StudentAssignmentLocalSnapshot> load({
    required String studentUsername,
    required String assignmentId,
  }) {
    return _repo.loadSnapshot(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  static String debugKeySubmitted(String studentUsername, String assignmentId) {
    return 'student_assignment_submitted::$studentUsername::$assignmentId';
  }

  static String debugKeySubmittedAt(String studentUsername, String assignmentId) {
    return 'student_assignment_submitted_at::$studentUsername::$assignmentId';
  }

  static String debugKeyNote(String studentUsername, String assignmentId) {
    return 'student_assignment_note::$studentUsername::$assignmentId';
  }

  static String debugKeyAttachment(String studentUsername, String assignmentId) {
    return 'student_assignment_attachment::$studentUsername::$assignmentId';
  }

  static Future<Map<String, String>> debugKeyTypes(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, String>{};

    for (final k in keys) {
      final v = prefs.get(k);

      if (v is bool) {
        out[k] = 'bool';
      } else if (v is int) {
        out[k] = 'int';
      } else if (v is String) {
        out[k] = 'String(len=${v.length})';
      } else {
        final list = prefs.getStringList(k);
        if (list != null) {
          out[k] = 'StringList(len=${list.length})';
        } else {
          out[k] = 'null';
        }
      }
    }

    return out;
  }
}
