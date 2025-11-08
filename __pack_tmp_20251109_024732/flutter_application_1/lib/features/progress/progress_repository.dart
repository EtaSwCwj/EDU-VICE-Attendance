// lib/features/progress/progress_repository.dart
//
// 진도 타임라인 리포지토리 포트(인터페이스)

import 'models.dart';

abstract class ProgressRepository {
  /// 학생/과목(+선택 책) 기준의 최근 진도 타임라인
  Future<List<ProgressEntry>> loadTimeline({
    required String studentId,
    required String subjectId,
    String? bookId,
    int limit = 20,
  });
}
