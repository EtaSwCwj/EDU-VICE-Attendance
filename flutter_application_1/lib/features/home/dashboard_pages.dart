// lib/features/home/dashboard_pages.dart
//
// 역할별 홈/대시보드 페이지 모음
// - OwnerDashboardPage: 기존처럼 간단 스텁
// - TeacherDashboardPage: 기존처럼 간단 스텁
// - StudentHomePage: 오늘 수업 카드 + 주간 달력 + 알림 요약 + [출석하기] CTA
//
// 의존:
//   provider
//   lib/features/assignments/*  (학생 배정 기반 표시)
//   lib/features/attendance/attendance_page.dart (출석 화면으로 이동)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../assignments/assignments_provider.dart';
import '../assignments/local_assignments_repository.dart';
import '../assignments/models.dart';
import '../attendance/attendance_page.dart';

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
    return ChangeNotifierProvider(
      create: (_) =>
          AssignmentsProvider(LocalAssignmentsRepository())..load(studentId: 'student-dev'),
      child: Consumer<AssignmentsProvider>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('학생 홈')),
            body: SafeArea(
              child: vm.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _StudentHomeBody(vm: vm),
            ),
          );
        },
      ),
    );
  }
}

class _StudentHomeBody extends StatelessWidget {
  final AssignmentsProvider vm;
  const _StudentHomeBody({required this.vm});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final week = _buildWeek(today);

    // 간단한 '오늘 수업' 목데이터: 배정된 과목 기준으로 시간 붙여서 보여줌
    final todayLessons = _mockTodayLessons(vm.subjects);

    // 간단 알림 요약 (향후 서버/로컬 연동)
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
          Text('학원: 에듀바이스 1관',
              style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 16),

          // 오늘 수업 카드
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
                      onPressed: () {
                        // 출석 페이지로 이동 (학생은 홈에서 접근)
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

          // 주간 달력 (간단 점표시)
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
                    children: week
                        .map(
                          (d) => _DayChip(
                            date: d,
                            isToday: _isSameDate(d, today),
                            hasLesson: todayLessons.any((l) => _isSameDate(l.date, d)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 알림 요약
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

  // 오늘 수업(목) 생성 — 배정된 과목 일부를 시간과 함께 보여줌
  List<_Lesson> _mockTodayLessons(List<AssignedSubject> subjects) {
    if (subjects.isEmpty) return const [];
    // 최대 2개만 노출(예시)
    final pool = subjects.take(2).toList();
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);

    final times = <Duration>[
      const Duration(hours: 16, minutes: 0),
      const Duration(hours: 19, minutes: 0),
    ];

    final result = <_Lesson>[];
    for (int i = 0; i < pool.length && i < times.length; i++) {
      result.add(
        _Lesson(
          subjectName: pool[i].name,
          teacherName: '담당 선생님',
          room: 'A-${i + 1}',
          date: base.add(times[i]),
        ),
      );
    }
    return result;
  }

  List<DateTime> _buildWeek(DateTime anchor) {
    final weekday = anchor.weekday; // Mon=1..Sun=7
    final monday = anchor.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _two(int v) => v.toString().padLeft(2, '0');
}

/// 내부 모델: 오늘 수업 표시용
class _Lesson {
  final String subjectName;
  final String teacherName;
  final String room;
  final DateTime date;

  _Lesson({
    required this.subjectName,
    required this.teacherName,
    required this.room,
    required this.date,
  });
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

/// 오늘 수업 리스트 타일
class _LessonTile extends StatelessWidget {
  final _Lesson lesson;
  const _LessonTile(this.lesson);

  @override
  Widget build(BuildContext context) {
    final t = lesson.date;
    final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.menu_book_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${lesson.subjectName} • $time • ${lesson.room} • ${lesson.teacherName}'),
          ),
        ],
      ),
    );
  }
}

/// 주간 달력 칩
class _DayChip extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool hasLesson;
  const _DayChip({required this.date, required this.isToday, required this.hasLesson});

  @override
  Widget build(BuildContext context) {
    final label = '${_w3(date.weekday)}\n${date.day}';
    final primary = Theme.of(context).colorScheme.primary;
    // withOpacity → withValues 로 대체(Flutter 권장)
    final bg = isToday
        ? primary.withValues(alpha: 0.12)
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
