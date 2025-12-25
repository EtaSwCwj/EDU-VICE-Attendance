// lib/features/teacher_homework/teacher_homework_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

import '../homework/models.dart';
import '../homework/local_homework_repository.dart';
import '../books/data/repositories/book_local_repository.dart';
import 'local_teacher_homework_repository.dart';
import 'teacher_homework_provider.dart';

class TeacherHomeworkPage extends StatelessWidget {
  const TeacherHomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    // BookLocalRepository가 등록되어 있으면 사용, 없으면 null
    BookLocalRepository? bookRepo;
    try {
      bookRepo = GetIt.instance<BookLocalRepository>();
    } catch (_) {
      // GetIt에 등록되지 않은 경우 무시
    }

    return ChangeNotifierProvider<TeacherHomeworkProvider>(
      create: (_) => TeacherHomeworkProvider(
        LocalTeacherHomeworkRepository(LocalHomeworkRepository()),
        bookRepo: bookRepo,
      )..loadStudents(),
      child: const _TeacherHomeworkView(),
    );
  }
}

class _TeacherHomeworkView extends StatelessWidget {
  const _TeacherHomeworkView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surfaceContainerHighest.withValues(alpha: 1);
    final vm = context.watch<TeacherHomeworkProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("숙제 (교사)"),
        actions: [
          IconButton(
            tooltip: "학생 검색",
            icon: const Icon(Icons.search),
            onPressed: () async {
              // ❗ await 이전에 provider를 확보해서 lint 제거
              final provider = context.read<TeacherHomeworkProvider>();
              final q = await showDialog<String>(
                context: context,
                builder: (_) => const _StudentSearchDialog(),
              );
              if (q != null) {
                await provider.loadStudents(query: q);
              }
            },
          ),
          IconButton(
            tooltip: "새로고침",
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TeacherHomeworkProvider>().loadStudents(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: vm.selectedStudentId == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'teacher_homework_fab',
              onPressed: () {
                // Provider 인스턴스를 직접 시트에 주입
                final provider = context.read<TeacherHomeworkProvider>();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  useRootNavigator: false,
                  builder: (_) => _NewAssignmentSheet(vm: provider),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text("새 과제"),
            ),
      body: Column(
        children: [
          Material(
            color: surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: const [
                  _StudentPickerRow(),
                  SizedBox(height: 8),
                  _SubjectFilterRow(),
                  SizedBox(height: 8),
                  _StatusCountersRow(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.selectedStudentId == null
                    ? const _EmptySelectStudent()
                    : (vm.items.isEmpty
                        ? const _EmptyAssignments()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                            itemCount: vm.items.length,
                            itemBuilder: (context, i) => _TeacherAssignmentCard(a: vm.items[i]),
                          )),
          ),
        ],
      ),
    );
  }
}

class _StudentPickerRow extends StatelessWidget {
  const _StudentPickerRow();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TeacherHomeworkProvider>();

    return Row(
      children: [
        Expanded(
          child: DropdownMenu<String>(
            label: const Text("학생 선택"),
            initialSelection: vm.selectedStudentId,
            onSelected: (v) => vm.selectStudent(v),
            dropdownMenuEntries: <DropdownMenuEntry<String>>[
              const DropdownMenuEntry(value: "", label: "선택 안됨"),
              ...vm.students.map((s) => DropdownMenuEntry<String>(
                    value: s.id,
                    label: s.name,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubjectFilterRow extends StatelessWidget {
  const _SubjectFilterRow();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TeacherHomeworkProvider>();
    final subjects = vm.subjectOptions;

    return Row(
      children: [
        Expanded(
          child: DropdownMenu<String>(
            label: const Text("과목 필터"),
            initialSelection: vm.selectedSubjectId,
            onSelected: (v) => vm.selectSubject(v),
            dropdownMenuEntries: <DropdownMenuEntry<String>>[
              const DropdownMenuEntry(value: "", label: "전체"),
              ...subjects.map((s) => DropdownMenuEntry<String>(
                    value: s.id,
                    label: s.name,
                  )),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: vm.resetSubjectFilter,
          icon: const Icon(Icons.filter_alt_off),
          label: const Text("필터 해제"),
        ),
      ],
    );
  }
}

class _StatusCountersRow extends StatelessWidget {
  const _StatusCountersRow();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TeacherHomeworkProvider>();
    final cs = Theme.of(context).colorScheme;

    final items = vm.items;
    int confirmWait = items.where((a) => a.teacherCheckedAt == null && a.isDone).length;
    int overdue = items.where((a) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final due = DateTime(a.dueDate.year, a.dueDate.month, a.dueDate.day);
      return !a.isDone && due.isBefore(today);
    }).length;
    int dueSoon = items.where((a) => !a.isDone && a.isDueSoon).length;
    int confirmed = items.where((a) => a.teacherCheckedAt != null && a.checkResult != null).length;

    Widget pill(Color bg, Color fg, String label, int count) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text("$count", style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          pill(cs.primary.withValues(alpha: 0.10), cs.primary, "확인 대기", confirmWait),
          const SizedBox(width: 8),
          pill(cs.error.withValues(alpha: 0.10), cs.error, "지남", overdue),
          const SizedBox(width: 8),
          pill(cs.tertiary.withValues(alpha: 0.10), cs.tertiary, "임박", dueSoon),
          const SizedBox(width: 8),
          pill(cs.secondary.withValues(alpha: 0.10), cs.secondary, "확정됨", confirmed),
        ],
      ),
    );
  }
}

class _TeacherAssignmentCard extends StatelessWidget {
  const _TeacherAssignmentCard({required this.a});
  final Assignment a;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<TeacherHomeworkProvider>();
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surfaceContainerHighest.withValues(alpha: 1);

    Color statusColor(Assignment x) {
      if (x.teacherCheckedAt != null && x.checkResult != null) {
        switch (x.checkResult!) {
          case CheckResult.pass:
            return cs.secondary;
          case CheckResult.fail:
            return cs.error;
          case CheckResult.partial:
            return cs.tertiary;
        }
      }
      if (x.isDone) return cs.primary;
      if (x.status == AssignmentStatus.overdue) return cs.error;
      if (x.isDueSoon) return cs.tertiary;
      return cs.onSurfaceVariant;
    }

    String statusLabel(Assignment x) {
      if (x.teacherCheckedAt != null && x.checkResult != null) {
        switch (x.checkResult!) {
          case CheckResult.pass:
            return "완료(확정)";
          case CheckResult.fail:
            return "미완료(확정)";
          case CheckResult.partial:
            return "부분완료(확정)";
        }
      }
      if (x.isDone) return "제출됨(확인 대기)";
      if (x.status == AssignmentStatus.overdue) return "지남";
      if (x.isDueSoon) return "임박";
      return "진행중";
    }

    return Card(
      color: surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${a.subject.name} · ${a.book.name}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor(a).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor(a).withValues(alpha: 0.55)),
                  ),
                  child: Text(
                    statusLabel(a),
                    style: TextStyle(
                      color: statusColor(a),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.rangeLabel,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  "마감: ${ymd(a.dueDate)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: a.status == AssignmentStatus.overdue ? cs.error : cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "학생: ${a.assignedTo.name}",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => vm.setCheckResult(assignment: a, result: CheckResult.pass),
                  icon: const Icon(Icons.check),
                  label: const Text("완료 확정"),
                ),
                OutlinedButton.icon(
                  onPressed: () => vm.setCheckResult(assignment: a, result: CheckResult.partial),
                  icon: const Icon(Icons.deblur),
                  label: const Text("부분완료"),
                ),
                OutlinedButton.icon(
                  onPressed: () => vm.setCheckResult(assignment: a, result: CheckResult.fail),
                  icon: const Icon(Icons.close),
                  label: const Text("미완료"),
                ),
              ],
            ),
            if (a.teacherCheckedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                "확인: ${a.teacherCheckedAt}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptySelectStudent extends StatelessWidget {
  const _EmptySelectStudent();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        "학생을 먼저 선택하세요.",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _EmptyAssignments extends StatelessWidget {
  const _EmptyAssignments();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        "해당 학생의 숙제가 없습니다.",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _StudentSearchDialog extends StatefulWidget {
  const _StudentSearchDialog();

  @override
  State<_StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<_StudentSearchDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("학생 검색"),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: "이름 일부를 입력하세요",
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(""),
          child: const Text("전체"),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text("검색"),
        ),
      ],
    );
  }
}

/// 새 과제 배정 바텀시트 (Provider 인스턴스 직접 주입)
class _NewAssignmentSheet extends StatefulWidget {
  const _NewAssignmentSheet({required this.vm});
  final TeacherHomeworkProvider vm;

  @override
  State<_NewAssignmentSheet> createState() => _NewAssignmentSheetState();
}

class _NewAssignmentSheetState extends State<_NewAssignmentSheet> {
  String? _subjectId;
  String? _bookId;
  final _rangeCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 2));

  TeacherHomeworkProvider get vm => widget.vm;

  @override
  Widget build(BuildContext context) {
    final subjects = vm.subjectOptions;
    final books = vm.bookOptions;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 4, width: 48, margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(999))),
          Row(
            children: [
              Text("새 과제 배정", style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),

          Align(alignment: Alignment.centerLeft, child: Text("과목", style: Theme.of(context).textTheme.labelLarge)),
          DropdownMenu<String>(
            initialSelection: _subjectId,
            onSelected: (v) => setState(() { _subjectId = v ?? ""; _bookId = null; }),
            dropdownMenuEntries: [
              ...subjects.map((s) => DropdownMenuEntry<String>(value: s.id, label: s.name)),
            ],
            expandedInsets: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          Align(alignment: Alignment.centerLeft, child: Text("책", style: Theme.of(context).textTheme.labelLarge)),
          DropdownMenu<String>(
            initialSelection: _bookId,
            onSelected: (v) => setState(() => _bookId = v ?? ""),
            dropdownMenuEntries: [
              ...books.where((b) => _subjectId == null || _subjectId!.isEmpty
                    ? true
                    : vm.items.any((a) => a.book.id == b.id && a.subject.id == _subjectId))
                  .map((b) => DropdownMenuEntry<String>(value: b.id, label: b.name)),
            ],
            expandedInsets: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _rangeCtrl,
            decoration: const InputDecoration(
              labelText: "범위 (예: p.10–20 / Day 3 / 1과 1~5번)",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(child: Text("마감일: ${ymd(_dueDate)}", style: Theme.of(context).textTheme.bodyLarge)),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                icon: const Icon(Icons.event),
                label: const Text("날짜 선택"),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                if ((_subjectId ?? "").isEmpty) { messenger.showSnackBar(const SnackBar(content: Text("과목을 선택하세요."))); return; }
                if ((_bookId ?? "").isEmpty) { messenger.showSnackBar(const SnackBar(content: Text("책을 선택하세요."))); return; }
                if (_rangeCtrl.text.trim().isEmpty) { messenger.showSnackBar(const SnackBar(content: Text("범위를 입력하세요."))); return; }

                final err = await vm.createNewAssignment(
                  subjectId: _subjectId!,
                  bookId: _bookId!,
                  rangeLabel: _rangeCtrl.text,
                  dueDate: _dueDate,
                );
                if (err != null) {
                  messenger.showSnackBar(SnackBar(content: Text(err)));
                  return;
                }
                nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text("새 과제를 배정했습니다.")));
              },
              icon: const Icon(Icons.save),
              label: const Text("저장"),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
