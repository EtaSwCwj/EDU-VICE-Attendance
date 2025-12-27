import 'package:amplify_flutter/amplify_flutter.dart';

class BookVolume {
  final int index;
  final String name;
  final int? answerStartPage;
  final int? answerEndPage;
  final int? totalPages;

  BookVolume({
    required this.index,
    required this.name,
    this.answerStartPage,
    this.answerEndPage,
    this.totalPages,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'answerStartPage': answerStartPage,
    'answerEndPage': answerEndPage,
    'totalPages': totalPages,
  };

  factory BookVolume.fromJson(Map<String, dynamic> json) {
    final volume = BookVolume(
      index: json['index'] as int,
      name: json['name'] as String,
      answerStartPage: json['answerStartPage'] as int?,
      answerEndPage: json['answerEndPage'] as int?,
      totalPages: json['totalPages'] as int?,
    );

    safePrint('[BookVolume] Volume 생성: index=${volume.index}, name=${volume.name}, totalPages=${volume.totalPages}');

    return volume;
  }
}
