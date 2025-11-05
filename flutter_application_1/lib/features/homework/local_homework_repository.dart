// lib/features/homework/local_homework_repository.dart
//
// DEV 목데이터용 과제 리포지토리
// - 메모리 내부 리스트를 수정하여 반환
// - 앱 재시작 시 초기화되는 스텁

import 'dart:collection';
import 'models.dart';
import 'homework_repository.dart';

class LocalHomeworkRepository implements HomeworkRepository {
  // bookId별 초기 과제 세트
  static Map<String, List<HomeworkTask>> _seed(String studentId) {
    final now = DateTime.now();
    return {
      'math-b01': [
        HomeworkTask(
          id: 'h1',
          studentId: studentId,
          bookId: 'math-b01',
          title: '유형특강 4단원 복습',
          range: 'p.121-128',
          due: DateTime(now.year, now.month, now.day + 2),
          completed: false,
        ),
        HomeworkTask(
          id: 'h2',
          studentId: studentId,
          bookId: 'math-b01',
          title: '오답노트 정리',
          range: null,
          due: DateTime(now.year, now.month, now.day + 4),
          completed: false,
        ),
      ],
      'eng-b01': [
        HomeworkTask(
          id: 'h3',
          studentId: studentId,
          bookId: 'eng-b01',
          title: 'VOCA Day 21 테스트',
          range: 'Day 21',
          due: DateTime(now.year, now.month, now.day + 1),
          completed: false,
        ),
      ],
      'sci-b01': [
        HomeworkTask(
          id: 'h4',
          studentId: studentId,
          bookId: 'sci-b01',
          title: '탐구A 1-2 개념 요약',
          range: '단원 1-2',
          due: null,
          completed: false,
        ),
      ],
    };
  }

  final Map<String, Map<String, List<HomeworkTask>>> _store = HashMap();
  // _store[studentId] => { bookId: [tasks...] }

  List<HomeworkTask> _getList(String studentId, String bookId) {
    final byStudent = _store.putIfAbsent(studentId, () => _seed(studentId));
    return byStudent.putIfAbsent(bookId, () => _seed(studentId)[bookId] ?? <HomeworkTask>[]);
  }

  @override
  Future<List<HomeworkTask>> loadTasks({
    required String studentId,
    required String bookId,
  }) async {
    return List<HomeworkTask>.unmodifiable(_getList(studentId, bookId));
  }

  @override
  Future<List<HomeworkTask>> toggleComplete({
    required String studentId,
    required String bookId,
    required String taskId,
  }) async {
    final list = _getList(studentId, bookId);
    final idx = list.indexWhere((e) => e.id == taskId);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(completed: !list[idx].completed);
    }
    return List<HomeworkTask>.unmodifiable(list);
  }
}
