// lib/features/assignments/local_assignments_repository.dart
//
// DEV 목데이터 기반 배정 리포지토리
// - 'student-dev'에 대해 고정 배정 반환
// - 다른 studentId는 빈 번들 반환

import 'models.dart';
import 'assignments_repository.dart';

class LocalAssignmentsRepository implements AssignmentsRepository {
  static const _subjects = <AssignedSubject>[
    AssignedSubject(id: 'math', name: '수학'),
    AssignedSubject(id: 'eng',  name: '영어'),
    AssignedSubject(id: 'sci',  name: '과학'),
  ];

  static const _books = <AssignedBook>[
    AssignedBook(
      id: 'math-b01',
      subjectId: 'math',
      name: '유형특강 수학',
      progressPct: 38,
      todayRange: 'p.121–128',
    ),
    AssignedBook(
      id: 'eng-b01',
      subjectId: 'eng',
      name: 'VOCA 33000',
      progressPct: 52,
      todayRange: 'Day 21',
    ),
    AssignedBook(
      id: 'sci-b01',
      subjectId: 'sci',
      name: '과학 탐구 A',
      progressPct: 10,
      todayRange: '단원 1-2',
    ),
  ];

  @override
  Future<StudentAssignmentBundle> loadForStudent(String studentId) async {
    if (studentId == 'student-dev') {
      return const StudentAssignmentBundle(
        studentId: 'student-dev',
        subjects: _subjects,
        books: _books,
      );
    }
    return StudentAssignmentBundle(
      studentId: studentId,
      subjects: const [],
      books: const [],
    );
  }
}
