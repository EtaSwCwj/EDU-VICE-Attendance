// lib/features/subjects/local_subjects_repository.dart
//
// 로컬 목 데이터 소스(파일/네트워크 없이 앱 내 하드코딩)
//
// 유지 원칙
// - id는 짧고 안정적으로: 'math','eng','sci'
// - 책 id는 '<subject>-b##' 규칙

import 'models.dart';
import 'subjects_repository.dart';

class LocalSubjectsRepository implements SubjectsRepository {
  static const _subjects = <Subject>[
    Subject(id: 'math', name: '수학'),
    Subject(id: 'eng',  name: '영어'),
    Subject(id: 'sci',  name: '과학'),
  ];

  static const _books = <Book>[
    Book(id: 'math-b01', subjectId: 'math', name: '유형특강 수학'),
    Book(id: 'math-b02', subjectId: 'math', name: '기출 분석 수학'),
    Book(id: 'eng-b01',  subjectId: 'eng',  name: 'VOCA 33000'),
    Book(id: 'eng-b02',  subjectId: 'eng',  name: '구문 독해'),
    Book(id: 'sci-b01',  subjectId: 'sci',  name: '과학 탐구 A'),
    Book(id: 'sci-b02',  subjectId: 'sci',  name: '실험 노트 B'),
  ];

  @override
  Future<List<Subject>> listSubjects() async {
    // 알파벳 id 기준 정렬(표시명 정렬이 필요하면 name으로 변경)
    final list = List<Subject>.from(_subjects)..sort((a, b) => a.id.compareTo(b.id));
    return list;
  }

  @override
  Future<List<Book>> listBooks(String subjectId) async {
    final list = _books.where((b) => b.subjectId == subjectId).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list;
    // 없는 subjectId면 빈 배열 반환(예외 X)
  }
}
