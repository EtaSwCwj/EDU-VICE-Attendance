// lib/domain/value/date_range.dart
//
// 출석/진도 등 조회 범위를 나타내는 UTC 기준 날짜 범위 객체.
// - start: 포함(inclusive, UTC)
// - end  : 제외(exclusive, UTC)
//
// 예)
//   final r = DateRange(
//     start: DateTime.utc(2025, 10, 1),
//     end:   DateTime.utc(2025, 11, 1),
//   );

class DateRange {
  /// [start]는 포함(inclusive, UTC), [end]는 제외(exclusive, UTC)
  final DateTime? start;
  final DateTime? end;

  const DateRange({this.start, this.end});

  /// 범위 미지정(빈 범위)
  static const empty = DateRange();

  /// 유효성 검사: 둘 다 있으면 start < end 이어야 함
  bool get isValid {
    if (start == null || end == null) return true;
    return start!.isBefore(end!);
  }

  /// 모든 값을 UTC로 강제한 사본
  DateRange toUtc() => DateRange(
        start: start?.toUtc(),
        end: end?.toUtc(),
      );

  @override
  String toString() => 'DateRange(start: $start, end: $end)';
}
