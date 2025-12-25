import 'package:dartz/dartz.dart';
import '../entities/homework.dart';
import '../../../../core/error/failures.dart';

abstract class HomeworkRepository {
  // 조회
  Future<Either<Failure, List<Homework>>> getHomeworkByStudent(String studentId);
  Future<Either<Failure, List<Homework>>> getHomeworkByTeacher(String teacherId);
  Future<Either<Failure, List<Homework>>> getPendingHomework(String studentId);
  Future<Either<Failure, List<Homework>>> getDueSoonHomework(String teacherId);
  
  // 생성 (선생님)
  Future<Either<Failure, Homework>> assignHomework(Homework homework);
  
  // 수정 (학생)
  Future<Either<Failure, void>> submitHomework(String id);
  
  // 평가 (선생님)
  Future<Either<Failure, void>> gradeHomework(String id, int score, String? feedback);
  
  // 삭제
  Future<Either<Failure, void>> deleteHomework(String id);
}
