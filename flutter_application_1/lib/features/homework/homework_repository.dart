// lib/features/homework/homework_repository.dart
//
// 과제 읽기/쓰기 포트(인터페이스)

import 'models.dart';

abstract class HomeworkRepository {
  /// 특정 학생+책에 대한 과제 목록
  Future<List<HomeworkTask>> loadTasks({
    required String studentId,
    required String bookId,
  });

  /// 완료 토글(로컬 스텁: 메모리 변경 후 목록 반환)
  Future<List<HomeworkTask>> toggleComplete({
    required String studentId,
    required String bookId,
    required String taskId,
  });
}
