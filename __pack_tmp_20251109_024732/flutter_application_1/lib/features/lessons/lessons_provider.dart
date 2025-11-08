// lib/features/lessons/lessons_provider.dart
//
// 레슨 주간 상태 공급자
// - loadWeek(anchorLocal): 현재 주(월~일) 레슨 로드
// - lessonsForDate(localDate): 해당 날짜 레슨 반환
// - todayLessons(): 오늘 레슨 간편 조회

import 'package:flutter/foundation.dart';
import 'models.dart';
import 'lessons_repository.dart';

class LessonsProvider extends ChangeNotifier {
  final LessonsRepository _repo;
  LessonsProvider(this._repo);

  bool _loading = false;
  bool get loading => _loading;

  // 주간 캐시(UTC 저장)
  List<Lesson> _weekLessons = const [];
  List<Lesson> get weekLessons => _weekLessons;

  // anchor 주(UTC Monday 00:00)
  DateTime? _anchorMondayUtc;

  Future<void> loadWeek({required String studentId, DateTime? anchorLocal}) async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final local = anchorLocal ?? DateTime.now();
      // 로컬 날짜 → UTC 정규화
      final anchorUtc = DateTime.utc(local.year, local.month, local.day);
      _weekLessons = await _repo.loadWeekLessonsForStudent(
        studentId: studentId,
        anchorUtc: anchorUtc,
      );

      // anchor 주의 Monday(UTC)
      final w = anchorUtc.weekday;
      _anchorMondayUtc = anchorUtc.subtract(Duration(days: w - DateTime.monday));
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 해당 로컬 날짜(연-월-일 매칭)의 레슨
  List<Lesson> lessonsForDate(DateTime localDate) {
    final y = localDate.year, m = localDate.month, d = localDate.day;
    return _weekLessons.where((les) {
      final ld = les.startUtc.toLocal();
      return ld.year == y && ld.month == m && ld.day == d;
    }).toList()
      ..sort((a, b) => a.startUtc.compareTo(b.startUtc));
  }

  List<Lesson> todayLessons() => lessonsForDate(DateTime.now());

  /// 주에 포함되는 로컬 날짜 배열(Mon..Sun)
  List<DateTime> weekDatesLocal() {
    final baseUtc = _anchorMondayUtc ?? DateTime.now().toUtc();
    final monLocal = baseUtc.toLocal();
    return List.generate(7, (i) {
      final d = monLocal.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }
}
