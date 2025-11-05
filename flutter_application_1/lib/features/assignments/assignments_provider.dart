// lib/features/assignments/assignments_provider.dart
//
// 학생 배정 상태 공급자(학습 탭/학생 홈에서 사용 예정)
// - load(studentId): 배정 로드(미지정 시 'student-dev')
// - selectSubject / selectBook: 배정 범위 내에서만 선택 허용
// - API는 SubjectsProvider와 유사(향후 교체 용이)

import 'package:flutter/foundation.dart';
import 'models.dart';
import 'assignments_repository.dart';

class AssignmentsProvider extends ChangeNotifier {
  final AssignmentsRepository _repo;

  AssignmentsProvider(this._repo);

  bool _loading = false;
  bool get loading => _loading;

  String? _studentId;
  String? get studentId => _studentId;

  List<AssignedSubject> _subjects = const [];
  List<AssignedSubject> get subjects => _subjects;

  String? _selectedSubjectId;
  String? get selectedSubjectId => _selectedSubjectId;

  List<AssignedBook> _books = const [];
  List<AssignedBook> get books => _books.where(
        (b) => _selectedSubjectId == null ? true : b.subjectId == _selectedSubjectId,
      ).toList();

  String? _selectedBookId;
  String? get selectedBookId => _selectedBookId;

  Future<void> load({String? studentId}) async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      _studentId = studentId ?? 'student-dev';
      final bundle = await _repo.loadForStudent(_studentId!);

      _subjects = bundle.subjects;
      _books = bundle.books;

      // 기본 선택: 첫 과목 → 그 과목의 첫 책
      if (_subjects.isNotEmpty) {
        _selectedSubjectId = _subjects.first.id;
        final firstBooks =
            _books.where((b) => b.subjectId == _selectedSubjectId).toList();
        _selectedBookId = firstBooks.isNotEmpty ? firstBooks.first.id : null;
      } else {
        _selectedSubjectId = null;
        _selectedBookId = null;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectSubject(String? subjectId) async {
    if (_selectedSubjectId == subjectId) return;
    _selectedSubjectId = subjectId;

    final candidates = _books
        .where((b) => subjectId == null ? false : b.subjectId == subjectId)
        .toList();
    _selectedBookId = candidates.isNotEmpty ? candidates.first.id : null;
    notifyListeners();
  }

  Future<void> selectBook(String? bookId) async {
    // 배정된 책만 선택 허용
    if (bookId != null && !_books.any((b) => b.id == bookId)) return;
    _selectedBookId = bookId;
    notifyListeners();
  }
}
