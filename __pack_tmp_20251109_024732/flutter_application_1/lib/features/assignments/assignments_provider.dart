// lib/features/assignments/assignments_provider.dart
//
// 학생에게 배정된 과목/책 상태

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'assignments_repository.dart';

class AssignmentsProvider extends ChangeNotifier {
  final AssignmentsRepository _repo;
  AssignmentsProvider(AssignmentsRepository repo) : _repo = repo;

  bool _loading = false;
  bool get loading => _loading;

  List<AssignedSubject> _subjects = const [];
  List<AssignedSubject> get subjects => _subjects;

  List<AssignedBook> _books = const [];
  List<AssignedBook> get books => _books;

  String? _lastStudent;

  Future<void> load({required String studentId}) async {
    if (_loading) return;
    if (_lastStudent == studentId && _subjects.isNotEmpty) return;

    _loading = true;
    notifyListeners();
    try {
      // ✅ 실제 포트 시그니처: Future<StudentAssignmentBundle> loadForStudent(String studentId)
      final bundle = await _repo.loadForStudent(studentId);
      _subjects = bundle.subjects;
      _books = bundle.books;
      _lastStudent = studentId;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 과목 ID에 연결된 책 목록
  List<AssignedBook> booksFor(String subjectId) {
    return _books.where((b) => b.subjectId == subjectId).toList(growable: false);
  }
}
