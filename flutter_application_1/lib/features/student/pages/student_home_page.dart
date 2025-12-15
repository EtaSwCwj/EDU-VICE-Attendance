// lib/features/student/pages/student_home_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// 학생용 홈 페이지: 오늘 수업/숙제 요약
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _userName = '학생';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      if (mounted) {
        setState(() {
          _userName = user.username;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = '학생';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _loading
                ? const Text('로딩 중...')
                : Text('안녕하세요, $_userName님'),
            Text(
              '${now.year}년 ${now.month}월 ${now.day}일',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: 데이터 새로고침
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 오늘 수업 요약
            _buildSectionCard(
              context,
              icon: Icons.school,
              iconColor: Colors.blue,
              title: '오늘의 수업',
              child: _buildTodayLessons(context),
            ),
            const SizedBox(height: 16),

            // 숙제 현황 요약
            _buildSectionCard(
              context,
              icon: Icons.assignment,
              iconColor: Colors.orange,
              title: '숙제 현황',
              child: _buildHomeworkSummary(context),
            ),
            const SizedBox(height: 16),

            // 진도 현황 요약
            _buildSectionCard(
              context,
              icon: Icons.trending_up,
              iconColor: Colors.green,
              title: '학습 진도',
              child: _buildProgressSummary(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLessons(BuildContext context) {
    // TODO: 실제 데이터 연동
    final mockLessons = [
      {'subject': '수학', 'time': '10:00', 'status': 'upcoming'},
      {'subject': '영어', 'time': '14:00', 'status': 'upcoming'},
    ];

    if (mockLessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('오늘 예정된 수업이 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: mockLessons.map((lesson) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: _getSubjectColor(lesson['subject'] as String),
            child: Text(
              (lesson['subject'] as String)[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(lesson['subject'] as String),
          subtitle: Text('${lesson['time']} 예정'),
          trailing: _buildStatusChip(lesson['status'] as String),
        );
      }).toList(),
    );
  }

  Widget _buildHomeworkSummary(BuildContext context) {
    // TODO: 실제 데이터 연동
    final summary = {
      'pending': 3,
      'dueSoon': 1,
      'completed': 5,
    };

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            label: '진행중',
            count: summary['pending']!,
            color: Colors.blue,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            label: '마감임박',
            count: summary['dueSoon']!,
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            label: '완료',
            count: summary['completed']!,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(BuildContext context) {
    // TODO: 실제 데이터 연동
    final mockProgress = [
      {'subject': '수학', 'book': '초등 수학의 정석', 'progress': 0.65},
      {'subject': '영어', 'book': '초등 영어 첫걸음', 'progress': 0.40},
    ];

    if (mockProgress.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('진행 중인 교재가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: mockProgress.map((item) {
        final progress = item['progress'] as double;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['book'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: _getSubjectColor(item['subject'] as String),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  _getSubjectColor(item['subject'] as String),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'inProgress':
        color = Colors.blue;
        label = '진행중';
        break;
      case 'completed':
        color = Colors.green;
        label = '완료';
        break;
      default:
        color = Colors.grey;
        label = '예정';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

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

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Amplify.Auth.signOut();
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('로그아웃 실패: $e')),
          );
        }
      }
    }
  }
}
