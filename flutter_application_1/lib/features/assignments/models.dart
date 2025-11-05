// lib/features/assignments/models.dart
//
// 학생 배정(Assignments) 도메인 스텁 모델

class AssignedSubject {
  final String id;   // 'math' | 'eng' | 'sci'
  final String name; // 표시명

  const AssignedSubject({required this.id, required this.name});
}

class AssignedBook {
  final String id;         // 'math-b01' 등
  final String subjectId;  // 연결 과목 id
  final String name;       // 표시명
  final int? progressPct;  // 진행률(0~100, 옵션)
  final String? todayRange; // 오늘 할 분량 텍스트(옵션)

  const AssignedBook({
    required this.id,
    required this.subjectId,
    required this.name,
    this.progressPct,
    this.todayRange,
  });
}

class StudentAssignmentBundle {
  final String studentId;
  final List<AssignedSubject> subjects;
  final List<AssignedBook> books;

  const StudentAssignmentBundle({
    required this.studentId,
    required this.subjects,
    required this.books,
  });
}
