// lib/features/teacher_homework/teacher_homework_provider.dart
import 'package:flutter/foundation.dart';

import '../homework/models.dart';
import 'teacher_homework_repository.dart';

class TeacherHomeworkProvider extends ChangeNotifier {
  TeacherHomeworkProvider(this._repo);

  final TeacherHomeworkRepository _repo;

  List<StudentRef> _students = [];
  String? _selectedStudentId;

  List<Assignment> _items = []; // 선택 학생의 전체 과제
  String? _selectedSubjectId;   // 과목 필터
  String _studentQuery = "";    // 학생 검색어
  bool _loading = false;

  bool get loading => _loading;
  List<StudentRef> get students => _students;
  String? get selectedStudentId => _selectedStudentId;

  // 선택 학생의 과제 중 과목 필터가 적용된 목록
  List<Assignment> get items {
    Iterable<Assignment> out = _items;
    if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty) {
      out = out.where((a) => a.subject.id == _selectedSubjectId);
    }
    // 기본 정렬: 확인대기 → 제출대기(지남/임박/기타) → 확정(완료/부분/미완료), 마감일 오름차순
    final list = out.toList()
      ..sort((a, b) {
        int rank(Assignment x) {
          final checked = x.teacherCheckedAt != null && x.checkResult != null;
          if (!checked && x.isDone) return 0; // 확인 대기(학생 제출됨)
          // 제출 대기
          final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
          final due = DateTime(x.dueDate.year, x.dueDate.month, x.dueDate.day);
          if (!x.isDone && due.isBefore(today)) return 1; // 지남
          if (!x.isDone && x.isDueSoon) return 2;         // 임박
          if (!x.isDone) return 3;                        // 기타 진행중
          // 확정
          return 4;
        }
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return a.dueDate.compareTo(b.dueDate);
      });
    return list;
  }

  String? get selectedSubjectId => _selectedSubjectId;
  List<SubjectRef> get subjectOptions {
    final map = <String, SubjectRef>{};
    for (final a in _items) {
      map[a.subject.id] = a.subject;
    }
    final out = map.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  // ---------- 학생 목록 로드/검색 ----------
  Future<void> loadStudents({String? query}) async {
    _loading = true;
    notifyListeners();
    try {
      _studentQuery = (query ?? "").trim();
      _students = await _repo.fetchStudents(query: _studentQuery.isEmpty ? null : _studentQuery);
      // 기존 선택 유지, 없으면 첫 학생 자동 선택
      if (_selectedStudentId == null || !_students.any((s) => s.id == _selectedStudentId)) {
        _selectedStudentId = _students.isNotEmpty ? _students.first.id : null;
      }
      if (_selectedStudentId != null) {
        await _loadAssignmentsFor(_selectedStudentId!);
      } else {
        _items = [];
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectStudent(String? id) async {
    _selectedStudentId = (id == null || id.isEmpty) ? null : id;
    _items = [];
    _selectedSubjectId = null;
    notifyListeners();
    if (_selectedStudentId != null) {
      await _loadAssignmentsFor(_selectedStudentId!);
    }
  }

  Future<void> _loadAssignmentsFor(String studentId) async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _repo.fetchAssignmentsByStudent(studentId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------- 과목 필터 ----------
  void selectSubject(String? id) {
    _selectedSubjectId = (id == null || id.isEmpty) ? null : id;
    notifyListeners();
  }

  void resetSubjectFilter() {
    _selectedSubjectId = null;
    notifyListeners();
  }

  // ---------- 검사 결과 확정 ----------
  Future<void> setCheckResult({
    required Assignment assignment,
    required CheckResult result,
  }) async {
    await _repo.teacherCheck(
      assignmentId: assignment.id,
      result: result,
      checkedAt: DateTime.now(),
    );
    // 로컬 반영
    final idx = _items.indexWhere((e) => e.id == assignment.id);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(
        teacherCheckedAt: DateTime.now(),
        checkResult: result,
      );
      notifyListeners();
    }
  }
}
