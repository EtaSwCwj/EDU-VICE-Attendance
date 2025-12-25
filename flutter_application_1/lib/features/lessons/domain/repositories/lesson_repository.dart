import 'package:dartz/dartz.dart';
import '../entities/lesson.dart';
import '../../../../core/error/failures.dart';

abstract class LessonRepository {
  // 수업 조회
  Future<Either<Failure, List<Lesson>>> getLessonsByTeacher(String teacherId, DateTime date);
  Future<Either<Failure, List<Lesson>>> getLessonsByStudent(String studentId, DateTime date);
  Future<Either<Failure, Lesson>> getLessonById(String id);
  Future<Either<Failure, List<Lesson>>> getLessonsByDateRange({
    String? teacherId, // Optional: null이면 모든 선생님의 수업 조회
    required DateTime startDate,
    required DateTime endDate,
  });
  
  // 수업 생성
  Future<Either<Failure, Lesson>> createLesson(Lesson lesson);
  Future<Either<Failure, List<Lesson>>> createRecurringLessons(
    Lesson template,
    RecurrenceRule rule,
  );
  
  // 수업 수정
  Future<Either<Failure, Lesson>> updateLesson(Lesson lesson);
  Future<Either<Failure, void>> updateLessonStatus(String id, LessonStatus status);
  Future<Either<Failure, void>> recordEvaluation(
    String lessonId,
    Map<String, int> scores,
    Map<String, bool> attendance,
    String? memo,
  );
  
  // 수업 삭제
  Future<Either<Failure, void>> deleteLesson(String id);
  Future<Either<Failure, void>> deleteRecurringSeries(String recurrenceId);
}
