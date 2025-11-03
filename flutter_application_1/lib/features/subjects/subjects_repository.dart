// lib/features/subjects/subjects_repository.dart
// 데이터 소스 추상화: 나중에 AWS로 교체 예정

import 'models.dart';

abstract class SubjectsRepository {
  Future<List<Subject>> getSubjects();
  Future<List<Book>> getBooksBySubject(String subjectId);
}
