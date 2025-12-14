// lib/features/lessons/local_lessons_repository.dart
//
// DEV용 로컬 스텁 리포지토리
// - 고정 주간 스케줄 → anchor 주의 Lesson 리스트 생성
// - 시간은 UTC로 저장(표시는 로컬 변환 권장)

import 'models.dart';
import 'lessons_repository.dart';

class LocalLessonsRepository implements LessonsRepository {
  // student-dev 에 대한 예시 주간 스케줄(과목 id는 기존 assignments에 맞춤)
  static const List<ClassSchedule> _schedules = [
    ClassSchedule(
      id: 'sch-math-mon-1900',
      academyId: 'academy-dev',
      classId: 'class-dev-A',
      subjectId: 'math',
      teacherId: 't-001',
      room: 'A-1',
      weekday: DateTime.monday,
      startMinutes: 19 * 60, // 19:00
      durationMin: 90,
    ),
    ClassSchedule(
      id: 'sch-eng-tue-1600',
      academyId: 'academy-dev',
      classId: 'class-dev-B',
      subjectId: 'eng',
      teacherId: 't-002',
      room: 'B-2',
      weekday: DateTime.tuesday,
      startMinutes: 16 * 60, // 16:00
      durationMin: 60,
    ),
    ClassSchedule(
      id: 'sch-sci-fri-1800',
      academyId: 'academy-dev',
      classId: 'class-dev-C',
      subjectId: 'sci',
      teacherId: 't-003',
      room: 'C-3',
      weekday: DateTime.friday,
      startMinutes: 18 * 60, // 18:00
      durationMin: 90,
    ),
  ];

  @override
  Future<List<Lesson>> loadWeekLessonsForStudent({
    required String studentId,
    required DateTime anchorUtc,
  }) async {
    // anchor 주의 Monday(UTC) 계산
    final mondayUtc = _mondayUtc(anchorUtc);
    final lessons = <Lesson>[];

    for (final s in _schedules) {
      final dayUtc = mondayUtc.add(Duration(days: s.weekday - DateTime.monday));
      final startUtc = DateTime.utc(
        dayUtc.year,
        dayUtc.month,
        dayUtc.day,
        s.startMinutes ~/ 60,
        s.startMinutes % 60,
      );
      final endUtc = startUtc.add(Duration(minutes: s.durationMin));
      final id = 'les-${_yyyymmdd(startUtc)}-${_hhmm(startUtc)}-${s.subjectId}';

      lessons.add(
        Lesson(
          id: id,
          academyId: s.academyId,
          classId: s.classId,
          subjectId: s.subjectId,
          teacherId: s.teacherId,
          room: s.room,
          startUtc: startUtc,
          endUtc: endUtc,
          studentIds: [studentId],
        ),
      );
    }

    // 시작 시각 기준 오름차순
    lessons.sort((a, b) => a.startUtc.compareTo(b.startUtc));
    return lessons;
  }

  DateTime _mondayUtc(DateTime anchorUtc) {
    final d = DateTime.utc(anchorUtc.year, anchorUtc.month, anchorUtc.day);
    final w = d.weekday; // Mon=1..Sun=7
    return d.subtract(Duration(days: w - DateTime.monday));
  }

  String _yyyymmdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}';
}
