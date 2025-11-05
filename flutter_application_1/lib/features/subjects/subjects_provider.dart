// lib/features/subjects/subjects_provider.dart
//
// ChangeNotifier로 과목/책 상태 제공(출석/숙제 등에서 공용)
// - load(): 과목 목록 로딩 + 저장된 선택 복원
// - selectSubject(id), selectBook(id): 선택 변경 및 영속화(SharedPreferences)
// - books: 현재 과목의 책 목록을 유지
//
// 주의: 비동기 순서 안전을 위해 로딩 중 중복 호출/경쟁상태 방지

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'subjects_repository.dart';

class SubjectsProvider extends ChangeNotifier {
  final SubjectsRepository _repo;

  SubjectsProvider(this._repo);

  // 로딩 상태
  bool _loading = false;
  bool get loading => _loading;

  // 전체 과목 목록
  List<Subject> _subjects = const [];
  List<Subject> get subjects => _subjects;

  // 현재 과목 선택
  String? _selectedSubjectId;
  String? get selectedSubjectId => _selectedSubjectId;

  // 현재 과목의 책 목록
  List<Book> _books = const [];
  List<Book> get books => _books;

  // 현재 책 선택
  String? _selectedBookId;
  String? get selectedBookId => _selectedBookId;

  static const _kSubjectPref = 'selectedSubjectId';
  static const _kBookPref = 'selectedBookId';

  /// 초기 로딩 + 저장된 선택 복원
  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1) 과목 목록
      final subs = await _repo.listSubjects();
      _subjects = subs;

      // 2) 저장된 과목/책 선택 복원
      final restoredSubject = prefs.getString(_kSubjectPref);
      final restoredBook = prefs.getString(_kBookPref);

      if (restoredSubject != null &&
          _subjects.any((s) => s.id == restoredSubject)) {
        _selectedSubjectId = restoredSubject;
        _books = await _repo.listBooks(restoredSubject);

        if (restoredBook != null &&
            _books.any((b) => b.id == restoredBook)) {
          _selectedBookId = restoredBook;
        } else {
          _selectedBookId = null;
        }
      } else {
        // 저장된 값이 없거나/무효: 첫 과목으로 초기화(있다면)
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first.id;
          _books = await _repo.listBooks(_selectedSubjectId!);
          _selectedBookId = null;
        } else {
          _selectedSubjectId = null;
          _books = const [];
          _selectedBookId = null;
        }
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 과목 선택 변경(책 초기화 포함)
  Future<void> selectSubject(String? subjectId) async {
    if (_selectedSubjectId == subjectId) return;

    _selectedSubjectId = subjectId;
    _selectedBookId = null;

    if (subjectId == null) {
      _books = const [];
    } else {
      _books = await _repo.listBooks(subjectId);
    }

    // 영속화
    final prefs = await SharedPreferences.getInstance();
    if (subjectId == null) {
      await prefs.remove(_kSubjectPref);
      await prefs.remove(_kBookPref);
    } else {
      await prefs.setString(_kSubjectPref, subjectId);
      await prefs.remove(_kBookPref);
    }

    notifyListeners();
  }

  /// 책 선택 변경
  Future<void> selectBook(String? bookId) async {
    _selectedBookId = bookId;

    final prefs = await SharedPreferences.getInstance();
    if (bookId == null) {
      await prefs.remove(_kBookPref);
    } else {
      await prefs.setString(_kBookPref, bookId);
    }

    notifyListeners();
  }
}
