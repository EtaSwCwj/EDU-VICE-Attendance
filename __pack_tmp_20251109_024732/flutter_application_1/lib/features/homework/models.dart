// lib/features/homework/models.dart
import 'package:flutter/foundation.dart';

/// 과제 완료 상태(학생 화면 표시에 쓰는 1차 분류)
enum AssignmentStatus { pending, completed, overdue }

/// 교사용 검사 결과(최종 확정)
enum CheckResult { pass, fail, partial }

/// 과목/책/학생 참조
@immutable
class SubjectRef {
  final String id;
  final String name;
  const SubjectRef({required this.id, required this.name});
}

@immutable
class BookRef {
  final String id;
  final String name;
  const BookRef({required this.id, required this.name});
}

@immutable
class StudentRef {
  final String id;
  final String name;
  const StudentRef({required this.id, required this.name});
}

/// 과제 엔터티
///
/// 학생/교사용 분리 원칙:
/// - 학생: isDone == "해왔어요(제출 표시)" 용도
/// - 교사: teacherCheckedAt + checkResult 가 최종 확정
@immutable
class Assignment {
  final String id;
  final SubjectRef subject;
  final BookRef book;
  final StudentRef assignedTo;

  /// 예: "p.30–45" 또는 "1과 1~3번"
  final String rangeLabel;
  final DateTime dueDate; // 마감일(로컬 날짜 기준 표기)

  /// 학생 자가 제출 표시
  final bool isDone;

  /// 교사 확정 메타
  final DateTime? teacherCheckedAt;
  final CheckResult? checkResult;

  const Assignment({
    required this.id,
    required this.subject,
    required this.book,
    required this.assignedTo,
    required this.rangeLabel,
    required this.dueDate,
    required this.isDone,
    this.teacherCheckedAt,
    this.checkResult,
  });

  Assignment copyWith({
    bool? isDone,
    DateTime? teacherCheckedAt,
    CheckResult? checkResult,
  }) {
    return Assignment(
      id: id,
      subject: subject,
      book: book,
      assignedTo: assignedTo,
      rangeLabel: rangeLabel,
      dueDate: dueDate,
      isDone: isDone ?? this.isDone,
      teacherCheckedAt: teacherCheckedAt ?? this.teacherCheckedAt,
      checkResult: checkResult ?? this.checkResult,
    );
  }

  /// 학생 탭 표시용 1차 상태:
  /// - isDone이면 completed
  /// - 미완료 & 마감 지남이면 overdue
  /// - 그 외 pending
  AssignmentStatus get status {
    if (isDone) return AssignmentStatus.completed;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(today)) return AssignmentStatus.overdue;
    return AssignmentStatus.pending;
  }

  /// 마감 임박(오늘 포함 2일 이내, 학생 탭 강조)
  bool get isDueSoon {
    if (isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    return diff >= 0 && diff <= 2;
  }
}

/// 간단 날짜 포맷(yyyy-MM-dd) — intl 미사용
String ymd(DateTime d) {
  String two(int v) => v < 10 ? "0$v" : "$v";
  return "${d.year}-${two(d.month)}-${two(d.day)}";
}
