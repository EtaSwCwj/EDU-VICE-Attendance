// lib/features/progress/progress_provider.dart
//
// 진도 타임라인 상태

import 'package:flutter/foundation.dart';
import 'models.dart';
import 'progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _repo;
  ProgressProvider(this._repo);

  bool _loading = false;
  bool get loading => _loading;

  List<ProgressEntry> _items = const [];
  List<ProgressEntry> get items => _items;

  String? _lastStudent;
  String? _lastSubject;
  String? _lastBook;

  Future<void> load({
    required String studentId,
    required String subjectId,
    String? bookId,
  }) async {
    // 같은 요청이면 스킵(빌드 중 재호출 방지)
    if (_lastStudent == studentId &&
        _lastSubject == subjectId &&
        _lastBook == bookId &&
        _items.isNotEmpty) {
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final list = await _repo.loadTimeline(
        studentId: studentId,
        subjectId: subjectId,
        bookId: bookId,
        limit: 20,
      );
      _items = list;
      _lastStudent = studentId;
      _lastSubject = subjectId;
      _lastBook = bookId;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 전체 진행률(예: 최근 기록의 pageTo를 단순 지표로 사용)
  int? latestPageTo() {
    if (_items.isEmpty) return null;
    return _items
        .where((e) => e.pageTo != null)
        .map((e) => e.pageTo!)
        .fold<int>(0, (max, v) => v > max ? v : max);
  }
}
