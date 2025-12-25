import 'package:dartz/dartz.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';
import '../../../../core/error/failures.dart';

class CreateRecurringLessons {
  final LessonRepository repository;

  CreateRecurringLessons(this.repository);

  Future<Either<Failure, List<Lesson>>> call(CreateRecurringLessonsParams params) async {
    // recurrenceId 생성
    final recurrenceId = 'rec-${DateTime.now().millisecondsSinceEpoch}';
    
    // 반복 날짜 생성
    final dates = params.rule.generateDates();
    
    // 각 날짜별 Lesson 생성
    final lessons = <Lesson>[];
    for (int i = 0; i < dates.length; i++) {
      final scheduledAt = DateTime(
        dates[i].year,
        dates[i].month,
        dates[i].day,
        params.template.scheduledAt.hour,
        params.template.scheduledAt.minute,
      );
      
      final lesson = Lesson(
        id: 'lesson-${scheduledAt.millisecondsSinceEpoch}-${params.template.subject}',
        academyId: params.template.academyId,
        teacherId: params.template.teacherId,
        studentIds: params.template.studentIds,
        bookId: params.template.bookId,
        subject: params.template.subject,
        scheduledAt: scheduledAt,
        durationMinutes: params.template.durationMinutes,
        status: LessonStatus.scheduled,
        studentScores: null,
        attendance: null,
        memo: null,
        recurrenceId: recurrenceId,
        isRecurring: true,
        createdAt: DateTime.now(),
      );
      
      lessons.add(lesson);
    }
    
    // Repository에 저장
    return await repository.createRecurringLessons(params.template, params.rule);
  }
}

class CreateRecurringLessonsParams {
  final Lesson template;
  final RecurrenceRule rule;

  CreateRecurringLessonsParams({
    required this.template,
    required this.rule,
  });
}
