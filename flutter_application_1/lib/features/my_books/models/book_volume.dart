import 'package:amplify_flutter/amplify_flutter.dart';

/// 책의 분권(Volume) 모델
/// 
/// 예: 본책 1~200페이지, 워크북 1~50페이지
/// 각 Volume은 독립적인 페이지 번호 체계를 가짐
class BookVolume {
  final int index;
  final String name;
  
  /// 이 Volume의 시작 페이지 (보통 1)
  final int? startPage;
  
  /// 이 Volume의 끝 페이지
  final int? endPage;
  
  /// 총 페이지 수 (endPage - startPage + 1)
  final int? totalPages;

  // Legacy 필드 (하위 호환성)
  final int? answerStartPage;
  final int? answerEndPage;

  BookVolume({
    required this.index,
    required this.name,
    this.startPage,
    this.endPage,
    this.totalPages,
    this.answerStartPage,
    this.answerEndPage,
  });

  /// 실제 시작 페이지 (기본값 1)
  int get effectiveStartPage => startPage ?? answerStartPage ?? 1;
  
  /// 실제 끝 페이지
  int? get effectiveEndPage => endPage ?? answerEndPage;
  
  /// 실제 총 페이지 수
  int get effectiveTotalPages {
    if (totalPages != null) return totalPages!;
    final end = effectiveEndPage;
    if (end != null) {
      return end - effectiveStartPage + 1;
    }
    return 0;
  }

  /// 페이지 범위가 설정되었는지
  bool get hasPageRange => effectiveTotalPages > 0;

  /// 페이지 범위 문자열 (예: "1~200")
  String get pageRangeString {
    if (!hasPageRange) return '미설정';
    return '$effectiveStartPage~${effectiveEndPage ?? "?"}';
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'startPage': startPage,
    'endPage': endPage,
    'totalPages': totalPages,
    // Legacy 필드도 저장 (하위 호환)
    'answerStartPage': answerStartPage ?? startPage,
    'answerEndPage': answerEndPage ?? endPage,
  };

  factory BookVolume.fromJson(Map<String, dynamic> json) {
    final volume = BookVolume(
      index: json['index'] as int,
      name: json['name'] as String,
      startPage: json['startPage'] as int?,
      endPage: json['endPage'] as int?,
      totalPages: json['totalPages'] as int?,
      answerStartPage: json['answerStartPage'] as int?,
      answerEndPage: json['answerEndPage'] as int?,
    );

    safePrint('[BookVolume] ${volume.name}: ${volume.pageRangeString} (${volume.effectiveTotalPages}p)');

    return volume;
  }

  BookVolume copyWith({
    int? index,
    String? name,
    int? startPage,
    int? endPage,
    int? totalPages,
    int? answerStartPage,
    int? answerEndPage,
  }) {
    return BookVolume(
      index: index ?? this.index,
      name: name ?? this.name,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      totalPages: totalPages ?? this.totalPages,
      answerStartPage: answerStartPage ?? this.answerStartPage,
      answerEndPage: answerEndPage ?? this.answerEndPage,
    );
  }
}
