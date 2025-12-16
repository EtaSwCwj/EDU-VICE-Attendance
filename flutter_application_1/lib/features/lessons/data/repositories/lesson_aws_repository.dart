// lib/features/lessons/data/repositories/lesson_aws_repository.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:dartz/dartz.dart';
import '../../../../models/ModelProvider.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../domain/entities/lesson.dart' as domain;

/// AWS DynamoDB와 연동하는 Lesson Repository
/// Amplify GraphQL API를 사용하여 Lesson 테이블에 CRUD 수행
class LessonAwsRepository implements LessonRepository {

  /// 선생님별 특정 날짜의 수업 조회
  @override
  Future<Either<Failure, List<domain.Lesson>>> getLessonsByTeacher(
    String teacherId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      final request = ModelQueries.list(
        Lesson.classType,
        where: Lesson.TEACHERUSERNAME.eq(teacherId)
            .and(Lesson.SCHEDULEDDATE.eq(TemporalDate.fromString(dateStr))),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[LessonAwsRepository] getLessonsByTeacher errors: ${response.errors}');
        return Left(ServerFailure(response.errors.toString()));
      }

      final lessons = response.data?.items.whereType<Lesson>().toList() ?? [];
      return Right(lessons.map(_toDomainLesson).toList());
    } catch (e) {
      safePrint('[LessonAwsRepository] getLessonsByTeacher error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 학생별 특정 날짜의 수업 조회
  @override
  Future<Either<Failure, List<domain.Lesson>>> getLessonsByStudent(
    String studentId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      // GraphQL에서 배열 포함 쿼리가 제한적이므로 전체 조회 후 필터링
      final request = ModelQueries.list(
        Lesson.classType,
        where: Lesson.SCHEDULEDDATE.eq(TemporalDate.fromString(dateStr)),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[LessonAwsRepository] getLessonsByStudent errors: ${response.errors}');
        return Left(ServerFailure(response.errors.toString()));
      }

      final allLessons = response.data?.items.whereType<Lesson>().toList() ?? [];
      final filtered = allLessons
          .where((l) => l.studentUsernames.contains(studentId))
          .toList();
      return Right(filtered.map(_toDomainLesson).toList());
    } catch (e) {
      safePrint('[LessonAwsRepository] getLessonsByStudent error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// ID로 수업 조회
  @override
  Future<Either<Failure, domain.Lesson>> getLessonById(String id) async {
    try {
      final request = ModelQueries.get(
        Lesson.classType,
        LessonModelIdentifier(id: id),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[LessonAwsRepository] getLessonById errors: ${response.errors}');
        return Left(ServerFailure(response.errors.toString()));
      }

      if (response.data == null) {
        return Left(NotFoundFailure('Lesson not found: $id'));
      }

      return Right(_toDomainLesson(response.data!));
    } catch (e) {
      safePrint('[LessonAwsRepository] getLessonById error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 날짜 범위로 수업 조회
  @override
  Future<Either<Failure, List<domain.Lesson>>> getLessonsByDateRange({
    String? teacherId, // Optional: null이면 모든 선생님의 수업 조회
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      safePrint('[LessonAwsRepository] getLessonsByDateRange: teacherId=$teacherId, startDate=$startDate, endDate=$endDate');

      final startStr = _formatDate(startDate);
      final endStr = _formatDate(endDate);

      // teacherId가 있으면 선생님 필터 포함, 없으면 날짜만 필터링
      final QueryPredicate where = teacherId != null
          ? Lesson.TEACHERUSERNAME.eq(teacherId)
              .and(Lesson.SCHEDULEDDATE.ge(TemporalDate.fromString(startStr)))
              .and(Lesson.SCHEDULEDDATE.le(TemporalDate.fromString(endStr)))
          : Lesson.SCHEDULEDDATE.ge(TemporalDate.fromString(startStr))
              .and(Lesson.SCHEDULEDDATE.le(TemporalDate.fromString(endStr)));

      final request = ModelQueries.list(Lesson.classType, where: where);
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[LessonAwsRepository] getLessonsByDateRange errors: ${response.errors}');
        return Left(ServerFailure(response.errors.toString()));
      }

      final lessons = response.data?.items.whereType<Lesson>().toList() ?? [];
      safePrint('[LessonAwsRepository] Found ${lessons.length} lessons for date range');

      if (lessons.isNotEmpty) {
        for (final lesson in lessons.take(3)) {
          safePrint('[LessonAwsRepository]   - Lesson: ${lesson.title}, scheduledDate=${lesson.scheduledDate}, startTime=${lesson.startTime}');
        }
      }

      return Right(lessons.map(_toDomainLesson).toList());
    } catch (e, stackTrace) {
      safePrint('[LessonAwsRepository] getLessonsByDateRange error: $e');
      safePrint('[LessonAwsRepository] Stack trace: $stackTrace');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 수업 생성
  @override
  Future<Either<Failure, domain.Lesson>> createLesson(domain.Lesson lesson) async {
    try {
      final awsLesson = _toAwsLesson(lesson);
      final request = ModelMutations.create(awsLesson);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[LessonAwsRepository] createLesson errors: ${response.errors}');
        return Left(ServerFailure(response.errors.toString()));
      }

      return Right(_toDomainLesson(response.data!));
    } catch (e) {
      safePrint('[LessonAwsRepository] createLesson error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 반복 수업 생성
  @override
  Future<Either<Failure, List<domain.Lesson>>> createRecurringLessons(
    domain.Lesson template,
    domain.RecurrenceRule rule,
  ) async {
    try {
      final dates = rule.generateDates();
      final createdLessons = <domain.Lesson>[];
      final recurrenceId = UUID.getUUID();

      for (final date in dates) {
        final lessonForDate = template.copyWith(
          scheduledAt: DateTime(
            date.year,
            date.month,
            date.day,
            template.scheduledAt.hour,
            template.scheduledAt.minute,
          ),
        );
        final awsLesson = _toAwsLesson(lessonForDate, recurrenceId: recurrenceId);
        final request = ModelMutations.create(awsLesson);
        final response = await Amplify.API.mutate(request: request).response;

        if (response.data != null) {
          createdLessons.add(_toDomainLesson(response.data!));
        }
      }

      return Right(createdLessons);
    } catch (e) {
      safePrint('[LessonAwsRepository] createRecurringLessons error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 수업 수정
  @override
  Future<Either<Failure, domain.Lesson>> updateLesson(domain.Lesson lesson) async {
    try {
      // 기존 수업 조회
      final getRequest = ModelQueries.get(
        Lesson.classType,
        LessonModelIdentifier(id: lesson.id),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      if (getResponse.data == null) {
        return Left(NotFoundFailure('Lesson not found: ${lesson.id}'));
      }

      final updated = getResponse.data!.copyWith(
        title: lesson.subject,
        subject: _subjectFromString(lesson.subject),
        studentUsernames: lesson.studentIds,
        bookId: lesson.bookId,
        scheduledDate: TemporalDate(DateTime(
          lesson.scheduledAt.year,
          lesson.scheduledAt.month,
          lesson.scheduledAt.day,
        )),
        startTime: TemporalTime(lesson.scheduledAt),
        duration: lesson.durationMinutes,
        status: _statusToAws(lesson.status),
        score: lesson.studentScores?.values.isNotEmpty == true
            ? lesson.studentScores!.values.first
            : null,
      );

      final request = ModelMutations.update(updated);
      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('[LessonAwsRepository] updateLesson errors: ${response.errors}');
        return Left(ServerFailure(response.errors.toString()));
      }

      return Right(_toDomainLesson(response.data!));
    } catch (e) {
      safePrint('[LessonAwsRepository] updateLesson error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 수업 상태 업데이트
  @override
  Future<Either<Failure, void>> updateLessonStatus(
    String id,
    domain.LessonStatus status,
  ) async {
    try {
      final getRequest = ModelQueries.get(
        Lesson.classType,
        LessonModelIdentifier(id: id),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      if (getResponse.data == null) {
        return Left(NotFoundFailure('Lesson not found: $id'));
      }

      final updated = getResponse.data!.copyWith(status: _statusToAws(status));
      final request = ModelMutations.update(updated);
      await Amplify.API.mutate(request: request).response;

      return const Right(null);
    } catch (e) {
      safePrint('[LessonAwsRepository] updateLessonStatus error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 평가 기록
  @override
  Future<Either<Failure, void>> recordEvaluation(
    String lessonId,
    Map<String, int> scores,
    Map<String, bool> attendance,
    String? memo,
  ) async {
    try {
      final getRequest = ModelQueries.get(
        Lesson.classType,
        LessonModelIdentifier(id: lessonId),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      if (getResponse.data == null) {
        return Left(NotFoundFailure('Lesson not found: $lessonId'));
      }

      // 평균 점수 계산
      final avgScore = scores.isNotEmpty
          ? (scores.values.reduce((a, b) => a + b) / scores.length).round()
          : null;

      final updated = getResponse.data!.copyWith(
        status: LessonStatus.COMPLETED,
        score: avgScore,
      );

      final request = ModelMutations.update(updated);
      await Amplify.API.mutate(request: request).response;

      return const Right(null);
    } catch (e) {
      safePrint('[LessonAwsRepository] recordEvaluation error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 수업 삭제
  @override
  Future<Either<Failure, void>> deleteLesson(String id) async {
    try {
      final getRequest = ModelQueries.get(
        Lesson.classType,
        LessonModelIdentifier(id: id),
      );
      final getResponse = await Amplify.API.query(request: getRequest).response;

      if (getResponse.data == null) {
        return Left(NotFoundFailure('Lesson not found: $id'));
      }

      final request = ModelMutations.delete(getResponse.data!);
      await Amplify.API.mutate(request: request).response;

      return const Right(null);
    } catch (e) {
      safePrint('[LessonAwsRepository] deleteLesson error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  /// 반복 수업 시리즈 삭제 (현재 미구현 - 단일 삭제만 지원)
  @override
  Future<Either<Failure, void>> deleteRecurringSeries(String recurrenceId) async {
    // TODO: recurrenceId로 관련 수업 모두 삭제
    return const Right(null);
  }

  // ─────────────────────────────────────────────────────────────────────
  // 변환 헬퍼 메서드
  // ─────────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// AWS Lesson → Domain Lesson 변환
  domain.Lesson _toDomainLesson(Lesson aws) {
    // TemporalDate와 TemporalTime을 로컬 타임존으로 파싱
    // getDateTime()은 UTC를 반환할 수 있으므로, 문자열에서 직접 파싱
    final dateStr = aws.scheduledDate.toString(); // "2025-12-16" 형식
    final dateParts = dateStr.split('-').map(int.parse).toList();

    final timeStr = aws.startTime.toString(); // "01:00:00" 형식
    final timeParts = timeStr.split(':').map(int.parse).toList();

    // 로컬 타임존으로 DateTime 생성 (UTC 아님!)
    final scheduledAt = DateTime(
      dateParts[0], // year
      dateParts[1], // month
      dateParts[2], // day
      timeParts[0], // hour
      timeParts[1], // minute
    );

    safePrint('[LessonAwsRepository] _toDomainLesson: ${aws.title}');
    safePrint('[LessonAwsRepository]   - AWS scheduledDate: ${aws.scheduledDate}, startTime: ${aws.startTime}');
    safePrint('[LessonAwsRepository]   - Parsed scheduledAt (로컬): $scheduledAt');

    return domain.Lesson(
      id: aws.id,
      academyId: 'default',
      teacherId: aws.teacherUsername,
      studentIds: aws.studentUsernames,
      bookId: aws.bookId ?? '',
      subject: _subjectToString(aws.subject),
      scheduledAt: scheduledAt,
      durationMinutes: aws.duration ?? 60,
      status: _statusFromAws(aws.status),
      studentScores: aws.score != null ? {'avg': aws.score!} : null,
      isRecurring: false,
      createdAt: aws.createdAt?.getDateTimeInUtc() ?? DateTime.now(),
    );
  }

  /// Domain Lesson → AWS Lesson 변환
  Lesson _toAwsLesson(domain.Lesson domainLesson, {String? recurrenceId}) {
    return Lesson(
      id: domainLesson.id.isEmpty ? UUID.getUUID() : domainLesson.id,
      title: domainLesson.subject,
      subject: _subjectFromString(domainLesson.subject),
      teacherUsername: domainLesson.teacherId,
      studentUsernames: domainLesson.studentIds,
      bookId: domainLesson.bookId.isEmpty ? null : domainLesson.bookId,
      scheduledDate: TemporalDate(DateTime(
        domainLesson.scheduledAt.year,
        domainLesson.scheduledAt.month,
        domainLesson.scheduledAt.day,
      )),
      startTime: TemporalTime(domainLesson.scheduledAt),
      duration: domainLesson.durationMinutes,
      status: _statusToAws(domainLesson.status),
      score: domainLesson.studentScores?.values.isNotEmpty == true
          ? domainLesson.studentScores!.values.first
          : null,
    );
  }

  String _subjectToString(Subject subject) {
    switch (subject) {
      case Subject.MATH:
        return '수학';
      case Subject.ENGLISH:
        return '영어';
      case Subject.SCIENCE:
        return '과학';
      case Subject.KOREAN:
        return '국어';
    }
  }

  Subject _subjectFromString(String str) {
    switch (str) {
      case '수학':
        return Subject.MATH;
      case '영어':
        return Subject.ENGLISH;
      case '과학':
        return Subject.SCIENCE;
      case '국어':
        return Subject.KOREAN;
      default:
        return Subject.MATH;
    }
  }

  domain.LessonStatus _statusFromAws(LessonStatus aws) {
    switch (aws) {
      case LessonStatus.SCHEDULED:
        return domain.LessonStatus.scheduled;
      case LessonStatus.IN_PROGRESS:
        return domain.LessonStatus.inProgress;
      case LessonStatus.COMPLETED:
        return domain.LessonStatus.completed;
    }
  }

  LessonStatus _statusToAws(domain.LessonStatus domainStatus) {
    if (domainStatus == domain.LessonStatus.scheduled) {
      return LessonStatus.SCHEDULED;
    } else if (domainStatus == domain.LessonStatus.inProgress) {
      return LessonStatus.IN_PROGRESS;
    } else if (domainStatus == domain.LessonStatus.completed) {
      return LessonStatus.COMPLETED;
    } else {
      // missed 또는 기타는 COMPLETED로 매핑
      return LessonStatus.COMPLETED;
    }
  }
}
