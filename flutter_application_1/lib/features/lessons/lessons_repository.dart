// lib/features/lessons/lessons_repository.dart
//
// 레슨/스케줄 리포지토리 포트(인터페이스)

import 'models.dart';

abstract class LessonsRepository {
  /// anchor 주(월~일) 구간의 Lesson 생성/조회(학생 기준)
  Future<List<Lesson>> loadWeekLessonsForStudent({
    required String studentId,
    required DateTime anchorUtc, // 기준 날짜(UTC)
  });
}
