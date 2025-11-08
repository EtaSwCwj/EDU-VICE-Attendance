// lib/features/progress/local_progress_repository.dart
//
// DEV용 로컬 스텁 구현
// - 단순 시드 데이터 반환(시간순 내림차순)

import 'dart:math';
import 'models.dart';
import 'progress_repository.dart';

class LocalProgressRepository implements ProgressRepository {
  final Random _rng = Random(7);

  @override
  Future<List<ProgressEntry>> loadTimeline({
    required String studentId,
    required String subjectId,
    String? bookId,
    int limit = 20,
  }) async {
    // 최근 n회 수업을 가정한 시뮬레이션 데이터
    final now = DateTime.now().toUtc();
    final out = <ProgressEntry>[];
    int lastTo = 150;

    for (int i = 0; i < limit; i++) {
      final dayBack = (i + 1) * 3; // 3일 간격으로 거꾸로 생성(예시)
      final when = now.subtract(Duration(days: dayBack, hours: 19));

      final size = 6 + _rng.nextInt(6); // 6~11p
      final from = (lastTo - size).clamp(1, 999);
      final to = lastTo;
      lastTo = from - 1;

      out.add(
        ProgressEntry(
          id: 'prg-${when.millisecondsSinceEpoch}-$subjectId',
          academyId: 'academy-dev',
          studentId: studentId,
          teacherId: 't-001',
          subjectId: subjectId,
          bookId: bookId,
          createdAtUtc: when,
          pageFrom: from,
          pageTo: to,
          note: '집중도 보통, 숙제는 다음 범위 예고',
        ),
      );
    }

    out.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return out;
  }
}
