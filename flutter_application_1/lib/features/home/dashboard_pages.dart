// lib/features/home/dashboard_pages.dart
//
// 역할별 홈/대시보드 페이지 모음
// - StudentHomePage: LessonsProvider 기반(오늘 수업 카드 + 주간 달력 + 알림 요약)
// - Owner/Teacher: 스텁 유지

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../assignments/assignments_provider.dart';
import '../assignments/local_assignments_repository.dart';

import '../attendance/attendance_page.dart';

import '../lessons/lessons_provider.dart';
import '../lessons/local_lessons_repository.dart';
import '../lessons/models.dart';

/// ------------------------------
/// 원장 대시보드 (간단 스텁)
/// ------------------------------
class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('원장 대시보드')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Stub: 학원 전체 현황(출석 요약, 공지, 반 현황 등)'),
        ),
      ),
    );
  }
}

/// ------------------------------
/// 선생 대시보드 (간단 스텁)
/// ------------------------------
class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('선생 대시보드')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Stub: 오늘 수업/담당 학생/과제 알림 요약'),
        ),
      ),
    );
  }
}

/// ------------------------------
/// 학생 홈
/// ------------------------------
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 배정(과목/책) – 상단 라벨 등에서 활용 가능
        ChangeNotifierProvider(
          create: (_) => AssignmentsProvider(LocalAssignmentsRepository())..load(studentId: 'student-dev'),
        ),
        // 레슨(회차) – 오늘 수업/달력 점의 근거
        ChangeNotifierProvider(
          create: (_) => LessonsProvider(LocalLessonsRepository())..loadWeek(studentId: 'student-dev'),
        ),
      ],
      child: Consumer2<AssignmentsProvider, LessonsProvider>(
        builder: (context, assign, lessons, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('학생 홈')),
            body: SafeArea(
              child: (assign.loading || lessons.loading)
                  ? const Center(child: CircularProgressIndicator())
                  : _StudentHomeBody(assign: assign, lessons: lessons),
            ),
          );
        },
      ),
    );
  }
}

class _StudentHomeBody extends StatelessWidget {
  final AssignmentsProvider assign;
  final LessonsProvider lessons;
  const _StudentHomeBody({required this.assign, required this.lessons});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDates = lessons.weekDatesLocal();
    final todayLessons = lessons.todayLessons();

    // 간단 알림 요약 (스텁)
    final notifications = <String>[
      '과제 마감 D-2: 영어 VOCA Day 21',
      '출석 미체크: 지난주 수학 1회',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 학원/학생 안내(DEV 고정값)
          Text('학원: 에듀바이스 1관', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          // 오늘 수업 카드 (Lesson 기반)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: '오늘 수업',
                    trailing: Text(
                      '${today.year}-${_two(today.month)}-${_two(today.day)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (todayLessons.isEmpty)
                    const Text('오늘 예정된 수업이 없습니다.')
                  else
                    ...todayLessons.map((l) => _LessonTile(l)).toList(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.how_to_reg_outlined),
                      label: const Text('출석하기'),
                      onPressed: todayLessons.isEmpty
                          ? null
                          : () {
                              // 출석 페이지로 이동 (추후: 해당 Lesson ID와 함께 이동)
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AttendancePage(),
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 주간 달력 (Lesson 유무 점표시)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: '이번 주 달력'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDates
                        .map(
                          (d) => _DayChip(
                            date: d,
                            isToday: _isSameDate(d, today),
                            hasLesson: lessons.lessonsForDate(d).isNotEmpty,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 알림 요약(스텁)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: '알림'),
                  const SizedBox(height: 8),
                  if (notifications.isEmpty)
                    const Text('새 알림이 없습니다.')
                  else
                    ...notifications
                        .take(2)
                        .map((t) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.notifications_none, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(t)),
                                ],
                              ),
                            ))
                        .toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _two(int v) => v.toString().padLeft(2, '0');
}

/// 섹션 헤더 위젯
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// 오늘 수업 리스트 타일 (Lesson 기반)
class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  const _LessonTile(this.lesson);

  @override
  Widget build(BuildContext context) {
    final tLocal = lesson.startUtc.toLocal();
    final time = '${tLocal.hour.toString().padLeft(2, '0')}:${tLocal.minute.toString().padLeft(2, '0')}';

    // 과목 라벨: assignments의 표시명과 매칭 시도
    String subjectLabel = lesson.subjectId;
    final assign = context.read<AssignmentsProvider?>();
    if (assign != null) {
      final m = assign.subjects.where((s) => s.id == lesson.subjectId);
      if (m.isNotEmpty) subjectLabel = m.first.name;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$subjectLabel • $time • ${lesson.room} • ${lesson.teacherId}'),
          ),
        ],
      ),
    );
  }
}

/// 주간 달력 칩
class _DayChip extends StatelessWidget {
  final DateTime date;   // 로컬 날짜(연-월-일)
  final bool isToday;
  final bool hasLesson;
  const _DayChip({required this.date, required this.isToday, required this.hasLesson});

  @override
  Widget build(BuildContext context) {
    final label = '${_w3(date.weekday)}\n${date.day}';
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isToday
        ? primary.withValues(alpha: 0.12) // withOpacity deprecated 대체
        : Theme.of(context).colorScheme.surface;
    final bd = isToday ? primary : Theme.of(context).dividerColor;

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 4),
          if (hasLesson)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _w3(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '월';
      case DateTime.tuesday:
        return '화';
      case DateTime.wednesday:
        return '수';
      case DateTime.thursday:
        return '목';
      case DateTime.friday:
        return '금';
      case DateTime.saturday:
        return '토';
      case DateTime.sunday:
        return '일';
      default:
        return '';
    }
  }
}
