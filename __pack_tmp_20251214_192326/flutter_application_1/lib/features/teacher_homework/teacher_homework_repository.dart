// lib/features/teacher_homework/teacher_homework_repository.dart
import '../homework/models.dart';

abstract class TeacherHomeworkRepository {
  Future<List<StudentRef>> fetchStudents({String? query});
  Future<List<Assignment>> fetchAssignmentsByStudent(String studentId);
  Future<void> teacherCheck({
    required String assignmentId,
    required CheckResult result,
    required DateTime checkedAt,
  });

  Future<void> createAssignment({
    required StudentRef student,
    required SubjectRef subject,
    required BookRef book,
    required String rangeLabel,
    required DateTime dueDate,
  });
}
