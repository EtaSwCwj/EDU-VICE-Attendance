// lib/features/student/pages/student_home_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart' as aws;
import '../../../core/di/injection_container.dart';
import '../../lessons/data/repositories/lesson_aws_repository.dart';
import '../../homework/data/repositories/assignment_aws_repository.dart';

/// 학생용 홈 페이지: 오늘 수업/숙제 요약
class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final LessonAwsRepository _lessonRepo = getIt<LessonAwsRepository>();
  final AssignmentAwsRepository _assignmentRepo = getIt<AssignmentAwsRepository>();

  String _userName = '학생';
  String? _studentUsername;
  bool _loading = true;
  String? _error;

  List<aws.Lesson> _todayLessons = [];
  int _pendingHomeworkCount = 0;
  int _dueSoonHomeworkCount = 0;
  int _completedHomeworkCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 현재 사용자 정보
      final user = await Amplify.Auth.getCurrentUser();
      _studentUsername = user.username;

      safePrint('[StudentHomePage] Loading data for student: $_studentUsername');

      // 오늘 수업 조회
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayResult = await _lessonRepo.getLessonsByStudent(_studentUsername!, today);

      // 숙제 현황 조회
      final pendingCount = await _assignmentRepo.getPendingCount(_studentUsername!);

      // 마감 임박 숙제 (3일 이내)
      final allAssignments = await _assignmentRepo.getByStudent(_studentUsername!);

      final lessons = todayResult.fold(
        (f) => <aws.Lesson>[],
        (l) => l.map((lesson) => _domainToAwsLesson(lesson)).toList(),
      );

      // 마감 임박 계산 (3일 이내)
      final threeDaysLater = DateTime.now().add(const Duration(days: 3));
      final dueSoonCount = allAssignments.where((a) {
        if (a.status == aws.AssignmentStatus.DONE) return false;
        if (a.dueDate == null) return false;
        final dueDateTime = a.dueDate!.getDateTimeInUtc().toLocal();
        return dueDateTime.isBefore(threeDaysLater);
      }).length;

      // 완료된 숙제 개수
      final completedCount = allAssignments.where((a) => a.status == aws.AssignmentStatus.DONE).length;

      if (mounted) {
        setState(() {
          _userName = _studentUsername!;
          _todayLessons = lessons;
          _pendingHomeworkCount = pendingCount;
          _dueSoonHomeworkCount = dueSoonCount;
          _completedHomeworkCount = completedCount;
          _loading = false;
        });

        safePrint('[StudentHomePage] Loaded: ${lessons.length} lessons, $pendingCount pending homework');
      }
    } catch (e, stackTrace) {
      safePrint('[StudentHomePage] Error loading data: $e');
      safePrint('[StudentHomePage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = '데이터를 불러오는데 실패했습니다: $e';
          _loading = false;
        });
      }
    }
  }

  // Domain Lesson을 AWS Lesson으로 변환
  aws.Lesson _domainToAwsLesson(dynamic domainLesson) {
    return aws.Lesson(
      title: domainLesson.subject ?? '수업',
      subject: aws.Subject.MATH, // 기본값
      teacherUsername: domainLesson.teacherId ?? '',
      studentUsernames: domainLesson.studentIds ?? [],
      scheduledDate: TemporalDate(domainLesson.scheduledAt),
      startTime: TemporalTime(domainLesson.scheduledAt),
      status: aws.LessonStatus.SCHEDULED,
    );
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: _loading
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
              : RefreshIndicator(
                  onRefresh: _loadData,
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

                      // 안내 메시지
                      Card(
                        color: Colors.blue.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '데이터는 AWS에서 실시간으로 조회됩니다',
                                  style: TextStyle(color: Colors.blue[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
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
    if (_todayLessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('오늘 예정된 수업이 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: _todayLessons.map((lesson) {
        final subjectName = _getSubjectName(lesson.subject);
        final time = lesson.startTime.getDateTime();

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: _getSubjectColor(lesson.subject),
            child: Text(
              subjectName[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(lesson.title),
          subtitle: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} 예정'),
          trailing: _buildStatusChip(lesson.status),
        );
      }).toList(),
    );
  }

  Widget _buildHomeworkSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            label: '진행중',
            count: _pendingHomeworkCount,
            color: Colors.blue,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            label: '마감임박',
            count: _dueSoonHomeworkCount,
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            label: '완료',
            count: _completedHomeworkCount,
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

  Widget _buildStatusChip(aws.LessonStatus status) {
    Color color;
    String label;

    switch (status) {
      case aws.LessonStatus.IN_PROGRESS:
        color = Colors.blue;
        label = '진행중';
        break;
      case aws.LessonStatus.COMPLETED:
        color = Colors.green;
        label = '완료';
        break;
      case aws.LessonStatus.SCHEDULED:
        color = Colors.grey;
        label = '예정';
        break;
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

  String _getSubjectName(aws.Subject subject) {
    switch (subject) {
      case aws.Subject.MATH:
        return '수학';
      case aws.Subject.ENGLISH:
        return '영어';
      case aws.Subject.SCIENCE:
        return '과학';
      case aws.Subject.KOREAN:
        return '국어';
    }
  }

  Color _getSubjectColor(aws.Subject subject) {
    switch (subject) {
      case aws.Subject.MATH:
        return Colors.blue;
      case aws.Subject.ENGLISH:
        return Colors.green;
      case aws.Subject.SCIENCE:
        return Colors.orange;
      case aws.Subject.KOREAN:
        return Colors.purple;
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
