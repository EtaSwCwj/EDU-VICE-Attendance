// lib/features/homework/homework_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'homework_provider.dart';
import 'local_homework_repository.dart';
import 'models.dart';

/// 21-3C:
/// - 제출 표시 영속화(SharedPreferences)는 Provider 내부에서 처리됨.
/// - 날짜 선택(달력) 필터 추가 + 날짜 칩으로 해제.
/// - 기존 21-3B 기능(필터 칩/현황 배지/리셋) 유지.
class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeworkProvider>(
      create: (_) => HomeworkProvider(LocalHomeworkRepository())..refresh(),
      child: const _HomeworkView(),
    );
  }
}

class _HomeworkView extends StatelessWidget {
  const _HomeworkView();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final surface = color.surfaceContainerHighest.withValues(alpha: 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("과제"),
        actions: const [
          _DatePickerAction(), // 달력 아이콘(날짜 필터 진입)
          SizedBox(width: 8),
        ],
      ),
      body: Consumer<HomeworkProvider>(
        builder: (context, vm, _) {
          return Column(
            children: [
              // 상단 필터 바
              Material(
                color: surface,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: _FilterBar(),
                ),
              ),
              // 선택 칩 + 현황 배지 + 날짜 칩
              Material(
                color: surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    children: const [
                      _SelectedChipsRow(),
                      SizedBox(height: 8),
                      _DateChipRow(),
                      SizedBox(height: 8),
                      _StatusCounters(),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: vm.loading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.items.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                            itemCount: vm.items.length,
                            itemBuilder: (context, index) {
                              final a = vm.items[index];
                              return _AssignmentCard(assignment: a);
                            },
                          ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _DatePickerAction extends StatelessWidget {
  const _DatePickerAction();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HomeworkProvider>();
    return IconButton(
      tooltip: "날짜 선택",
      icon: const Icon(Icons.event),
      onPressed: () async {
        final now = DateTime.now();
        final pick = await showDatePicker(
          context: context,
          firstDate: DateTime(now.year - 1, 1, 1),
          lastDate: DateTime(now.year + 1, 12, 31),
          initialDate: vm.selectedDate ?? now,
          helpText: "마감일 기준 날짜 선택",
        );
        if (pick != null) {
          vm.setSelectedDate(pick);
        }
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeworkProvider>();
    final subjects = vm.subjectOptions;
    final books = vm.bookOptions;

    return Row(
      children: [
        // 과목 필터
        Expanded(
          child: DropdownMenu<String>(
            label: const Text("과목"),
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
        // 책 필터
        Expanded(
          child: DropdownMenu<String>(
            label: const Text("책"),
            initialSelection: vm.selectedBookId,
            onSelected: (v) => vm.selectBook(v),
            dropdownMenuEntries: <DropdownMenuEntry<String>>[
              const DropdownMenuEntry(value: "", label: "전체"),
              ...books.map((b) => DropdownMenuEntry<String>(
                    value: b.id,
                    label: b.name,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectedChipsRow extends StatelessWidget {
  const _SelectedChipsRow();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeworkProvider>();
    final subject = vm.selectedSubjectName;
    final book = vm.selectedBookName;

    final hasSubject = subject != null && subject.isNotEmpty;
    final hasBook = book != null && book.isNotEmpty;
    final hasAny = hasSubject || hasBook;

    if (!hasAny) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (hasSubject)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InputChip(
              label: Text("과목: $subject"),
              deleteIcon: const Icon(Icons.close),
              onDeleted: vm.clearSubject,
              onPressed: vm.clearSubject,
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 1),
              tooltip: '과목 필터 해제',
            ),
          ),
        if (hasBook)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InputChip(
              label: Text("책: $book"),
              deleteIcon: const Icon(Icons.close),
              onDeleted: vm.clearBook,
              onPressed: vm.clearBook,
              backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 1),
              tooltip: '책 필터 해제',
            ),
          ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: vm.resetFilters,
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text("필터 리셋"),
        ),
      ],
    );
  }
}

class _DateChipRow extends StatelessWidget {
  const _DateChipRow();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeworkProvider>();
    final pick = vm.selectedDate;
    if (pick == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final label = "날짜: ${ymd(pick)}";

    return Row(
      children: [
        InputChip(
          label: Text(label),
          deleteIcon: const Icon(Icons.close),
          onDeleted: () => vm.setSelectedDate(null),
          onPressed: () => vm.setSelectedDate(null),
          backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 1),
          tooltip: '날짜 필터 해제',
        ),
      ],
    );
  }
}

class _StatusCounters extends StatelessWidget {
  const _StatusCounters();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeworkProvider>();
    final cs = Theme.of(context).colorScheme;

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

    return Row(
      children: [
        pill(cs.error.withValues(alpha: 0.10), cs.error, "지남", vm.overdueCount),
        const SizedBox(width: 8),
        pill(cs.tertiary.withValues(alpha: 0.10), cs.tertiary, "임박", vm.dueSoonCount),
        const SizedBox(width: 8),
        pill(cs.primary.withValues(alpha: 0.10), cs.primary, "진행", vm.pendingCount),
        const SizedBox(width: 8),
        pill(cs.secondary.withValues(alpha: 0.10), cs.secondary, "제출", vm.completedCount),
      ],
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment});
  final Assignment assignment;

  Color _statusColor(BuildContext context, Assignment a) {
    final cs = Theme.of(context).colorScheme;
    switch (a.status) {
      case AssignmentStatus.pending:
        return a.isDueSoon ? cs.tertiary : cs.primary;
      case AssignmentStatus.completed:
        return cs.secondary;
      case AssignmentStatus.overdue:
        return cs.error;
    }
  }

  String _statusLabel(Assignment a) {
    switch (a.status) {
      case AssignmentStatus.pending:
        return a.isDueSoon ? "임박" : "진행중";
      case AssignmentStatus.completed:
        return "제출됨";
      case AssignmentStatus.overdue:
        return "지남";
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HomeworkProvider>();
    final cs = Theme.of(context).colorScheme;
    final surface = cs.surfaceContainerHighest.withValues(alpha: 1);

    return Card(
      color: surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) 상단 라벨(과목/책) + 상태칩
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${assignment.subject.name} · ${assignment.book.name}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context, assignment).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _statusColor(context, assignment).withValues(alpha: 0.55),
                    ),
                  ),
                  child: Text(
                    _statusLabel(assignment),
                    style: TextStyle(
                      color: _statusColor(context, assignment),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 2) 범위 / 마감일
            Row(
              children: [
                Expanded(
                  child: Text(
                    assignment.rangeLabel,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  "마감: ${ymd(assignment.dueDate)}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: assignment.status == AssignmentStatus.overdue
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 3) '해왔어요(제출 표시)' 토글
            Row(
              children: [
                Checkbox(
                  value: assignment.isDone,
                  onChanged: (_) => vm.toggleDone(assignment),
                ),
                const SizedBox(width: 4),
                Text(
                  assignment.isDone ? "해왔어요(제출됨)" : "아직",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => vm.toggleDone(assignment),
                  icon: Icon(
                    assignment.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: assignment.isDone ? cs.secondary : cs.onSurfaceVariant,
                  ),
                  tooltip: assignment.isDone ? "제출 표시 해제" : "해왔어요(제출 표시)",
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "※ 최종 완료는 선생 확인 후 확정됩니다.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<HomeworkProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            "표시할 과제가 없습니다.",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: vm.resetFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text("필터 초기화"),
          ),
        ],
      ),
    );
  }
}
