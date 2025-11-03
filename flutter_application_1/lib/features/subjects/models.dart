// lib/features/subjects/models.dart
// 과목/책 도메인 모델

class Subject {
  final String id;
  final String name;

  const Subject({required this.id, required this.name});
}

class Book {
  final String id;
  final String name;
  final String subjectId; // 소속 과목

  const Book({
    required this.id,
    required this.name,
    required this.subjectId,
  });
}
