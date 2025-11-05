// lib/features/subjects/subjects_repository.dart
//
// 과목/책 읽기 전용 리포지토리 인터페이스
// (지금 단계: 로컬 목 데이터. 이후 AWS 붙일 때 동일 포트 유지)

import 'models.dart';

abstract class SubjectsRepository {
  /// 모든 과목 반환(정렬 포함)
  Future<List<Subject>> listSubjects();

  /// 특정 과목의 책 목록
  Future<List<Book>> listBooks(String subjectId);
}
