import 'package:equatable/equatable.dart';

class TocEntry extends Equatable {
  final String unitName;
  final int startPage;
  final int? endPage;

  const TocEntry({
    required this.unitName,
    required this.startPage,
    this.endPage,
  });

  factory TocEntry.fromJson(Map<String, dynamic> json) {
    return TocEntry(
      unitName: json['unitName'] as String? ?? '',
      startPage: json['startPage'] as int? ?? 0,  // null이면 0
      endPage: json['endPage'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitName': unitName,
      'startPage': startPage,
      'endPage': endPage,
    };
  }

  TocEntry copyWith({
    String? unitName,
    int? startPage,
    int? endPage,
  }) {
    return TocEntry(
      unitName: unitName ?? this.unitName,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
    );
  }

  @override
  List<Object?> get props => [unitName, startPage, endPage];
}