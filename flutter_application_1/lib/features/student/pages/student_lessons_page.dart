// lib/features/student/pages/student_lessons_page.dart
import 'package:flutter/material.dart';

/// 학생용 수업 페이지: 내 수업 목록 (오늘/예정/완료)
class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('내 수업'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '오늘'),
            Tab(text: '예정'),
            Tab(text: '완료'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildUpcomingTab(),
          _buildCompletedTab(),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    // TODO: 실제 데이터 연동
    final mockLessons = [
      _MockLesson(
        subject: '수학',
        teacher: '김선생님',
        time: '10:00 - 11:30',
        book: '초등 수학의 정석',
        chapter: '3단원 소수',
        status: 'upcoming',
      ),
      _MockLesson(
        subject: '영어',
        teacher: '박선생님',
        time: '14:00 - 15:00',
        book: '초등 영어 첫걸음',
        chapter: 'Unit 4 Food',
        status: 'upcoming',
      ),
    ];

    if (mockLessons.isEmpty) {
      return _buildEmptyState('오늘 예정된 수업이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 새로고침
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockLessons.length,
        itemBuilder: (context, index) {
          return _LessonCard(lesson: mockLessons[index]);
        },
      ),
    );
  }

  Widget _buildUpcomingTab() {
    // TODO: 실제 데이터 연동
    final mockLessons = [
      _MockLesson(
        subject: '수학',
        teacher: '김선생님',
        time: '12/18 (수) 10:00',
        book: '초등 수학의 정석',
        chapter: '4단원 도형',
        status: 'scheduled',
      ),
      _MockLesson(
        subject: '과학',
        teacher: '이선생님',
        time: '12/19 (목) 16:00',
        book: '초등 과학 탐구',
        chapter: '2단원 물질의 성질',
        status: 'scheduled',
      ),
    ];

    if (mockLessons.isEmpty) {
      return _buildEmptyState('예정된 수업이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 새로고침
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockLessons.length,
        itemBuilder: (context, index) {
          return _LessonCard(lesson: mockLessons[index]);
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    // TODO: 실제 데이터 연동
    final mockLessons = [
      _MockLesson(
        subject: '수학',
        teacher: '김선생님',
        time: '12/15 (일) 10:00',
        book: '초등 수학의 정석',
        chapter: '2단원 분수',
        status: 'completed',
        score: 85,
      ),
      _MockLesson(
        subject: '영어',
        teacher: '박선생님',
        time: '12/14 (토) 14:00',
        book: '초등 영어 첫걸음',
        chapter: 'Unit 3 School',
        status: 'completed',
        score: 90,
      ),
    ];

    if (mockLessons.isEmpty) {
      return _buildEmptyState('완료된 수업이 없습니다');
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 새로고침
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockLessons.length,
        itemBuilder: (context, index) {
          return _LessonCard(lesson: mockLessons[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _MockLesson {
  final String subject;
  final String teacher;
  final String time;
  final String book;
  final String chapter;
  final String status;
  final int? score;

  _MockLesson({
    required this.subject,
    required this.teacher,
    required this.time,
    required this.book,
    required this.chapter,
    required this.status,
    this.score,
  });
}

class _LessonCard extends StatelessWidget {
  final _MockLesson lesson;

  const _LessonCard({required this.lesson});

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

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(lesson.subject);

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
                  backgroundColor: color,
                  child: Text(
                    lesson.subject[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.subject,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        lesson.teacher,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(lesson.time, style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${lesson.book} - ${lesson.chapter}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (lesson.score != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 18, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '평가 점수: ${lesson.score}점',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (lesson.status) {
      case 'inProgress':
        color = Colors.blue;
        label = '진행중';
        icon = Icons.play_circle;
        break;
      case 'completed':
        color = Colors.green;
        label = '완료';
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        label = '예정';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
