import 'package:equatable/equatable.dart';

enum HomeworkStatus {
  pending,    // 미완료
  submitted,  // 제출함 (학생 표시)
  graded,     // 평가 완료 (선생님 확인)
  overdue,    // 기한 지남
}

class Homework extends Equatable {
  final String id;
  final String academyId;
  final String studentId;
  final String teacherId;
  final String bookId;
  final String subject;
  
  final String title;
  final String description;
  final String? chapterRange; // "1-3과" or "p.30-45"
  
  final DateTime assignedAt;
  final DateTime dueDate;
  
  // 학생 제출 정보
  final bool isSubmitted;
  final DateTime? submittedAt;
  
  // 선생님 평가 정보
  final int? score; // 0-100
  final String? feedback;
  final DateTime? gradedAt;

  const Homework({
    required this.id,
    required this.academyId,
    required this.studentId,
    required this.teacherId,
    required this.bookId,
    required this.subject,
    required this.title,
    required this.description,
    this.chapterRange,
    required this.assignedAt,
    required this.dueDate,
    required this.isSubmitted,
    this.submittedAt,
    this.score,
    this.feedback,
    this.gradedAt,
  });

  HomeworkStatus get status {
    if (gradedAt != null) return HomeworkStatus.graded;
    if (isSubmitted) return HomeworkStatus.submitted;
    if (DateTime.now().isAfter(dueDate)) return HomeworkStatus.overdue;
    return HomeworkStatus.pending;
  }

  bool get isDueSoon {
    if (isSubmitted) return false;
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    return diff.inDays <= 1 && diff.inDays >= 0;
  }

  Homework copyWith({
    bool? isSubmitted,
    DateTime? submittedAt,
    int? score,
    String? feedback,
    DateTime? gradedAt,
  }) {
    return Homework(
      id: id,
      academyId: academyId,
      studentId: studentId,
      teacherId: teacherId,
      bookId: bookId,
      subject: subject,
      title: title,
      description: description,
      chapterRange: chapterRange,
      assignedAt: assignedAt,
      dueDate: dueDate,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
