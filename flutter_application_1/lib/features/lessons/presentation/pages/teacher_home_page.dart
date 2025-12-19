import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../widgets/lesson_card.dart';
import '../widgets/evaluation_dialog.dart';

class TeacherHomePage extends StatefulWidget {
  final String teacherId;

  const TeacherHomePage({
    super.key,
    required this.teacherId,
  });

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadTodayLessons(widget.teacherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 수업'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<LessonProvider>().loadTodayLessons(widget.teacherId);
            },
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
                      provider.loadTodayLessons(widget.teacherId);
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (provider.totalCount == 0) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('오늘 수업이 없습니다'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadTodayLessons(widget.teacherId),
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
                  ...provider.completed.map((lesson) => LessonCard(lesson: lesson)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lessons_teacher_home_fab',
        onPressed: () {
          // TODO: 수업 추가 페이지로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('수업 추가 기능은 다음 단계에서 구현됩니다')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('수업 추가'),
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

  Future<void> _showEvaluationDialog(lesson) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EvaluationDialog(
        lesson: lesson,
        studentNames: List.generate(
          lesson.studentIds.length,
          (i) => '학생 ${i + 1}', // TODO: 실제 학생 이름 가져오기
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
        context.read<LessonProvider>().loadTodayLessons(widget.teacherId);
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
        context.read<LessonProvider>().loadTodayLessons(widget.teacherId);
      }
    }
  }
}
