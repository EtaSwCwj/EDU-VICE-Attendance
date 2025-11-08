// lib/features/homework/local_homework_repository.dart
import 'dart:async';
import 'dart:convert';

import 'models.dart';
import 'homework_repository.dart';
import '../../shared/services/kv_store.dart';

/// 데모/개발용 로컬 저장소:
/// - SharedPreferences(JSON)로 과제 리스트 영속화
/// - 학생/교사용 화면 공용 데이터 소스
class LocalHomeworkRepository implements HomeworkRepository {
  static const String _prefsKey = 'assignments_v1';

  // 메모리 캐시 (IO 최소화)
  final List<Assignment> _store = [];
  bool _initialized = false;

  // ────────────────────────────────────────────────────────────────────────────
  // 초기 로드 & 시드
  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;

    final raw = await KvStore.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      // 최초 실행: 샘플 데이터 시드
      _store
        ..clear()
        ..addAll(_seedData());
      await _persist();
      return;
    }

    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      _store
        ..clear()
        ..addAll(list.map(_fromMap));
    } catch (_) {
      // 손상되었을 경우 초기화
      _store
        ..clear()
        ..addAll(_seedData());
      await _persist();
    }
  }

  // 샘플 데이터(최초 1회)
  List<Assignment> _seedData() {
    const s1 = StudentRef(id: "STU-001", name: "홍길동");
    const s2 = StudentRef(id: "STU-002", name: "김하늘");

    return [
      Assignment(
        id: "A-001",
        subject: const SubjectRef(id: "S-MATH", name: "수학"),
        book: const BookRef(id: "B-Calc1", name: "개념원리 수1"),
        assignedTo: s1,
        rangeLabel: "p.30–45",
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isDone: false,
      ),
      Assignment(
        id: "A-002",
        subject: const SubjectRef(id: "S-KOR", name: "국어"),
        book: const BookRef(id: "B-KOR-문법", name: "문법 개념서"),
        assignedTo: s1,
        rangeLabel: "문법 단원 2: 1~3번",
        dueDate: DateTime.now().add(const Duration(days: 3)),
        isDone: false,
      ),
      Assignment(
        id: "A-003",
        subject: const SubjectRef(id: "S-ENG", name: "영어"),
        book: const BookRef(id: "B-ENG-VOCA", name: "VOCA 2200"),
        assignedTo: s2,
        rangeLabel: "Day 05",
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        isDone: false,
      ),
      Assignment(
        id: "A-004",
        subject: const SubjectRef(id: "S-MATH", name: "수학"),
        book: const BookRef(id: "B-Calc1", name: "개념원리 수1"),
        assignedTo: s2,
        rangeLabel: "p.46–60",
        dueDate: DateTime.now(),
        isDone: true,
        teacherCheckedAt: null,
        checkResult: null,
      ),
    ];
  }

  Future<void> _persist() async {
    final jsonList = _store.map(_toMap).toList();
    await KvStore.setString(_prefsKey, jsonEncode(jsonList));
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 인터페이스 구현

  @override
  Future<List<Assignment>> fetchAssignments() async {
    await _ensureLoaded();
    await Future.delayed(const Duration(milliseconds: 80));
    return List<Assignment>.unmodifiable(_store);
  }

  @override
  Future<void> updateAssignment(Assignment assignment) async {
    await _ensureLoaded();
    final idx = _store.indexWhere((e) => e.id == assignment.id);
    if (idx >= 0) {
      _store[idx] = assignment;
      await _persist();
    }
  }

  /// 새 과제 추가(교사용 배정에서 호출)
  Future<void> createAssignment(Assignment a) async {
    await _ensureLoaded();
    _store.add(a);
    await _persist();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 직렬화 헬퍼

  Map<String, dynamic> _toMap(Assignment a) => {
        "id": a.id,
        "subject": {"id": a.subject.id, "name": a.subject.name},
        "book": {"id": a.book.id, "name": a.book.name},
        "student": {"id": a.assignedTo.id, "name": a.assignedTo.name},
        "rangeLabel": a.rangeLabel,
        "dueDateMs": a.dueDate.millisecondsSinceEpoch,
        "isDone": a.isDone,
        "teacherCheckedAtMs": a.teacherCheckedAt?.millisecondsSinceEpoch,
        "checkResult": a.checkResult == null ? null : _checkResultToString(a.checkResult!),
      };

  Assignment _fromMap(Map<String, dynamic> m) {
    final subject = SubjectRef(
      id: (m["subject"]?["id"] ?? "") as String,
      name: (m["subject"]?["name"] ?? "") as String,
    );
    final book = BookRef(
      id: (m["book"]?["id"] ?? "") as String,
      name: (m["book"]?["name"] ?? "") as String,
    );
    final student = StudentRef(
      id: (m["student"]?["id"] ?? "") as String,
      name: (m["student"]?["name"] ?? "") as String,
    );
    final due = DateTime.fromMillisecondsSinceEpoch((m["dueDateMs"] as num).toInt());
    final checkedMs = m["teacherCheckedAtMs"];
    final checkedAt = checkedMs == null ? null : DateTime.fromMillisecondsSinceEpoch((checkedMs as num).toInt());

    return Assignment(
      id: (m["id"] ?? "") as String,
      subject: subject,
      book: book,
      assignedTo: student,
      rangeLabel: (m["rangeLabel"] ?? "") as String,
      dueDate: due,
      isDone: (m["isDone"] ?? false) as bool,
      teacherCheckedAt: checkedAt,
      checkResult: _checkResultFromString(m["checkResult"]),
    );
  }

  String _checkResultToString(CheckResult v) {
    switch (v) {
      case CheckResult.pass:
        return "pass";
      case CheckResult.partial:
        return "partial";
      case CheckResult.fail:
        return "fail";
    }
  }

  CheckResult? _checkResultFromString(dynamic s) {
    if (s == null) return null;
    switch (s as String) {
      case "pass":
        return CheckResult.pass;
      case "partial":
        return CheckResult.partial;
      case "fail":
        return CheckResult.fail;
    }
    return null;
  }
}
