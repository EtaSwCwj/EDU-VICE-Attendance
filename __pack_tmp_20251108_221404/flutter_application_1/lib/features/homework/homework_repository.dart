// lib/features/homework/homework_repository.dart
import 'models.dart';

/// 과제 읽기/쓰기 추상화
abstract class HomeworkRepository {
  Future<List<Assignment>> fetchAssignments();
  Future<void> updateAssignment(Assignment assignment);
}
