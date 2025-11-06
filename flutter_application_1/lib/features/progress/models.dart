// lib/features/progress/models.dart
//
// 진도(Progress) 도메인 모델
// - 모든 시간은 UTC 보관
// - 이후 AWS 이식 시 스키마 유지 가정

class ProgressEntry {
  final String id;              // "prg-<timestamp>-<subjectId>"
  final String academyId;       // 예: "academy-dev"
  final String studentId;       // 예: "student-dev"
  final String teacherId;       // 예: "t-001"
  final String subjectId;       // 예: "math"
  final String? bookId;         // 책이 없는 과제형 진도는 null 허용
  final DateTime createdAtUtc;  // 기록 시각(UTC)

  // 책 범위 기록(예: p.121~128)
  final int? pageFrom;
  final int? pageTo;

  // 자유 메모(선생 코멘트 등)
  final String? note;

  const ProgressEntry({
    required this.id,
    required this.academyId,
    required this.studentId,
    required this.teacherId,
    required this.subjectId,
    required this.bookId,
    required this.createdAtUtc,
    this.pageFrom,
    this.pageTo,
    this.note,
  });
}
