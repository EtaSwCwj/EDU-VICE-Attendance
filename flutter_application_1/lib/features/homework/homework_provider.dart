// lib/features/homework/homework_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homework_repository.dart';
import 'models.dart';

/// 과제 목록/필터/상태 변경 + 현황 카운트/라벨 + 영속화(SharedPreferences) + 날짜 필터
class HomeworkProvider extends ChangeNotifier {
  HomeworkProvider(this._repo);

  final HomeworkRepository _repo;

  List<Assignment> _all = [];
  String? _selectedSubjectId;
  String? _selectedBookId;

  DateTime? _selectedDate; // 타임라인/달력 연동용 (해당 날짜 마감 과제만 보기)
  bool _loading = false;

  bool get loading => _loading;
  DateTime? get selectedDate => _selectedDate;

  // ---------- 공개 게터 ----------
  List<Assignment> get items {
    Iterable<Assignment> out = _all;

    // 과목/책 필터
    if (_selectedSubjectId != null && _selectedSubjectId!.isNotEmpty) {
      out = out.where((a) => a.subject.id == _selectedSubjectId);
    }
    if (_selectedBookId != null && _selectedBookId!.isNotEmpty) {
      out = out.where((a) => a.book.id == _selectedBookId);
    }

    // 날짜 필터(선택된 경우, 해당 날짜에 마감되는 과제만)
    if (_selectedDate != null) {
      final pick = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      out = out.where((a) {
        final due = DateTime(a.dueDate.year, a.dueDate.month, a.dueDate.day);
        return due == pick;
      });
    }

    // 타임라인 정합성: 지남 → 임박 → 진행중 → 제출됨
    final list = out.toList()
      ..sort((a, b) {
        int rank(Assignment x) {
          if (x.status == AssignmentStatus.overdue) return 0;
          if (!x.isDone && x.isDueSoon) return 1;
          if (x.status == AssignmentStatus.pending) return 2;
          return 3; // completed(= 제출됨)
        }
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        // 같은 그룹 내에서는 마감일 오름차순
        return a.dueDate.compareTo(b.dueDate);
      });
    return list;
  }

  // 필터 드롭다운 옵션
  List<SubjectRef> get subjectOptions {
    final map = <String, SubjectRef>{};
    for (final a in _all) {
      map[a.subject.id] = a.subject;
    }
    return map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<BookRef> get bookOptions {
    final map = <String, BookRef>{};
    for (final a in _all) {
      if (_selectedSubjectId == null || a.subject.id == _selectedSubjectId) {
        map[a.book.id] = a.book;
      }
    }
    return map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  // 선택 상태
  String? get selectedSubjectId => _selectedSubjectId;
  String? get selectedBookId => _selectedBookId;

  // 라벨 헬퍼(필터 칩용)
  String? get selectedSubjectName =>
      _nameById(subjectOptions.map((e) => MapEntry(e.id, e.name)).toList(), _selectedSubjectId);
  String? get selectedBookName =>
      _nameById(bookOptions.map((e) => MapEntry(e.id, e.name)).toList(), _selectedBookId);

  // 현황 카운트
  int get overdueCount => items.where((a) => a.status == AssignmentStatus.overdue).length;
  int get dueSoonCount => items.where((a) => !a.isDone && a.isDueSoon).length;
  int get pendingCount =>
      items.where((a) => a.status == AssignmentStatus.pending && !a.isDueSoon).length;
  int get completedCount => items.where((a) => a.status == AssignmentStatus.completed).length;

  // ---------- 동작 ----------
  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      // 1) 저장소에서 로드
      final raw = await _repo.fetchAssignments();
      // 2) prefs 오버레이 적용(제출 표시 영속화)
      _all = await _applyPrefsOverlay(raw);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectSubject(String? id) {
    _selectedSubjectId = (id?.isEmpty ?? true) ? null : id;
    // 과목 변경 시 책 필터 초기화
    _selectedBookId = null;
    notifyListeners();
  }

  void selectBook(String? id) {
    _selectedBookId = (id?.isEmpty ?? true) ? null : id;
    notifyListeners();
  }

  void resetFilters() {
    _selectedSubjectId = null;
    _selectedBookId = null;
    _selectedDate = null;
    notifyListeners();
  }

  void clearSubject() {
    _selectedSubjectId = null;
    notifyListeners();
  }

  void clearBook() {
    _selectedBookId = null;
    notifyListeners();
  }

  void setSelectedDate(DateTime? date) {
    if (date == null) {
      _selectedDate = null;
    } else {
      _selectedDate = DateTime(date.year, date.month, date.day);
    }
    notifyListeners();
  }

  Future<void> toggleDone(Assignment a) async {
    final next = a.copyWith(isDone: !a.isDone);
    // 1) 저장소 업데이트
    await _repo.updateAssignment(next);
    // 2) 로컬 상태 업데이트
    final idx = _all.indexWhere((e) => e.id == a.id);
    if (idx >= 0) _all[idx] = next;
    notifyListeners();
    // 3) 영속화 반영
    await _savePrefFlag(next.id, next.isDone);
  }

  // ---------- 내부 (SharedPreferences 오버레이) ----------
  static const _prefsPrefix = "hw_submitted_"; // + assignmentId -> bool

  Future<List<Assignment>> _applyPrefsOverlay(List<Assignment> src) async {
    final prefs = await SharedPreferences.getInstance();
    return src.map((a) {
      final key = "$_prefsPrefix${a.id}";
      final persisted = prefs.getBool(key);
      if (persisted == null) return a;
      return a.copyWith(isDone: persisted);
    }).toList(growable: false);
  }

  Future<void> _savePrefFlag(String assignmentId, bool isDone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("$_prefsPrefix$assignmentId", isDone);
  }

  String? _nameById(List<MapEntry<String, String>> pairs, String? id) {
    if (id == null) return null;
    for (final e in pairs) {
      if (e.key == id) return e.value;
    }
    return null;
  }
}
