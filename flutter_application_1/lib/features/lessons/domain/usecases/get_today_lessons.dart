import 'package:dartz/dartz.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';
import '../../../../core/error/failures.dart';

class GetTodayLessons {
  final LessonRepository repository;

  GetTodayLessons(this.repository);

  Future<Either<Failure, TodayLessonsResult>> call(String teacherId) async {
    final today = DateTime.now();
    final result = await repository.getLessonsByTeacher(teacherId, today);
    
    return result.fold(
      (failure) => Left(failure),
      (lessons) {
        final inProgress = <Lesson>[];
        final upcoming = <Lesson>[];
        final completed = <Lesson>[];
        final warnings = <Lesson>[];
        
        for (final lesson in lessons) {
          if (lesson.status == LessonStatus.completed) {
            completed.add(lesson);
          } else if (lesson.status == LessonStatus.inProgress) {
            inProgress.add(lesson);
          } else if (lesson.shouldWarn) {
            warnings.add(lesson);
          } else if (lesson.status == LessonStatus.scheduled) {
            upcoming.add(lesson);
          }
        }
        
        // 정렬: 진행중 > 경고 > 시간 가까운 순
        inProgress.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        warnings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        completed.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        
        return Right(TodayLessonsResult(
          inProgress: inProgress,
          upcoming: upcoming,
          completed: completed,
          warnings: warnings,
        ));
      },
    );
  }
}

class TodayLessonsResult {
  final List<Lesson> inProgress;
  final List<Lesson> upcoming;
  final List<Lesson> completed;
  final List<Lesson> warnings;

  TodayLessonsResult({
    required this.inProgress,
    required this.upcoming,
    required this.completed,
    required this.warnings,
  });

  int get totalCount => inProgress.length + upcoming.length + completed.length + warnings.length;
}
