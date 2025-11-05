// lib/features/homework/homework_page.dart
//
// 역할별 학습/숙제 화면
// - student: AssignmentsProvider + HomeworkProvider(배정된 과목/책 기반 과제 목록)
// - owner/teacher: 임시 골격 안내

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../assignments/assignments_provider.dart';
import '../assignments/local_assignments_repository.dart';
import '../assignments/models.dart';

import 'models.dart';
import 'homework_repository.dart';
import 'local_homework_repository.dart';

class HomeworkPage extends StatelessWidget {
  final String role;
  const HomeworkPage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case 'student':
        return const _StudentLearningPage();
      case 'teacher':
        return const _RoleStubPage(
          title: '숙제(선생)',
          description: '향후: 담당 학생/과목별 숙제 배정·진도 확인 화면',
        );
      case 'owner':
      default:
        return const _RoleStubPage(
          title: '숙제(원장)',
          description: '향후: 학원 전체 과목/반 기준 숙제 현황 요약',
        );
    }
  }
}

/// ------------------------------
/// Provider: Homework (학생 전용)
/// ------------------------------
class HomeworkProvider extends ChangeNotifier {
  final HomeworkRepository _repo;
  HomeworkProvider(this._repo);

  String? _lastStudentId;
  String? _lastBookId;

  bool _loading = false;
  bool get loading => _loading;

  List<HomeworkTask> _tasks = const [];
  List<HomeworkTask> get tasks => _tasks;

  Future<void> loadIfNeeded({required String studentId, required String? bookId}) async {
    if (bookId == null) {
      _tasks = const [];
      _lastStudentId = studentId;
      _lastBookId = null;
      notifyListeners();
      return;
    }
    if (_loading) return;
    if (_lastStudentId == studentId && _lastBookId == bookId) return;

    _loading = true;
    notifyListeners();
    try {
      _tasks = await _repo.loadTasks(studentId: studentId, bookId: bookId);
      _lastStudentId = studentId;
      _lastBookId = bookId;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleComplete(String taskId) async {
    if (_lastStudentId == null || _lastBookId == null) return;
    _tasks = await _repo.toggleComplete(
      studentId: _lastStudentId!,
      bookId: _lastBookId!,
      taskId: taskId,
    );
    notifyListeners();
  }
}

/// ------------------------------
/// 학생 학습 탭(배정 + 과제)
/// ------------------------------
class _StudentLearningPage extends StatefulWidget {
  const _StudentLearningPage();

  @override
  State<_StudentLearningPage> createState() => _StudentLearningPageState();
}

class _StudentLearningPageState extends State<_StudentLearningPage> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AssignmentsProvider(LocalAssignmentsRepository())..load(studentId: 'student-dev'),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeworkProvider(LocalHomeworkRepository()),
        ),
      ],
      child: Consumer2<AssignmentsProvider, HomeworkProvider>(
        builder: (context, vm, hw, _) {
          // 과목/책 선택 상태를 기반으로 과제 목록 로딩 보장
          hw.loadIfNeeded(studentId: vm.studentId ?? 'student-dev', bookId: vm.selectedBookId);

          return Scaffold(
            appBar: AppBar(title: const Text('학습')),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _StudentLearningBody(vm: vm, hw: hw),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudentLearningBody extends StatelessWidget {
  final AssignmentsProvider vm;
  final HomeworkProvider hw;
  const _StudentLearningBody({required this.vm, required this.hw});

  @override
  Widget build(BuildContext context) {
    final subjects = vm.subjects;
    final books = vm.books;
    final hasSingleSubject = subjects.length <= 1;

    AssignedBook? selectedBook;
    final selectedId = vm.selectedBookId;
    if (selectedId != null) {
      final matches = books.where((b) => b.id == selectedId);
      selectedBook = matches.isNotEmpty ? matches.first : null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 과목 선택(1개면 감춤)
        if (!hasSingleSubject)
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '과목',
              border: OutlineInputBorder(),
            ),
            initialValue: vm.selectedSubjectId,
            items: subjects
                .map((s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ))
                .toList(),
            onChanged: (v) {
              // ignore: discarded_futures
              vm.selectSubject(v);
            },
          ),
        if (!hasSingleSubject) const SizedBox(height: 12),

        // 책 선택
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: '책',
            border: OutlineInputBorder(),
          ),
          initialValue: vm.selectedBookId,
          items: books
              .map((b) => DropdownMenuItem<String>(
                    value: b.id,
                    child: Text(b.name),
                  ))
              .toList(),
          onChanged: (v) {
            // ignore: discarded_futures
            vm.selectBook(v);
            // 선택 변경 즉시 과제 로드 보장
            hw.loadIfNeeded(studentId: vm.studentId ?? 'student-dev', bookId: v);
          },
        ),
        const SizedBox(height: 16),

        // 진도/요약 카드
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: selectedBook == null
                ? const Text('배정된 책이 없습니다.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedBook.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.trending_up, size: 18),
                          const SizedBox(width: 6),
                          Text('진행률: ${selectedBook.progressPct?.toString() ?? '-'}%',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.flag_outlined, size: 18),
                          const SizedBox(width: 6),
                          Text('오늘 할 분량: ${selectedBook.todayRange ?? '-'}',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // 과제 목록
        Expanded(
          child: hw.loading
              ? const Center(child: CircularProgressIndicator())
              : _HomeworkList(hw: hw),
        ),
      ],
    );
  }
}

class _HomeworkList extends StatelessWidget {
  final HomeworkProvider hw;
  const _HomeworkList({required this.hw});

  @override
  Widget build(BuildContext context) {
    final tasks = hw.tasks;
    if (tasks.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Center(child: Text('과제가 없습니다.')),
      );
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final t = tasks[i];
        final dueStr = _formatDue(t.due);
        final isOverdue = _isOverdue(t.due);
        final range = t.range;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await hw.toggleComplete(t.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.completed ? '완료 해제' : '완료 처리'),
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: t.completed,
                    onChanged: (_) => hw.toggleComplete(t.id),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title, style: Theme.of(context).textTheme.titleSmall),
                        if (range != null) ...[
                          const SizedBox(height: 2),
                          Text(range, style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (dueStr != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.event_note,
                                size: 14,
                                color: isOverdue
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOverdue ? '마감 지남 • $dueStr' : '마감 • $dueStr',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isOverdue
                                          ? Theme.of(context).colorScheme.error
                                          : null,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _formatDue(DateTime? due) {
    if (due == null) return null;
    final y = due.year.toString().padLeft(4, '0');
    final m = due.month.toString().padLeft(2, '0');
    final d = due.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isOverdue(DateTime? due) {
    if (due == null) return false;
    final now = DateTime.now();
    final dd = DateTime(due.year, due.month, due.day);
    final nn = DateTime(now.year, now.month, now.day);
    return dd.isBefore(nn);
  }
}

/// ------------------------------
/// 다른 역할(원장/선생) 임시 골격
/// ------------------------------
class _RoleStubPage extends StatelessWidget {
  final String title;
  final String description;
  const _RoleStubPage({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(description),
        ),
      ),
    );
  }
}
