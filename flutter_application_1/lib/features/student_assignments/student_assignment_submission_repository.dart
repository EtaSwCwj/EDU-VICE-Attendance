import 'student_assignment_local_snapshot.dart';

/// 26단계 목표:
/// - "로컬 저장/조회"를 하나의 인터페이스 뒤로 숨겨서,
///   나중에 서버 구현을 붙여도 UI/호출부 변경을 최소화한다.
/// - 지금은 LocalFirst 그대로. 서버 업로드/공유는 아직 안 함.
abstract interface class StudentAssignmentSubmissionRepository {
  Future<StudentAssignmentLocalSnapshot> loadSnapshot({
    required String studentUsername,
    required String assignmentId,
  });

  Future<void> submit({
    required String studentUsername,
    required String assignmentId,
  });

  Future<void> unsubmit({
    required String studentUsername,
    required String assignmentId,
  });

  Future<void> saveNote({
    required String studentUsername,
    required String assignmentId,
    required String note,
  });

  Future<void> clearNote({
    required String studentUsername,
    required String assignmentId,
  });

  Future<List<String>> loadAttachmentPaths({
    required String studentUsername,
    required String assignmentId,
  });

  Future<void> saveAttachmentPaths({
    required String studentUsername,
    required String assignmentId,
    required List<String> paths,
  });

  Future<void> clearAttachments({
    required String studentUsername,
    required String assignmentId,
  });
}
