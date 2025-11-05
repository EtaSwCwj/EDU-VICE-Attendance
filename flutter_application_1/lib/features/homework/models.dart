// lib/features/homework/models.dart
//
// 학생 과제(숙제) 도메인 스텁

class HomeworkTask {
  final String id;
  final String studentId; // 'student-dev'
  final String bookId;    // 배정된 책 id
  final String title;     // 표시 제목
  final String? range;    // 'p.121-128' 등
  final DateTime? due;    // 마감일(옵션)
  final bool completed;   // 완료 여부

  const HomeworkTask({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.title,
    this.range,
    this.due,
    required this.completed,
  });

  HomeworkTask copyWith({
    String? id,
    String? studentId,
    String? bookId,
    String? title,
    String? range,
    DateTime? due,
    bool? completed,
  }) {
    return HomeworkTask(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      range: range ?? this.range,
      due: due ?? this.due,
      completed: completed ?? this.completed,
    );
    }
}
