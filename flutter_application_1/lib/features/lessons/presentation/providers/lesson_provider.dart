import 'package:flutter/foundation.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/usecases/get_today_lessons.dart';
import '../../domain/usecases/create_recurring_lessons.dart';
import '../../domain/usecases/record_lesson_evaluation.dart';
import '../../domain/repositories/lesson_repository.dart';

class LessonProvider extends ChangeNotifier {
  final LessonRepository _repository;
  final GetTodayLessons _getTodayLessons;
  final CreateRecurringLessons _createRecurringLessons;
  final RecordLessonEvaluation _recordEvaluation;

  LessonProvider(this._repository)
      : _getTodayLessons = GetTodayLessons(_repository),
        _createRecurringLessons = CreateRecurringLessons(_repository),
        _recordEvaluation = RecordLessonEvaluation(_repository);

  // State
  List<Lesson> _inProgress = [];
  List<Lesson> _upcoming = [];
  List<Lesson> _completed = [];
  List<Lesson> _warnings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Lesson> get inProgress => _inProgress;
  List<Lesson> get upcoming => _upcoming;
  List<Lesson> get completed => _completed;
  List<Lesson> get warnings => _warnings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalCount => _inProgress.length + _upcoming.length + _completed.length + _warnings.length;

  // 오늘 수업 로드
  Future<void> loadTodayLessons(String teacherId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _getTodayLessons(teacherId);

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (data) {
        _inProgress = data.inProgress;
        _upcoming = data.upcoming;
        _completed = data.completed;
        _warnings = data.warnings;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // N주 반복 수업 생성
  Future<bool> createRecurring({
    required Lesson template,
    required RecurrenceRule rule,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _createRecurringLessons(
      CreateRecurringLessonsParams(template: template, rule: rule),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (lessons) {
        // 성공 시 오늘 수업 다시 로드
        notifyListeners();
        return true;
      },
    );
  }

  // 수업 평가 기록
  Future<bool> recordEvaluation({
    required String lessonId,
    required Map<String, int> scores,
    required Map<String, bool> attendance,
    String? memo,
  }) async {
    final result = await _recordEvaluation(
      RecordEvaluationParams(
        lessonId: lessonId,
        scores: scores,
        attendance: attendance,
        memo: memo,
      ),
    );

    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        // 해당 수업 상태 업데이트
        _updateLessonInLists(lessonId);
        notifyListeners();
        return true;
      },
    );
  }

  // 수업 시작
  Future<bool> startLesson(String lessonId) async {
    final result = await _repository.updateLessonStatus(
      lessonId,
      LessonStatus.inProgress,
    );

    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _updateLessonInLists(lessonId);
        notifyListeners();
        return true;
      },
    );
  }

  // 수업 삭제
  Future<bool> deleteLesson(String lessonId) async {
    final result = await _repository.deleteLesson(lessonId);

    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _removeLessonFromLists(lessonId);
        notifyListeners();
        return true;
      },
    );
  }

  // 반복 시리즈 전체 삭제
  Future<bool> deleteRecurringSeries(String recurrenceId) async {
    final result = await _repository.deleteRecurringSeries(recurrenceId);

    return result.fold(
      (failure) {
        _error = failure.message;
        notifyListeners();
        return false;
      },
      (_) {
        _removeRecurringSeriesFromLists(recurrenceId);
        notifyListeners();
        return true;
      },
    );
  }

  void _updateLessonInLists(String lessonId) {
    // 실제 구현은 repository에서 다시 가져와야 하지만
    // 간단하게 리스트 재정렬
    final allLessons = [..._inProgress, ..._upcoming, ..._completed, ..._warnings];
    final lesson = allLessons.firstWhere((l) => l.id == lessonId);

    _removeLessonFromLists(lessonId);

    if (lesson.status == LessonStatus.completed) {
      _completed.add(lesson);
    } else if (lesson.status == LessonStatus.inProgress) {
      _inProgress.add(lesson);
    } else if (lesson.shouldWarn) {
      _warnings.add(lesson);
    } else {
      _upcoming.add(lesson);
    }
  }

  void _removeLessonFromLists(String lessonId) {
    _inProgress.removeWhere((l) => l.id == lessonId);
    _upcoming.removeWhere((l) => l.id == lessonId);
    _completed.removeWhere((l) => l.id == lessonId);
    _warnings.removeWhere((l) => l.id == lessonId);
  }

  void _removeRecurringSeriesFromLists(String recurrenceId) {
    _inProgress.removeWhere((l) => l.recurrenceId == recurrenceId);
    _upcoming.removeWhere((l) => l.recurrenceId == recurrenceId);
    _completed.removeWhere((l) => l.recurrenceId == recurrenceId);
    _warnings.removeWhere((l) => l.recurrenceId == recurrenceId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
