import 'package:shared_preferences/shared_preferences.dart';

import 'student_assignment_local_keys.dart';
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

  static String debugKeySubmitted({
    required String studentUsername,
    required String assignmentId,
  }) {
    return StudentAssignmentLocalKeys.submitted(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  static String debugKeySubmittedAt({
    required String studentUsername,
    required String assignmentId,
  }) {
    return StudentAssignmentLocalKeys.submittedAt(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  static String debugKeyNote({
    required String studentUsername,
    required String assignmentId,
  }) {
    return StudentAssignmentLocalKeys.note(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  static String debugKeyAttachment({
    required String studentUsername,
    required String assignmentId,
  }) {
    return StudentAssignmentLocalKeys.attachment(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  static Future<Map<String, String>> debugKeyTypes(List<String> keys) async {
  final prefs = await SharedPreferences.getInstance();
  final out = <String, String>{};

  for (final k in keys) {
    final v = prefs.get(k);

    if (v is bool) {
      out[k] = 'bool';
      continue;
    }
    if (v is int) {
      out[k] = 'int';
      continue;
    }
    if (v is String) {
      out[k] = 'String(len=${v.length})';
      continue;
    }

    final list = prefs.getStringList(k);
    if (list != null) {
      out[k] = 'StringList(len=${list.length})';
      continue;
    }

    // 저장된 값이 없을 때(null)도 "의미상 기본값"이 있는 키들은 디버그에서 기본값을 보여준다.
    if (k.startsWith(StudentAssignmentLocalKeys.submittedPrefix)) {
      out[k] = 'bool(default:false)';
    } else if (k.startsWith(StudentAssignmentLocalKeys.notePrefix)) {
      out[k] = 'String(len=0)';
    } else if (k.startsWith(StudentAssignmentLocalKeys.attachmentPrefix)) {
      out[k] = 'StringList(len=0)';
    } else {
      // submitted_at 등: 기본값이 없는 키는 null 그대로 표시
      out[k] = 'null';
    }
  }

  return out;
}
}
