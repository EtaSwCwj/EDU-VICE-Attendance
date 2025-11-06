// lib/features/teacher_homework/local_teacher_homework_repository.dart
import 'dart:async';

import '../homework/models.dart';
import '../homework/local_homework_repository.dart';
import 'teacher_homework_repository.dart';

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
        int rank(Assignment x) {
          final checked = x.teacherCheckedAt != null && x.checkResult != null;
          if (!checked && x.isDone) return 0;
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          final due = DateTime(x.dueDate.year, x.dueDate.month, x.dueDate.day);
          if (!x.isDone && due.isBefore(today)) return 1;
          if (!x.isDone && x.isDueSoon) return 2;
          if (!x.isDone) return 3;
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
    final list = await _base.fetchAssignments();
    final idx = list.indexWhere((e) => e.id == assignmentId);
    if (idx < 0) return;
    final a = list[idx].copyWith(
      teacherCheckedAt: checkedAt,
      checkResult: result,
    );
    await _base.updateAssignment(a);
    await Future.delayed(const Duration(milliseconds: 120));
  }

  String _nextId(List<Assignment> all) {
    // A-001, A-002 ... 패턴 유지
    int maxN = 0;
    for (final a in all) {
      final m = RegExp(r'^A-(\d+)$').firstMatch(a.id);
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > maxN) maxN = n;
      }
    }
    final next = maxN + 1;
    return "A-${next.toString().padLeft(3, '0')}";
    // 대체: 타임스탬프 사용 가능 ex) "A-${DateTime.now().millisecondsSinceEpoch}"
  }

  @override
  Future<void> createAssignment({
    required StudentRef student,
    required SubjectRef subject,
    required BookRef book,
    required String rangeLabel,
    required DateTime dueDate,
  }) async {
    final all = await _base.fetchAssignments();
    final id = _nextId(all);
    final newA = Assignment(
      id: id,
      subject: subject,
      book: book,
      assignedTo: student,
      rangeLabel: rangeLabel,
      dueDate: dueDate,
      isDone: false,
    );
    await _base.createAssignment(newA);
    await Future.delayed(const Duration(milliseconds: 120));
  }
}
