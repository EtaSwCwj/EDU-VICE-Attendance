// lib/features/subjects/subjects_provider.dart
// ChangeNotifier: 과목/책 목록 로딩 + 선택 상태 관리 + 로컬 영구 저장(shared_preferences)

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'subjects_repository.dart';

class SubjectsProvider extends ChangeNotifier {
  final SubjectsRepository repository;
  SubjectsProvider(this.repository);

  // ---- 상태 ----
  bool _loading = false;
  bool get loading => _loading;

  List<Subject> _subjects = const [];
  List<Subject> get subjects => _subjects;

  List<Book> _books = const [];
  List<Book> get books => _books;

  String? _selectedSubjectId;
  String? get selectedSubjectId => _selectedSubjectId;

  String? _selectedBookId;
  String? get selectedBookId => _selectedBookId;

  // ---- 저장 키 ----
  static const _kKeySubject = 'selected_subject_id';
  static const _kKeyBook = 'selected_book_id';

  // ---- public API ----

  /// 앱 시작/화면 진입 시 호출: 목록 로딩 + 저장된 subject/book 복원
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      // 1) 과목 목록 로딩
      _subjects = await repository.getSubjects();

      // 2) 저장된 선택 복원
      final prefs = await SharedPreferences.getInstance();
      final savedSubject = prefs.getString(_kKeySubject);
      final savedBook = prefs.getString(_kKeyBook);

      // 저장된 과목이 현재 목록에 존재하면 복원
      if (savedSubject != null && _subjects.any((s) => s.id == savedSubject)) {
        _selectedSubjectId = savedSubject;
        // 과목 변경에 맞춘 책 목록 로드
        await _loadBooksFor(savedSubject);

        // 저장된 책도 유효하면 복원
        if (savedBook != null && _books.any((b) => b.id == savedBook)) {
          _selectedBookId = savedBook;
        } else {
          _selectedBookId = null;
        }
      } else {
        // 저장된 과목이 없거나 유효하지 않으면 초기화
        _selectedSubjectId = null;
        _books = const [];
        _selectedBookId = null;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 과목 선택(변경 시 책 목록 새로 로딩, 선택값 저장)
  Future<void> selectSubject(String? subjectId) async {
    if (_selectedSubjectId == subjectId) {
      // 동일 선택이면 무시해도 됨(그래도 저장은 해둔다)
      await _saveSelected(subjectId: subjectId, bookId: _selectedBookId);
      return;
    }

    _selectedSubjectId = subjectId;
    _selectedBookId = null;
    notifyListeners();

    if (subjectId == null || subjectId.isEmpty) {
      _books = const [];
      await _saveSelected(subjectId: null, bookId: null);
      notifyListeners();
      return;
    }

    await _loadBooksFor(subjectId);
    // 책 선택값은 null로 초기화된 상태
    await _saveSelected(subjectId: subjectId, bookId: null);
    notifyListeners();
  }

  /// 책 선택(선택값 저장)
  Future<void> selectBook(String? bookId) async {
    _selectedBookId = bookId;
    notifyListeners();
    await _saveSelected(subjectId: _selectedSubjectId, bookId: _selectedBookId);
  }

  // ---- internal ----
  Future<void> _loadBooksFor(String subjectId) async {
    _books = await repository.getBooksBySubject(subjectId);
    _selectedBookId = null;
  }

  Future<void> _saveSelected({
    required String? subjectId,
    required String? bookId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (subjectId == null || subjectId.isEmpty) {
      await prefs.remove(_kKeySubject);
      await prefs.remove(_kKeyBook);
      return;
    }
    await prefs.setString(_kKeySubject, subjectId);
    if (bookId == null || bookId.isEmpty) {
      await prefs.remove(_kKeyBook);
    } else {
      await prefs.setString(_kKeyBook, bookId);
    }
  }
}
