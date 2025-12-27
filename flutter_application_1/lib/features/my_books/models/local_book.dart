import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class LocalBook extends Equatable {
  final String id;
  final String title;
  final String publisher;
  final String subject; // ENGLISH, MATH, KOREAN, SCIENCE
  final int totalPages;
  final String? coverImagePath; // 로컬 이미지 경로
  final List<int> registeredPages; // 정답지 등록된 페이지들
  final DateTime createdAt;
  final DateTime updatedAt;

  LocalBook({
    String? id,
    required this.title,
    required this.publisher,
    required this.subject,
    required this.totalPages,
    this.coverImagePath,
    List<int>? registeredPages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        registeredPages = registeredPages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'publisher': publisher,
      'subject': subject,
      'totalPages': totalPages,
      'coverImagePath': coverImagePath,
      'registeredPages': registeredPages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LocalBook.fromJson(Map<String, dynamic> json) {
    return LocalBook(
      id: json['id'] as String,
      title: json['title'] as String,
      publisher: json['publisher'] as String,
      subject: json['subject'] as String,
      totalPages: json['totalPages'] as int,
      coverImagePath: json['coverImagePath'] as String?,
      registeredPages: (json['registeredPages'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  LocalBook copyWith({
    String? id,
    String? title,
    String? publisher,
    String? subject,
    int? totalPages,
    String? coverImagePath,
    List<int>? registeredPages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalBook(
      id: id ?? this.id,
      title: title ?? this.title,
      publisher: publisher ?? this.publisher,
      subject: subject ?? this.subject,
      totalPages: totalPages ?? this.totalPages,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      registeredPages: registeredPages ?? this.registeredPages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progress {
    if (totalPages == 0) return 0.0;
    return registeredPages.length / totalPages;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        publisher,
        subject,
        totalPages,
        coverImagePath,
        registeredPages,
        createdAt,
        updatedAt,
      ];
}