import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../lessons/presentation/providers/lesson_provider.dart';
import '../../lessons/presentation/widgets/lesson_card.dart';
import '../../lessons/presentation/widgets/evaluation_dialog.dart';
import '../../lessons/domain/entities/lesson.dart';
import '../../settings/settings_page.dart';
import '../../../shared/services/auth_state.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  String? _teacherUsername;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadLessons();
    });
  }

  Future<void> _initializeAndLoadLessons() async {
    await _loadTeacherUsername();
    _loadLessons();
  }

  Future<void> _loadTeacherUsername() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      setState(() {
        _teacherUsername = user.username;
      });
      safePrint('[TeacherHomePage] Teacher username: $_teacherUsername');
    } catch (e) {
      safePrint('[TeacherHomePage] Error getting username: $e');
    }
  }

  void _loadLessons() {
    if (_teacherUsername == null) {
      safePrint('[TeacherHomePage] Cannot load lessons: teacherUsername is null');
      return;
    }
    context.read<LessonProvider>().loadTodayLessons(_teacherUsername!);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘의 수업'),
            Text(
              '${now.year}년 ${now.month}월 ${now.day}일',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLessons,
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: '설정',
          ),
        ],
      ),
      body: Consumer<LessonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      _loadLessons();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (provider.totalCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_available, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('오늘 수업이 없습니다'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTestDataDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('테스트 데이터 추가'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadLessons(),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (provider.warnings.isNotEmpty) ...[
                  _buildSectionHeader('⚠️ 경고', provider.warnings.length, Colors.red),
                  ...provider.warnings.map((lesson) => LessonCard(
                        lesson: lesson,
                        onEvaluate: () => _showEvaluationDialog(lesson),
                      )),
                  const SizedBox(height: 16),
                ],
                if (provider.inProgress.isNotEmpty) ...[
                  _buildSectionHeader('📍 진행중', provider.inProgress.length, Colors.blue),
                  ...provider.inProgress.map((lesson) => LessonCard(
                        lesson: lesson,
                        onEvaluate: () => _showEvaluationDialog(lesson),
                      )),
                  const SizedBox(height: 16),
                ],
                if (provider.upcoming.isNotEmpty) ...[
                  _buildSectionHeader('⏰ 예정', provider.upcoming.length, Colors.grey),
                  ...provider.upcoming.map((lesson) => LessonCard(
                        lesson: lesson,
                        onStart: () => _startLesson(lesson.id),
                      )),
                  const SizedBox(height: 16),
                ],
                if (provider.completed.isNotEmpty) ...[
                  _buildSectionHeader('✅ 완료', provider.completed.length, Colors.green),
                  ...provider.completed.map((lesson) => LessonCard(
                        lesson: lesson,
                        onEdit: () => _editCompletedLesson(lesson),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teacher_home_new_fab',
        onPressed: () => _showAddTestDataDialog(),
        icon: const Icon(Icons.science),
        label: const Text('테스트 데이터'),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEvaluationDialog(Lesson lesson) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EvaluationDialog(
        lesson: lesson,
        studentNames: List.generate(
          lesson.studentIds.length,
          (i) => '학생 ${i + 1}',
        ),
      ),
    );

    if (result != null && mounted) {
      final success = await context.read<LessonProvider>().recordEvaluation(
            lessonId: lesson.id,
            scores: result['scores'] as Map<String, int>,
            attendance: result['attendance'] as Map<String, bool>,
            memo: result['memo'] as String?,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('평가가 저장되었습니다')),
        );
        _loadLessons();
      }
    }
  }

  Future<void> _startLesson(String lessonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수업 시작'),
        content: const Text('수업을 시작하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<LessonProvider>().startLesson(lessonId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수업이 시작되었습니다')),
        );
        _loadLessons();
      }
    }
  }

  Future<void> _showAddTestDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테스트 데이터 추가'),
        content: const Text('오늘 수업 3개를 자동으로 추가하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _addTestData();
      _loadLessons();
    }
  }

  Future<void> _addTestData() async {
    if (_teacherUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선생님 정보를 가져올 수 없습니다')),
      );
      return;
    }

    final repository = context.read<LessonProvider>();
    final now = DateTime.now();

    // 오늘 오전 10시 수업 (진행중)
    await repository.createRecurring(
      template: Lesson(
        id: 'test-lesson-1',
        academyId: 'academy-dev',
        teacherId: _teacherUsername!,
        studentIds: ['student-001', 'student-002'],
        bookId: 'book-math-01',
        subject: '수학',
        scheduledAt: DateTime(now.year, now.month, now.day, 10, 0),
        durationMinutes: 90,
        status: LessonStatus.inProgress,
        progress: const LessonProgress(
          chapterName: '3단원 소수',
          startPage: 45,
          endPage: 52,
        ),
        isRecurring: false,
        createdAt: DateTime.now(),
      ),
      rule: RecurrenceRule(
        weekInterval: 1,
        occurrences: 1,
        startDate: now,
        daysOfWeek: [now.weekday],
      ),
    );

    // 오늘 오후 2시 수업 (예정)
    await repository.createRecurring(
      template: Lesson(
        id: 'test-lesson-2',
        academyId: 'academy-dev',
        teacherId: _teacherUsername!,
        studentIds: ['student-003'],
        bookId: 'book-english-01',
        subject: '영어',
        scheduledAt: DateTime(now.year, now.month, now.day, 14, 0),
        durationMinutes: 60,
        status: LessonStatus.scheduled,
        progress: const LessonProgress(
          chapterName: 'Unit 4 Food',
          startPage: 35,
          endPage: 42,
        ),
        isRecurring: false,
        createdAt: DateTime.now(),
      ),
      rule: RecurrenceRule(
        weekInterval: 1,
        occurrences: 1,
        startDate: now,
        daysOfWeek: [now.weekday],
      ),
    );

    // 오늘 오후 4시 수업 (예정)
    await repository.createRecurring(
      template: Lesson(
        id: 'test-lesson-3',
        academyId: 'academy-dev',
        teacherId: _teacherUsername!,
        studentIds: ['student-001', 'student-003'],
        bookId: 'book-science-01',
        subject: '과학',
        scheduledAt: DateTime(now.year, now.month, now.day, 16, 0),
        durationMinutes: 90,
        status: LessonStatus.scheduled,
        progress: const LessonProgress(
          chapterName: '2장 화학',
          startPage: 20,
          endPage: 28,
        ),
        isRecurring: false,
        createdAt: DateTime.now(),
      ),
      rule: RecurrenceRule(
        weekInterval: 1,
        occurrences: 1,
        startDate: now,
        daysOfWeek: [now.weekday],
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테스트 데이터가 추가되었습니다')),
      );
    }
  }

  void _editCompletedLesson(Lesson lesson) {
    // TODO: 수업 탭으로 이동 (해당 날짜)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수업 탭으로 이동 기능은 곧 추가됩니다')),
    );
  }

  void _openSettings() {
    try {
      final authState = context.read<AuthState>();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: authState,
            child: Scaffold(
              appBar: AppBar(title: const Text('설정')),
              body: const SettingsPage(role: 'teacher'),
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정 페이지를 열 수 없습니다')),
      );
    }
  }
}
