// lib/features/student/pages/student_homework_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart' as aws;
import '../../../core/di/injection_container.dart';
import '../../homework/data/repositories/assignment_aws_repository.dart';

/// 학생용 숙제 페이지: 내 숙제 목록 (진행중/완료)
class StudentHomeworkPage extends StatefulWidget {
  const StudentHomeworkPage({super.key});

  @override
  State<StudentHomeworkPage> createState() => _StudentHomeworkPageState();
}

class _StudentHomeworkPageState extends State<StudentHomeworkPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final AssignmentAwsRepository _assignmentRepo = getIt<AssignmentAwsRepository>();

  List<aws.Assignment> _pendingAssignments = [];
  List<aws.Assignment> _completedAssignments = [];

  bool _isLoading = true;
  String? _error;
  String? _studentUsername;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 현재 학생 username 가져오기
      _studentUsername = await _getCurrentUsername();
      safePrint('[StudentHomeworkPage] Student username: $_studentUsername');

      if (_studentUsername == null) {
        setState(() {
          _error = '로그인 정보를 가져올 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      // 진행중 숙제 (ASSIGNED + IN_PROGRESS)
      final assignedFuture = _assignmentRepo.getByStudentAndStatus(
        _studentUsername!,
        aws.AssignmentStatus.ASSIGNED,
      );
      final inProgressFuture = _assignmentRepo.getByStudentAndStatus(
        _studentUsername!,
        aws.AssignmentStatus.IN_PROGRESS,
      );

      // 완료 숙제
      final doneFuture = _assignmentRepo.getByStudentAndStatus(
        _studentUsername!,
        aws.AssignmentStatus.DONE,
      );

      final results = await Future.wait([assignedFuture, inProgressFuture, doneFuture]);

      setState(() {
        _pendingAssignments = [...results[0], ...results[1]];
        // 마감일 기준 오름차순 정렬
        _pendingAssignments.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        _completedAssignments = results[2];
        _isLoading = false;
      });

      safePrint('[StudentHomeworkPage] Loaded: ${_pendingAssignments.length} pending, ${_completedAssignments.length} completed');
    } catch (e) {
      safePrint('[StudentHomeworkPage] Error: $e');
      setState(() {
        _error = '데이터를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _getCurrentUsername() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      return user.username;
    } catch (e) {
      safePrint('[StudentHomeworkPage] Error getting username: $e');
      return null;
    }
  }

  // 숙제 상태 계산 (overdue, dueSoon, pending)
  String _getHomeworkStatus(aws.Assignment assignment) {
    if (assignment.status == aws.AssignmentStatus.DONE) {
      return 'completed';
    }

    if (assignment.dueDate == null) {
      return 'pending';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateTime = assignment.dueDate!.getDateTimeInUtc().toLocal();
    final dueDate = DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);
    final diff = dueDate.difference(today).inDays;

    if (diff < 0) return 'overdue';
    if (diff <= 1) return 'dueSoon';
    return 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 숙제'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '진행중 (${_pendingAssignments.length})'),
            Tab(text: '완료 (${_completedAssignments.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingTab(),
                    _buildCompletedTab(),
                  ],
                ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingAssignments.isEmpty) {
      return _buildEmptyState('진행중인 숙제가 없습니다');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 현황 요약
          _buildSummaryRow(_pendingAssignments),
          const SizedBox(height: 16),
          // 숙제 목록
          ..._pendingAssignments.map((hw) => _HomeworkCard(
                assignment: hw,
                status: _getHomeworkStatus(hw),
                onToggle: () => _markAsCompleted(hw),
              )),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    if (_completedAssignments.isEmpty) {
      return _buildEmptyState('완료된 숙제가 없습니다');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedAssignments.length,
        itemBuilder: (context, index) {
          return _HomeworkCard(
            assignment: _completedAssignments[index],
            status: 'completed',
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(List<aws.Assignment> assignments) {
    int overdue = 0;
    int dueSoon = 0;
    int pending = 0;

    for (final hw in assignments) {
      final status = _getHomeworkStatus(hw);
      switch (status) {
        case 'overdue':
          overdue++;
          break;
        case 'dueSoon':
          dueSoon++;
          break;
        case 'pending':
          pending++;
          break;
      }
    }

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

  Future<void> _markAsCompleted(aws.Assignment assignment) async {
    safePrint('[StudentHomeworkPage] Marking assignment as completed');
    safePrint('[StudentHomeworkPage]   - Assignment ID: ${assignment.id}');
    safePrint('[StudentHomeworkPage]   - Title: ${assignment.title}');
    safePrint('[StudentHomeworkPage]   - Current status: ${assignment.status}');
    safePrint('[StudentHomeworkPage]   - Student username: ${assignment.studentUsername}');
    safePrint('[StudentHomeworkPage]   - Current user: $_studentUsername');

    final success = await _assignmentRepo.updateStatus(
      assignment.id,
      aws.AssignmentStatus.DONE,
    );

    safePrint('[StudentHomeworkPage] Update result: ${success ? "SUCCESS" : "FAILED"}');

    if (!mounted) return;

    if (success) {
      safePrint('[StudentHomeworkPage] ✅ Assignment marked as completed successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${assignment.title}" 완료 처리되었습니다')),
      );
      _loadData(); // 새로고침
    } else {
      safePrint('[StudentHomeworkPage] ❌ Failed to mark assignment as completed');
      safePrint('[StudentHomeworkPage] 가능한 원인:');
      safePrint('[StudentHomeworkPage]   1. 네트워크 오류');
      safePrint('[StudentHomeworkPage]   2. GraphQL mutation 실패 (AssignmentAwsRepository 로그 확인)');
      safePrint('[StudentHomeworkPage]   3. 권한 문제 (@auth 규칙 확인 - 학생은 update 권한 있어야 함)');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('상태 업데이트에 실패했습니다. 로그를 확인하세요.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _HomeworkCard extends StatelessWidget {
  final aws.Assignment assignment;
  final String status; // pending, dueSoon, overdue, completed
  final VoidCallback? onToggle;

  const _HomeworkCard({
    required this.assignment,
    required this.status,
    this.onToggle,
  });

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

  String _formatDate(TemporalDateTime? temporalDate) {
    if (temporalDate == null) return '마감일 없음';

    final date = temporalDate.getDateTimeInUtc().toLocal();
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
    final statusColor = _getStatusColor(status);
    final isCompleted = status == 'completed';

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
                  backgroundColor: Colors.blue,
                  radius: 18,
                  child: Text(
                    assignment.title[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (assignment.book != null)
                        Text(
                          assignment.book!,
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
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (assignment.range != null || assignment.description != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      assignment.range ?? assignment.description ?? '',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: status == 'overdue' ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '마감: ${_formatDate(assignment.dueDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: status == 'overdue' ? Colors.red : Colors.grey[600],
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
            if (isCompleted) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      '완료됨',
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
