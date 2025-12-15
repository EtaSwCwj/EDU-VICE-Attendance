import 'package:dartz/dartz.dart';
import 'package:sembast/sembast.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';

class LessonLocalRepository implements LessonRepository {
  final Database db;
  final _store = StoreRef<String, Map<String, dynamic>>('lessons');

  LessonLocalRepository(this.db);

  @override
  Future<Either<Failure, List<Lesson>>> getLessonsByTeacher(
    String teacherId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final finder = Finder(
        filter: Filter.and([
          Filter.equals('teacherId', teacherId),
          Filter.greaterThanOrEquals('scheduledAt', startOfDay.toIso8601String()),
          Filter.lessThan('scheduledAt', endOfDay.toIso8601String()),
        ]),
        sortOrders: [SortOrder('scheduledAt')],
      );

      final records = await _store.find(db, finder: finder);
      final lessons = records.map((r) => _fromMap(r.value)).toList();

      return Right(lessons);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> getLessonsByStudent(
    String studentId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final finder = Finder(
        filter: Filter.and([
          Filter.greaterThanOrEquals('scheduledAt', startOfDay.toIso8601String()),
          Filter.lessThan('scheduledAt', endOfDay.toIso8601String()),
        ]),
      );

      final records = await _store.find(db, finder: finder);
      final lessons = records
          .map((r) => _fromMap(r.value))
          .where((lesson) => lesson.studentIds.contains(studentId))
          .toList();

      return Right(lessons);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Lesson>> getLessonById(String id) async {
    try {
      final record = await _store.record(id).get(db);
      if (record == null) {
        return Left(NotFoundFailure('수업을 찾을 수 없습니다'));
      }
      return Right(_fromMap(record));
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> getLessonsByDateRange({
    required String teacherId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final finder = Finder(
        filter: Filter.and([
          Filter.equals('teacherId', teacherId),
          Filter.greaterThanOrEquals('scheduledAt', startDate.toIso8601String()),
          Filter.lessThanOrEquals('scheduledAt', endDate.toIso8601String()),
        ]),
        sortOrders: [SortOrder('scheduledAt')],
      );

      final records = await _store.find(db, finder: finder);
      final lessons = records.map((r) => _fromMap(r.value)).toList();

      return Right(lessons);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Lesson>> createLesson(Lesson lesson) async {
    try {
      await _store.record(lesson.id).put(db, _toMap(lesson));
      return Right(lesson);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Lesson>>> createRecurringLessons(
    Lesson template,
    RecurrenceRule rule,
  ) async {
    try {
      final recurrenceId = 'rec-${DateTime.now().millisecondsSinceEpoch}';
      final dates = rule.generateDates();
      final lessons = <Lesson>[];

      for (final date in dates) {
        final scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          template.scheduledAt.hour,
          template.scheduledAt.minute,
        );

        final lesson = Lesson(
          id: 'lesson-${scheduledAt.millisecondsSinceEpoch}',
          academyId: template.academyId,
          teacherId: template.teacherId,
          studentIds: template.studentIds,
          bookId: template.bookId,
          subject: template.subject,
          scheduledAt: scheduledAt,
          durationMinutes: template.durationMinutes,
          status: LessonStatus.scheduled,
          recurrenceId: recurrenceId,
          isRecurring: true,
          createdAt: DateTime.now(),
        );

        await _store.record(lesson.id).put(db, _toMap(lesson));
        lessons.add(lesson);
      }

      return Right(lessons);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Lesson>> updateLesson(Lesson lesson) async {
    try {
      await _store.record(lesson.id).put(db, _toMap(lesson));
      return Right(lesson);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateLessonStatus(String id, LessonStatus status) async {
    try {
      final record = await _store.record(id).get(db);
      if (record == null) {
        return Left(NotFoundFailure('수업을 찾을 수 없습니다'));
      }

      final lesson = _fromMap(record);
      final updated = lesson.copyWith(
        status: status,
        completedAt: status == LessonStatus.completed ? DateTime.now() : null,
      );

      await _store.record(id).put(db, _toMap(updated));
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> recordEvaluation(
    String lessonId,
    Map<String, int> scores,
    Map<String, bool> attendance,
    String? memo,
  ) async {
    try {
      final record = await _store.record(lessonId).get(db);
      if (record == null) {
        return Left(NotFoundFailure('수업을 찾을 수 없습니다'));
      }

      final lesson = _fromMap(record);
      final updated = lesson.copyWith(
        studentScores: scores,
        attendance: attendance,
        memo: memo,
        status: LessonStatus.completed,
        completedAt: DateTime.now(),
      );

      await _store.record(lessonId).put(db, _toMap(updated));
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteLesson(String id) async {
    try {
      await _store.record(id).delete(db);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecurringSeries(String recurrenceId) async {
    try {
      final finder = Finder(
        filter: Filter.equals('recurrenceId', recurrenceId),
      );
      await _store.delete(db, finder: finder);
      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  Map<String, dynamic> _toMap(Lesson lesson) {
    return {
      'id': lesson.id,
      'academyId': lesson.academyId,
      'teacherId': lesson.teacherId,
      'studentIds': lesson.studentIds,
      'bookId': lesson.bookId,
      'subject': lesson.subject,
      'scheduledAt': lesson.scheduledAt.toIso8601String(),
      'durationMinutes': lesson.durationMinutes,
      'status': lesson.status.name,
      'studentScores': lesson.studentScores,
      'attendance': lesson.attendance,
      'memo': lesson.memo,
      'recurrenceId': lesson.recurrenceId,
      'isRecurring': lesson.isRecurring,
      'createdAt': lesson.createdAt.toIso8601String(),
      'completedAt': lesson.completedAt?.toIso8601String(),
    };
  }

  Lesson _fromMap(Map<String, dynamic> map) {
    return Lesson(
      id: map['id'] as String,
      academyId: map['academyId'] as String,
      teacherId: map['teacherId'] as String,
      studentIds: List<String>.from(map['studentIds'] as List),
      bookId: map['bookId'] as String,
      subject: map['subject'] as String,
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      durationMinutes: map['durationMinutes'] as int,
      status: LessonStatus.values.firstWhere((e) => e.name == map['status']),
      studentScores: map['studentScores'] != null
          ? Map<String, int>.from(map['studentScores'] as Map)
          : null,
      attendance: map['attendance'] != null
          ? Map<String, bool>.from(map['attendance'] as Map)
          : null,
      memo: map['memo'] as String?,
      recurrenceId: map['recurrenceId'] as String?,
      isRecurring: map['isRecurring'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }
}
