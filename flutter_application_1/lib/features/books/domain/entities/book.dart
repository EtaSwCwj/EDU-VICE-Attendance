import 'package:equatable/equatable.dart';

class Book extends Equatable {
  final String id;
  final String academyId;
  final String title;
  final String subject;
  final String? grade;
  final String? imageUrl;
  final List<String> chapters;
  final int publishYear;
  final DateTime createdAt;

  const Book({
    required this.id,
    required this.academyId,
    required this.title,
    required this.subject,
    this.grade,
    this.imageUrl,
    required this.chapters,
    required this.publishYear,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

class BookProgress extends Equatable {
  final String bookId;
  final String studentId;
  final Map<int, ChapterProgress> chapters; // chapterIndex -> progress

  const BookProgress({
    required this.bookId,
    required this.studentId,
    required this.chapters,
  });

  double get overallProgress {
    if (chapters.isEmpty) return 0.0;
    final completed = chapters.values.where((c) => c.isCompleted).length;
    return completed / chapters.length;
  }

  @override
  List<Object?> get props => [bookId, studentId];
}

class ChapterProgress extends Equatable {
  final int chapterIndex;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? note;

  const ChapterProgress({
    required this.chapterIndex,
    required this.isCompleted,
    this.completedAt,
    this.note,
  });

  @override
  List<Object?> get props => [chapterIndex];
}
