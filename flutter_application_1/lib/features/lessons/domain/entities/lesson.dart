import 'package:equatable/equatable.dart';

enum LessonStatus {
  scheduled,   // 예정
  inProgress,  // 진행중
  completed,   // 완료
  missed,      // 결석/미진행
}

/// 수업 진도 정보
class LessonProgress extends Equatable {
  final String? chapterName;      // 챕터명 (예: "1단원 자연수")
  final int? startPage;           // 시작 페이지
  final int? endPage;             // 끝 페이지
  final String? note;             // 진도 관련 메모

  const LessonProgress({
    this.chapterName,
    this.startPage,
    this.endPage,
    this.note,
  });

  String get displayText {
    final parts = <String>[];
    if (chapterName != null) parts.add(chapterName!);
    if (startPage != null && endPage != null) {
      parts.add('p.$startPage-$endPage');
    } else if (startPage != null) {
      parts.add('p.$startPage~');
    }
    return parts.isEmpty ? '진도 미정' : parts.join(' ');
  }

  @override
  List<Object?> get props => [chapterName, startPage, endPage];
}

class Lesson extends Equatable {
  final String id;
  final String academyId;
  final String teacherId;
  final List<String> studentIds;
  final String bookId;
  final String subject;
  final DateTime scheduledAt;
  final int durationMinutes;
  final LessonStatus status;
  
  // 진도 정보 (NEW!)
  final LessonProgress? progress;
  
  // 평가 정보
  final Map<String, int>? studentScores; // studentId -> score (0-100)
  final Map<String, bool>? attendance;   // studentId -> present
  final Map<String, String>? studentMemos; // studentId -> memo (학생별 메모)
  final String? memo;
  
  // 반복 정보 (원본 수업만 가짐)
  final String? recurrenceId;  // 같은 반복 그룹
  final bool isRecurring;
  
  final DateTime createdAt;
  final DateTime? completedAt;

  const Lesson({
    required this.id,
    required this.academyId,
    required this.teacherId,
    required this.studentIds,
    required this.bookId,
    required this.subject,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.progress,
    this.studentScores,
    this.attendance,
    this.studentMemos,
    this.memo,
    this.recurrenceId,
    required this.isRecurring,
    required this.createdAt,
    this.completedAt,
  });

  bool get isToday {
    final now = DateTime.now();
    final scheduled = scheduledAt;
    return now.year == scheduled.year &&
           now.month == scheduled.month &&
           now.day == scheduled.day;
  }

  bool get isPast {
    return DateTime.now().isAfter(scheduledAt.add(Duration(minutes: durationMinutes)));
  }

  bool get shouldWarn {
    return isPast && status == LessonStatus.scheduled;
  }

  Lesson copyWith({
    List<String>? studentIds,
    String? bookId,
    String? subject,
    DateTime? scheduledAt,
    int? durationMinutes,
    LessonStatus? status,
    LessonProgress? progress,
    Map<String, int>? studentScores,
    Map<String, bool>? attendance,
    Map<String, String>? studentMemos,
    String? memo,
    DateTime? completedAt,
  }) {
    return Lesson(
      id: id,
      academyId: academyId,
      teacherId: teacherId,
      studentIds: studentIds ?? this.studentIds,
      bookId: bookId ?? this.bookId,
      subject: subject ?? this.subject,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      studentScores: studentScores ?? this.studentScores,
      attendance: attendance ?? this.attendance,
      studentMemos: studentMemos ?? this.studentMemos,
      memo: memo ?? this.memo,
      recurrenceId: recurrenceId,
      isRecurring: isRecurring,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}

class RecurrenceRule {
  final int weekInterval;  // 1 = 매주, 2 = 격주, 4 = 4주마다
  final int occurrences;   // 총 몇 회 반복
  final DateTime startDate;
  final List<int> daysOfWeek; // 1=월, 2=화, ..., 7=일

  const RecurrenceRule({
    required this.weekInterval,
    required this.occurrences,
    required this.startDate,
    required this.daysOfWeek,
  });

  List<DateTime> generateDates() {
    final dates = <DateTime>[];
    var currentDate = startDate;
    
    while (dates.length < occurrences) {
      for (final day in daysOfWeek) {
        if (dates.length >= occurrences) break;
        
        final targetDate = _findNextWeekday(currentDate, day);
        if (targetDate.isAfter(startDate) || targetDate.isAtSameMomentAs(startDate)) {
          dates.add(targetDate);
        }
      }
      currentDate = currentDate.add(Duration(days: 7 * weekInterval));
    }
    
    return dates;
  }

  DateTime _findNextWeekday(DateTime from, int targetWeekday) {
    final currentWeekday = from.weekday;
    final daysUntilTarget = (targetWeekday - currentWeekday) % 7;
    return from.add(Duration(days: daysUntilTarget));
  }
}
