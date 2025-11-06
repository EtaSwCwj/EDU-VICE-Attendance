// lib/features/homework/homework_page.dart
//
// 학생용 "학습" 탭 (진도 타임라인 연동) — 전역 Provider 사용 (AppProviders 주입 전제)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../assignments/assignments_provider.dart';
import '../progress/progress_provider.dart';
import '../progress/models.dart';

class HomeworkPage extends StatefulWidget {
  final String? role; // 필요 시 사용, 없으면 무시
  const HomeworkPage({super.key, this.role});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  // DEV 고정 학생 ID (추후 AuthState/로그인 연동)
  String _studentId = 'student-dev';

  String? _subjectId;
  String? _bookId;

  @override
  void initState() {
    super.initState();

    // 프레임 이후: 전역 Provider에 로드 트리거
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final assign = context.read<AssignmentsProvider>();
      final progress = context.read<ProgressProvider>();

      // 과목/책 배정 로드
      await assign.load(studentId: _studentId);

      // 최초 선택값 세팅
      if (assign.subjects.isNotEmpty && _subjectId == null) {
        setState(() {
          _subjectId = assign.subjects.first.id;
          final books = assign.booksFor(_subjectId!);
          _bookId = books.isNotEmpty ? books.first.id : null;
        });

        // 진도 타임라인 로드
        await progress.load(
          studentId: _studentId,
          subjectId: _subjectId!,
          bookId: _bookId,
        );
      }
    });
  }

  void _onSubjectChanged(String? v) {
    if (v == null) return;
    setState(() {
      _subjectId = v;
      _bookId = null;
    });

    // 과목 바뀌면, 해당 과목의 첫 번째 책으로 초기화 + 진도 재로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final assign = context.read<AssignmentsProvider>();
      final progress = context.read<ProgressProvider>();

      final books = assign.booksFor(_subjectId!);
      setState(() {
        _bookId = books.isNotEmpty ? books.first.id : null;
      });

      await progress.load(
        studentId: _studentId,
        subjectId: _subjectId!,
        bookId: _bookId,
      );
    });
  }

  void _onBookChanged(String? v) {
    setState(() => _bookId = v);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final progress = context.read<ProgressProvider>();
      if (_subjectId == null) return;
      await progress.load(
        studentId: _studentId,
        subjectId: _subjectId!,
        bookId: _bookId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final assign = context.watch<AssignmentsProvider>();
    final progress = context.watch<ProgressProvider>();

    final subjects = assign.subjects;
    final books = (_subjectId == null)
        ? const <dynamic>[]
        : assign.booksFor(_subjectId!);

    final latest = progress.latestPageTo();
    final todayPlan = (latest == null)
        ? null
        : '오늘 할 분량: p.${latest + 1}–${latest + 8}';

    return Scaffold(
      appBar: AppBar(title: const Text('학습')),
      body: SafeArea(
        child: (assign.loading && subjects.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 과목 선택 — Flutter 최신 위젯 DropdownMenu 사용 (deprecation 경고 제거)
                  const _FieldLabel('과목'),
                  DropdownMenu<String>(
                    initialSelection: _subjectId,
                    onSelected: _onSubjectChanged,
                    dropdownMenuEntries: subjects
                        .map(
                          (s) => DropdownMenuEntry<String>(
                            value: s.id,
                            label: s.name,
                          ),
                        )
                        .toList(),
                    width: MediaQuery.of(context).size.width - 32,
                    // 시각 스타일은 기본값 유지 (Material 3)
                  ),
                  const SizedBox(height: 16),

                  // 책 선택
                  const _FieldLabel('책'),
                  DropdownMenu<String>(
                    initialSelection: _bookId,
                    onSelected: _onBookChanged,
                    dropdownMenuEntries: books
                        .map(
                          (b) => DropdownMenuEntry<String>(
                            value: b.id,
                            label: b.name,
                          ),
                        )
                        .toList(),
                    width: MediaQuery.of(context).size.width - 32,
                  ),
                  const SizedBox(height: 20),

                  // 요약 카드
                  _SummaryCard(
                    title: (_bookId == null)
                        ? '진행 요약'
                        : books.firstWhere((b) => b.id == _bookId!).name,
                    progressText: (latest == null)
                        ? '진도 기록이 없습니다.'
                        : '진행률: ${(latest / 200 * 100).floor()}%',
                    planText: todayPlan,
                  ),
                  const SizedBox(height: 20),

                  // 최근 타임라인
                  const Text(
                    '최근 진도 타임라인',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (progress.loading && progress.items.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_subjectId == null)
                    const Text('과목을 선택하세요.')
                  else
                    Column(
                      children: progress.items
                          .map((e) => _TimelineTile(entry: e))
                          .toList(),
                    ),
                ],
              ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.progressText,
    required this.planText,
  });

  final String title;
  final String progressText;
  final String? planText;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.35); // surfaceVariant/withOpacity 대체
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 18),
              const SizedBox(width: 6),
              Text(progressText),
            ],
          ),
          if (planText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 18),
                const SizedBox(width: 6),
                Text(planText!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry});
  final ProgressEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: 0.30), // withOpacity 대체
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.menu_book_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('p.${entry.pageFrom}–${entry.pageTo}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                // 날짜 표시는 모델 필드명이 통일되면 추가: taughtAt/recordedAt 등
                // 현재는 빌드 에러 방지 위해 생략
              ],
            ),
          ),
        ],
      ),
    );
  }
}
