import 'package:dartz/dartz.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';
import '../../../../core/error/failures.dart';

class RecordLessonEvaluation {
  final LessonRepository repository;

  RecordLessonEvaluation(this.repository);

  Future<Either<Failure, void>> call(RecordEvaluationParams params) async {
    // 점수 유효성 검사
    for (final score in params.scores.values) {
      if (score < 0 || score > 100) {
        return Left(ValidationFailure('점수는 0-100 사이여야 합니다'));
      }
    }
    
    // 평가 저장
    final result = await repository.recordEvaluation(
      params.lessonId,
      params.scores,
      params.attendance,
      params.memo,
    );
    
    // 수업 상태를 완료로 변경
    if (result.isRight()) {
      await repository.updateLessonStatus(params.lessonId, LessonStatus.completed);
    }
    
    return result;
  }
}

class RecordEvaluationParams {
  final String lessonId;
  final Map<String, int> scores;      // studentId -> score
  final Map<String, bool> attendance; // studentId -> present
  final String? memo;

  RecordEvaluationParams({
    required this.lessonId,
    required this.scores,
    required this.attendance,
    this.memo,
  });
}
