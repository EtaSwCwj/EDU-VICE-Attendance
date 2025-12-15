import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../lessons/presentation/providers/lesson_provider.dart';
import '../../lessons/presentation/widgets/lesson_card.dart';
import '../../lessons/domain/entities/lesson.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLessons();
    });
  }

  void _loadLessons() {
    context.read<LessonProvider>().loadLessonsByDate(
      teacherId: 'teacher-001',
      date: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수업 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSelector(),
          Expanded(
            child: Consumer<LessonProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(child: Text('에러: ${provider.error}'));
                }

                final lessons = provider.allLessons
                    .where((l) => _isSameDay(l.scheduledAt, _selectedDate))
                    .toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

                if (lessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          '${_selectedDate.month}월 ${_selectedDate.day}일\n수업이 없습니다',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) => LessonCard(
                    lesson: lessons[index],
                    onTap: () => _showLessonDetail(lessons[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // 기획서: 수업 추가/수정은 학생 탭에서만 가능
      // 수업 탭은 조회/평가 전용
    );
  }

  Widget _buildWeekSelector() {
    final today = DateTime.now();
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final date = weekDays[index];
          final isSelected = _isSameDay(date, _selectedDate);
          final isToday = _isSameDay(date, today);

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadLessons();
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : isToday
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday && !isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2026),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadLessons();
    }
  }

  void _showLessonDetail(Lesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lesson.subject,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lesson.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(lesson.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.schedule, '시간',
                '${_formatTime(lesson.scheduledAt)} (${lesson.durationMinutes}분)'),
            _buildDetailRow(Icons.group, '학생', '${lesson.studentIds.length}명'),
            if (lesson.progress != null)
              _buildDetailRow(Icons.menu_book, '진도', lesson.progress!.displayText),
            if (lesson.memo != null)
              _buildDetailRow(Icons.note, '메모', lesson.memo!),
            if (lesson.studentScores != null) ...[
              const Divider(),
              const Text('평가 결과', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...lesson.studentScores!.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('학생 ${e.key.substring(e.key.length - 3)}'),
                    const Spacer(),
                    Text('${e.value}점', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editLesson(lesson);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('수정'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteLesson(lesson);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('삭제'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.scheduled: return Colors.grey;
      case LessonStatus.inProgress: return Colors.blue;
      case LessonStatus.completed: return Colors.green;
      case LessonStatus.missed: return Colors.red;
    }
  }

  String _getStatusText(LessonStatus status) {
    switch (status) {
      case LessonStatus.scheduled: return '예정';
      case LessonStatus.inProgress: return '진행중';
      case LessonStatus.completed: return '완료';
      case LessonStatus.missed: return '미진행';
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text('$label: '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _editLesson(Lesson lesson) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('수업 수정 기능은 곧 추가됩니다')),
    );
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수업 삭제'),
        content: const Text('이 수업을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: 삭제 로직
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수업이 삭제되었습니다')),
      );
      _loadLessons();
    }
  }
}
