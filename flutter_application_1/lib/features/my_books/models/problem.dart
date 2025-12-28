import 'package:amplify_flutter/amplify_flutter.dart';

/// 개별 문제 모델
/// - 페이지에서 분할된 각 문제를 표현
class Problem {
  final String id;
  final int page;           // 페이지 번호
  final int problemNumber;  // 문제 번호 (1, 2, 3...)
  final String volumeName;  // 소속 Volume
  final String imagePath;   // 크롭된 이미지 경로
  final Map<String, int> boundingBox; // {x, y, width, height}
  final DateTime createdAt;
  
  // 정답 관련 (나중에 확장)
  final bool? isCorrect;    // 정답 여부
  final String? answerImagePath; // 정답지 이미지

  Problem({
    required this.id,
    required this.page,
    required this.problemNumber,
    required this.volumeName,
    required this.imagePath,
    required this.boundingBox,
    DateTime? createdAt,
    this.isCorrect,
    this.answerImagePath,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'page': page,
    'problemNumber': problemNumber,
    'volumeName': volumeName,
    'imagePath': imagePath,
    'boundingBox': boundingBox,
    'createdAt': createdAt.toIso8601String(),
    'isCorrect': isCorrect,
    'answerImagePath': answerImagePath,
  };

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] as String,
      page: json['page'] as int,
      problemNumber: json['problemNumber'] as int,
      volumeName: json['volumeName'] as String,
      imagePath: json['imagePath'] as String,
      boundingBox: Map<String, int>.from(json['boundingBox'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCorrect: json['isCorrect'] as bool?,
      answerImagePath: json['answerImagePath'] as String?,
    );
  }

  Problem copyWith({
    String? id,
    int? page,
    int? problemNumber,
    String? volumeName,
    String? imagePath,
    Map<String, int>? boundingBox,
    DateTime? createdAt,
    bool? isCorrect,
    String? answerImagePath,
  }) {
    return Problem(
      id: id ?? this.id,
      page: page ?? this.page,
      problemNumber: problemNumber ?? this.problemNumber,
      volumeName: volumeName ?? this.volumeName,
      imagePath: imagePath ?? this.imagePath,
      boundingBox: boundingBox ?? this.boundingBox,
      createdAt: createdAt ?? this.createdAt,
      isCorrect: isCorrect ?? this.isCorrect,
      answerImagePath: answerImagePath ?? this.answerImagePath,
    );
  }

  @override
  String toString() => 'Problem(p$page-q$problemNumber, $volumeName)';
}
