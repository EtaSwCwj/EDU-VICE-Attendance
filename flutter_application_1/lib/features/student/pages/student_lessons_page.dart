// lib/features/student/pages/student_lessons_page.dart
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../../models/ModelProvider.dart' as aws;
import '../../../core/di/injection_container.dart';
import '../../books/data/repositories/book_aws_repository.dart';

/// 학생용 수업 페이지: 내 수업 목록 (오늘/예정/완료)
class StudentLessonsPage extends StatefulWidget {
  const StudentLessonsPage({super.key});

  @override
  State<StudentLessonsPage> createState() => _StudentLessonsPageState();
}

class _StudentLessonsPageState extends State<StudentLessonsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<aws.Lesson> _todayLessons = [];
  List<aws.Lesson> _upcomingLessons = [];
  List<aws.Lesson> _completedLessons = [];

  bool _isLoading = true;
  String? _error;
  String? _studentUsername;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      safePrint('[StudentLessonsPage] Student username: $_studentUsername');

      if (_studentUsername == null) {
        setState(() {
          _error = '로그인 정보를 가져올 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      safePrint('[StudentLessonsPage] Querying AWS Lessons for student: $_studentUsername');

      // AWS Lesson 테이블에서 직접 조회 (studentUsernames에 현재 학생 포함된 수업)
      final request = ModelQueries.list(
        aws.Lesson.classType,
        where: aws.Lesson.STUDENTUSERNAMES.contains(_studentUsername!),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('[StudentLessonsPage] GraphQL errors: ${response.errors}');
        throw Exception('GraphQL query failed: ${response.errors}');
      }

      final allLessons = response.data?.items.whereType<aws.Lesson>().toList() ?? [];
      safePrint('[StudentLessonsPage] Found ${allLessons.length} total lessons for student');

      // 오늘 수업만 필터링
      final todayLessons = allLessons.where((lesson) {
        final lessonDate = lesson.scheduledDate.getDateTime();
        final lessonDay = DateTime(lessonDate.year, lessonDate.month, lessonDate.day);
        return lessonDay.isAtSameMomentAs(today);
      }).toList();

      setState(() {
        _todayLessons = todayLessons;
        // TODO: 예정/완료 수업도 조회
        _upcomingLessons = [];
        _completedLessons = [];
        _isLoading = false;
      });

      safePrint('[StudentLessonsPage] Loaded: ${_todayLessons.length} today lessons');
      for (final lesson in _todayLessons) {
        safePrint('[StudentLessonsPage]   - ${lesson.title}: scheduledDate=${lesson.scheduledDate}, startTime=${lesson.startTime}');
      }
    } catch (e, stackTrace) {
      safePrint('[StudentLessonsPage] Error: $e');
      safePrint('[StudentLessonsPage] Stack trace: $stackTrace');
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
      safePrint('[StudentLessonsPage] Error getting username: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 수업'),
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
            Tab(text: '오늘 (${_todayLessons.length})'),
            Tab(text: '예정 (${_upcomingLessons.length})'),
            Tab(text: '완료 (${_completedLessons.length})'),
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
                    _buildLessonList(_todayLessons, '오늘 예정된 수업이 없습니다'),
                    _buildLessonList(_upcomingLessons, '예정된 수업이 없습니다'),
                    _buildLessonList(_completedLessons, '완료된 수업이 없습니다'),
                  ],
                ),
    );
  }

  Widget _buildLessonList(List<aws.Lesson> lessons, String emptyMessage) {
    if (lessons.isEmpty) {
      return _buildEmptyState(emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        itemBuilder: (context, index) {
          return _LessonCard(lesson: lessons[index]);
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

class _LessonCard extends StatelessWidget {
  final aws.Lesson lesson;

  const _LessonCard({required this.lesson});

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

  String _getStatusLabel(aws.LessonStatus status) {
    switch (status) {
      case aws.LessonStatus.IN_PROGRESS:
        return '진행중';
      case aws.LessonStatus.COMPLETED:
        return '완료';
      case aws.LessonStatus.SCHEDULED:
        return '예정';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(lesson.subject);
    final subjectName = _getSubjectName(lesson.subject);

    // TemporalDate와 TemporalTime을 로컬 타임존으로 파싱
    // getDateTime()은 UTC로 변환할 수 있으므로, 문자열에서 직접 파싱
    final dateStr = lesson.scheduledDate.toString(); // "2025-12-16" 형식
    final dateParts = dateStr.split('-').map(int.parse).toList();

    final timeStr = lesson.startTime.toString(); // "01:00:00" 형식
    final timeParts = timeStr.split(':').map(int.parse).toList();

    safePrint('[StudentLessonsPage._LessonCard] ${lesson.title}: AWS scheduledDate=${lesson.scheduledDate}, startTime=${lesson.startTime}');
    safePrint('[StudentLessonsPage._LessonCard] Parsed date: ${dateParts[1]}/${dateParts[2]}, time: ${timeParts[0]}:${timeParts[1]}');

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
                    subjectName[0],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        lesson.teacherUsername,
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
                Text(
                  '${dateParts[1]}/${dateParts[2]} ${timeParts[0].toString().padLeft(2, '0')}:${timeParts[1].toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (lesson.duration != null) ...[
                  const Text(' · '),
                  Text('${lesson.duration}분', style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
            if (lesson.bookId != null) ...[
              const SizedBox(height: 8),
              _BookTitle(bookId: lesson.bookId!),
            ],
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
    IconData icon;

    switch (lesson.status) {
      case aws.LessonStatus.IN_PROGRESS:
        color = Colors.blue;
        icon = Icons.play_circle;
        break;
      case aws.LessonStatus.COMPLETED:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case aws.LessonStatus.SCHEDULED:
        color = Colors.grey;
        icon = Icons.schedule;
        break;
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
            _getStatusLabel(lesson.status),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// 교재 ID로 교재 제목을 조회하여 표시하는 위젯
class _BookTitle extends StatelessWidget {
  final String bookId;

  const _BookTitle({required this.bookId});

  @override
  Widget build(BuildContext context) {
    final bookRepo = getIt<BookAwsRepository>();

    return FutureBuilder<aws.Book?>(
      future: bookRepo.getById(bookId),
      builder: (context, snapshot) {
        String displayText;

        if (snapshot.connectionState == ConnectionState.waiting) {
          displayText = '로딩 중...';
        } else if (snapshot.hasError) {
          safePrint('[_BookTitle] Error loading book: ${snapshot.error}');
          displayText = '';
        } else if (snapshot.hasData && snapshot.data != null) {
          displayText = snapshot.data!.title;
        } else {
          displayText = '';
        }

        // 빈 문자열이면 위젯을 표시하지 않음
        if (displayText.isEmpty) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            const Icon(Icons.menu_book, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                displayText,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
