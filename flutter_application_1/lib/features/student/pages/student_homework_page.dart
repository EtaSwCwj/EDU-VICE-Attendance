// lib/features/student/pages/student_homework_page.dart
import 'package:flutter/material.dart';

/// 학생용 숙제 페이지: 내 숙제 목록 (진행중/완료)
class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({super.key});

  @override
  State<StudentHomeworkPage> createState() => _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends State<StudentHomeworkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 숙제'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '진행중'),
            Tab(text: '완료'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: '필터',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    // TODO: 실제 데이터 연동
    final mockHomework = [
      _MockHomework(
        subject: '수학',
        book: '초등 수학의 정석',
        range: 'p.45-52',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: 'dueSoon',
      ),
      _MockHomework(
        subject: '영어',
        book: '초등 영어 첫걸음',
        range: 'Unit 4 단어 암기',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        status: 'pending',
      ),
      _MockHomework(
        subject: '과학',
        book: '초등 과학 탐구',
        range: '2단원 문제풀이',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        status: 'overdue',
      ),
    ];

    if (mockHomework.isEmpty) {
      return _buildEmptyState('진행중인 숙제가 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 새로고침
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 현황 요약
          _buildSummaryRow(mockHomework),
          const SizedBox(height: 16),
          // 숙제 목록
          ...mockHomework.map((hw) => _HomeworkCard(
                homework: hw,
                onToggle: () => _toggleHomework(hw),
              )),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    // TODO: 실제 데이터 연동
    final mockHomework = [
      _MockHomework(
        subject: '수학',
        book: '초등 수학의 정석',
        range: 'p.30-44',
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
        checkResult: 'pass',
      ),
      _MockHomework(
        subject: '국어',
        book: '초등 국어 독해력',
        range: '1장 문장 이해하기',
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'completed',
        checkResult: 'pass',
      ),
    ];

    if (mockHomework.isEmpty) {
      return _buildEmptyState('완료된 숙제가 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 새로고침
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockHomework.length,
        itemBuilder: (context, index) {
          return _HomeworkCard(homework: mockHomework[index]);
        },
      ),
    );
  }

  Widget _buildSummaryRow(List<_MockHomework> homework) {
    final overdue = homework.where((h) => h.status == 'overdue').length;
    final dueSoon = homework.where((h) => h.status == 'dueSoon').length;
    final pending = homework.where((h) => h.status == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('지남', overdue, Colors.red),
          _buildSummaryItem('임박', dueSoon, Colors.orange),
          _buildSummaryItem('진행중', pending, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _toggleHomework(_MockHomework homework) {
    // TODO: 실제 데이터 업데이트
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${homework.range}" 제출 상태가 변경되었습니다')),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '필터',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: true,
                  onSelected: (_) => Navigator.pop(context),
                ),
                FilterChip(
                  label: const Text('수학'),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context),
                ),
                FilterChip(
                  label: const Text('영어'),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context),
                ),
                FilterChip(
                  label: const Text('과학'),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context),
                ),
                FilterChip(
                  label: const Text('국어'),
                  selected: false,
                  onSelected: (_) => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MockHomework {
  final String subject;
  final String book;
  final String range;
  final DateTime dueDate;
  final String status; // pending, dueSoon, overdue, completed
  final String? checkResult; // pass, fail, partial

  _MockHomework({
    required this.subject,
    required this.book,
    required this.range,
    required this.dueDate,
    required this.status,
    this.checkResult,
  });
}

class _HomeworkCard extends StatelessWidget {
  final _MockHomework homework;
  final VoidCallback? onToggle;

  const _HomeworkCard({required this.homework, this.onToggle});

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case '수학':
        return Colors.blue;
      case '영어':
        return Colors.green;
      case '과학':
        return Colors.orange;
      case '국어':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'overdue':
        return Colors.red;
      case 'dueSoon':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'overdue':
        return '지남';
      case 'dueSoon':
        return '마감 임박';
      case 'completed':
        return '완료';
      default:
        return '진행중';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final diff = targetDate.difference(today).inDays;

    if (diff == 0) return '오늘';
    if (diff == 1) return '내일';
    if (diff == -1) return '어제';
    if (diff < 0) return '${-diff}일 전';
    return '$diff일 후';
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _getSubjectColor(homework.subject);
    final statusColor = _getStatusColor(homework.status);
    final isCompleted = homework.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: subjectColor,
                  radius: 18,
                  child: Text(
                    homework.subject[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        homework.book,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        homework.subject,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _getStatusLabel(homework.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.bookmark, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    homework.range,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: homework.status == 'overdue' ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '마감: ${_formatDate(homework.dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: homework.status == 'overdue' ? Colors.red : Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (!isCompleted && onToggle != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: const Icon(Icons.check),
                  label: const Text('완료 표시'),
                ),
              ),
            ],
            if (homework.checkResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      '선생님 확인 완료',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
