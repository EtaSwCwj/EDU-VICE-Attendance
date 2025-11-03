// lib/features/subjects/local_subjects_repository.dart
// 로컬 스텁 구현 (하드코딩). 이후 AWS로 구현 교체 가능.

import 'dart:async';
import 'models.dart';
import 'subjects_repository.dart';

class LocalSubjectsRepository implements SubjectsRepository {
  static const List<Subject> _subjects = [
    Subject(id: 'math', name: '수학'),
    Subject(id: 'eng',  name: '영어'),
    Subject(id: 'sci',  name: '과학'),
  ];

  static const List<Book> _books = [
    Book(id: 'm1', name: '개념수학 1', subjectId: 'math'),
    Book(id: 'm2', name: '유형특강 수학', subjectId: 'math'),
    Book(id: 'e1', name: 'Grammar Master', subjectId: 'eng'),
    Book(id: 'e2', name: 'Reading Power', subjectId: 'eng'),
    Book(id: 's1', name: '과학 개념노트', subjectId: 'sci'),
    Book(id: 's2', name: '실험으로 배우는 과학', subjectId: 'sci'),
  ];

  @override
  Future<List<Subject>> getSubjects() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return _subjects;
  }

  @override
  Future<List<Book>> getBooksBySubject(String subjectId) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return _books.where((b) => b.subjectId == subjectId).toList();
  }
}
