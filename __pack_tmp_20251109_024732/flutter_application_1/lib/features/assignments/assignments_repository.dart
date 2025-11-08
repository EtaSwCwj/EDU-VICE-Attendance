// lib/features/assignments/assignments_repository.dart
//
// 배정 읽기 전용 리포지토리 포트(인터페이스)

import 'models.dart';

abstract class AssignmentsRepository {
  /// 해당 학생에게 배정된 과목/책 번들을 반환
  Future<StudentAssignmentBundle> loadForStudent(String studentId);
}
