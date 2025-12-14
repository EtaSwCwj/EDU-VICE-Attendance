import 'student_assignment_local_attachments.dart';
import 'student_assignment_local_notes.dart';
import 'student_assignment_local_snapshot.dart';
import 'student_assignment_local_submission.dart';
import 'student_assignment_submission_repository.dart';

class LocalStudentAssignmentSubmissionRepository implements StudentAssignmentSubmissionRepository {
  const LocalStudentAssignmentSubmissionRepository();

  @override
  Future<StudentAssignmentLocalSnapshot> loadSnapshot({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final submitted = await StudentAssignmentLocalSubmission.isSubmitted(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );

    final submittedAt = await StudentAssignmentLocalSubmission.submittedAtEpochMillis(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );

    final note = await StudentAssignmentLocalNotes.load(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );

    final photos = await StudentAssignmentLocalAttachments.loadPaths(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );

    return StudentAssignmentLocalSnapshot(
      submitted: submitted,
      submittedAtEpochMillis: submittedAt,
      note: note,
      photoPaths: _uniqueNonEmpty(photos),
    );
  }

  @override
  Future<void> submit({
    required String studentUsername,
    required String assignmentId,
  }) async {
    await StudentAssignmentLocalSubmission.submit(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  @override
  Future<void> unsubmit({
    required String studentUsername,
    required String assignmentId,
  }) async {
    await StudentAssignmentLocalSubmission.unsubmit(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  @override
  Future<void> saveNote({
    required String studentUsername,
    required String assignmentId,
    required String note,
  }) async {
    await StudentAssignmentLocalNotes.save(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
      note: note,
    );
  }

  @override
  Future<void> clearNote({
    required String studentUsername,
    required String assignmentId,
  }) async {
    await StudentAssignmentLocalNotes.clear(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
  }

  @override
  Future<List<String>> loadAttachmentPaths({
    required String studentUsername,
    required String assignmentId,
  }) async {
    final paths = await StudentAssignmentLocalAttachments.loadPaths(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
    );
    return _uniqueNonEmpty(paths);
  }

  @override
  Future<void> saveAttachmentPaths({
    required String studentUsername,
    required String assignmentId,
    required List<String> paths,
  }) async {
    await StudentAssignmentLocalAttachments.savePaths(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
      paths: paths,
    );
  }

  @override
  Future<void> clearAttachments({
    required String studentUsername,
    required String assignmentId,
  }) async {
    await StudentAssignmentLocalAttachments.clear(
      studentUsername: studentUsername,
      assignmentId: assignmentId,
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
