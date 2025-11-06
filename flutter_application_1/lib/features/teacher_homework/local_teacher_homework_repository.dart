// lib/features/teacher_homework/local_teacher_homework_repository.dart
import 'dart:async';

import '../homework/models.dart';
import '../homework/local_homework_repository.dart';
import 'teacher_homework_repository.dart';

/// 학생/과제는 LocalHomeworkRepository의 _store를 그대로 사용.
/// 여긴 교사용 뷰에서 필요한 질의/갱신만 래핑한다.
class LocalTeacherHomeworkRepository implements TeacherHomeworkRepository {
  final LocalHomeworkRepository _base;

  LocalTeacherHomeworkRepository(this._base);

  @override
  Future<List<StudentRef>> fetchStudents({String? query}) async {
    final list = await _base.fetchAssignments();
    final map = <String, StudentRef>{};
    for (final a in list) {
      map[a.assignedTo.id] = a.assignedTo;
    }
    var out = map.values.toList();
    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim();
      out = out.where((s) => s.name.contains(q)).toList();
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  @override
  Future<List<Assignment>> fetchAssignmentsByStudent(String studentId) async {
    final all = await _base.fetchAssignments();
    final out = all.where((a) => a.assignedTo.id == studentId).toList()
      ..sort((a, b) {
        // 검사 대기(학생 제출 완료 but 미확정) -> 제출 대기(임박/지남 우선) -> 확정 완료/미완료/부분
        int rank(Assignment x) {
          final pendingCheck = x.isDone && x.teacherCheckedAt == null;
          final overdue = DateTime(x.dueDate.year, x.dueDate.month, x.dueDate.day)
              .isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
          if (pendingCheck) return 0;
          if (!x.isDone && overdue) return 1;
          if (!x.isDone && x.isDueSoon) return 2;
          if (!x.isDone) return 3;
          // isDone && teacherCheckedAt != null 인 케이스(확정)
          return 4;
        }

        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return a.dueDate.compareTo(b.dueDate);
      });
    return out;
  }

  @override
  Future<void> teacherCheck({
    required String assignmentId,
    required CheckResult result,
    required DateTime checkedAt,
  }) async {
    // base 저장소 갱신
    final list = await _base.fetchAssignments();
    final idx = list.indexWhere((e) => e.id == assignmentId);
    if (idx < 0) return;
    final a = list[idx].copyWith(
      teacherCheckedAt: checkedAt,
      checkResult: result,
    );
    await _base.updateAssignment(a);
    // 딜레이로 네트워크 느낌
    await Future.delayed(const Duration(milliseconds: 120));
  }
}
