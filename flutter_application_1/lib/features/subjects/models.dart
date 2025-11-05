// lib/features/subjects/models.dart
//
// 과목/책 도메인 모델 (간단 · 불변)
//
// 설계 포인트
// - id: 앱 전역에서 유일(예: 'math', 'eng', 'sci', 'math-b01')
// - name: 표시용 이름
// - ==/hashCode 오버라이드로 비교 안정화

class Subject {
  final String id;   // 'math' | 'eng' | 'sci' ...
  final String name; // '수학' | '영어' | '과학' ...

  const Subject({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Book {
  final String id;        // 'math-b01' 등
  final String subjectId; // 참조: Subject.id
  final String name;      // '유형특강 수학' 등

  const Book({
    required this.id,
    required this.subjectId,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
