// lib/features/lessons/models.dart
//
// Lesson(회차) / ClassSchedule(주간 고정표) 도메인 모델
// - 모든 시간은 UTC 보관, 화면 표시는 로컬 변환 권장

class ClassSchedule {
  final String id;           // 'sch-...'
  final String academyId;    // 'academy-dev'
  final String? classId;     // 반/코스 식별자(옵션)
  final String subjectId;    // 예: 'math'
  final String teacherId;    // 담당 선생
  final String room;         // 교실 표기
  final int weekday;         // 1=Mon..7=Sun
  final int startMinutes;    // 자정 기준 분 (예: 19:00 → 1140)
  final int durationMin;     // 수업 길이(분)

  const ClassSchedule({
    required this.id,
    required this.academyId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.room,
    required this.weekday,
    required this.startMinutes,
    required this.durationMin,
  });
}

class Lesson {
  final String id;           // 'les-YYYYMMDD-HHmm-<subjectId>'
  final String academyId;
  final String? classId;
  final String subjectId;
  final String teacherId;
  final String room;
  final DateTime startUtc;   // UTC
  final DateTime endUtc;     // UTC
  final List<String> studentIds; // 참여 학생들(학생 홈 필터용)

  const Lesson({
    required this.id,
    required this.academyId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.room,
    required this.startUtc,
    required this.endUtc,
    required this.studentIds,
  });
}
