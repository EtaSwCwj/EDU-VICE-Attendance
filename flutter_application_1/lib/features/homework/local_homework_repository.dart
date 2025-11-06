// lib/features/homework/local_homework_repository.dart
import 'dart:async';
import 'models.dart';
import 'homework_repository.dart';

/// 데모용 로컬 저장소(학생/교사용 공용 데이터 소스)
class LocalHomeworkRepository implements HomeworkRepository {
  // 데모 학생
  static const s1 = StudentRef(id: "STU-001", name: "홍길동");
  static const s2 = StudentRef(id: "STU-002", name: "김하늘");

  final List<Assignment> _store = [
    Assignment(
      id: "A-001",
      subject: SubjectRef(id: "S-MATH", name: "수학"),
      book: BookRef(id: "B-Calc1", name: "개념원리 수1"),
      assignedTo: s1,
      rangeLabel: "p.30–45",
      dueDate: DateTime.now().add(const Duration(days: 1)),
      isDone: false,
    ),
    Assignment(
      id: "A-002",
      subject: SubjectRef(id: "S-KOR", name: "국어"),
      book: BookRef(id: "B-KOR-문법", name: "문법 개념서"),
      assignedTo: s1,
      rangeLabel: "문법 단원 2: 1~3번",
      dueDate: DateTime.now().add(const Duration(days: 3)),
      isDone: false,
    ),
    Assignment(
      id: "A-003",
      subject: SubjectRef(id: "S-ENG", name: "영어"),
      book: BookRef(id: "B-ENG-VOCA", name: "VOCA 2200"),
      assignedTo: s2,
      rangeLabel: "Day 05",
      dueDate: DateTime.now().subtract(const Duration(days: 1)),
      isDone: false,
    ),
    Assignment(
      id: "A-004",
      subject: SubjectRef(id: "S-MATH", name: "수학"),
      book: BookRef(id: "B-Calc1", name: "개념원리 수1"),
      assignedTo: s2,
      rangeLabel: "p.46–60",
      dueDate: DateTime.now(),
      isDone: true,
      teacherCheckedAt: null,
      checkResult: null,
    ),
  ];

  @override
  Future<List<Assignment>> fetchAssignments() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return List<Assignment>.unmodifiable(_store);
  }

  @override
  Future<void> updateAssignment(Assignment assignment) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final idx = _store.indexWhere((e) => e.id == assignment.id);
    if (idx >= 0) _store[idx] = assignment;
  }

  /// 새 과제 추가(교사용 배정)
  Future<void> createAssignment(Assignment a) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _store.add(a);
  }
}
