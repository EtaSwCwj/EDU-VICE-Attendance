import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onTap;
  final VoidCallback? onEvaluate;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;

  const LessonCard({
    super.key,
    required this.lesson,
    this.onTap,
    this.onEvaluate,
    this.onStart,
    this.onEdit,
  });

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _getStatusColor(lesson.status),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 상태 배지 + 과목명 + 시간
              Row(
                children: [
                  _StatusBadge(status: lesson.status),
                  const SizedBox(width: 8),
                  Text(
                    lesson.subject,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(lesson.scheduledAt),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 학생 수 + 수업 시간
              Row(
                children: [
                  const Icon(Icons.group, size: 16),
                  const SizedBox(width: 4),
                  Text('${lesson.studentIds.length}명'),
                  const SizedBox(width: 16),
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 4),
                  Text('${lesson.durationMinutes}분'),
                ],
              ),
              // 진도 정보 (NEW!)
              if (lesson.progress != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 16, color: Colors.indigo),
                    const SizedBox(width: 4),
                    Text(
                      lesson.progress!.displayText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              // 메모
              if (lesson.memo != null) ...[
                const SizedBox(height: 8),
                Text(
                  lesson.memo!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              // 완료된 수업: 평균 점수
              if (lesson.status == LessonStatus.completed &&
                  lesson.studentScores != null) ...[
                const SizedBox(height: 8),
                _ScoreSummary(scores: lesson.studentScores!),
              ],
              const SizedBox(height: 12),
              _ActionButtons(
                lesson: lesson,
                onEvaluate: onEvaluate,
                onStart: onStart,
                onEdit: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(LessonStatus status) {
    switch (status) {
      case LessonStatus.inProgress:
        return Colors.blue[50]!;
      case LessonStatus.completed:
        return Colors.green[50]!;
      case LessonStatus.scheduled:
        return Colors.grey[50]!;
      case LessonStatus.missed:
        return Colors.red[50]!;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final LessonStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        config.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  ({Color color, String label}) _getConfig() {
    switch (status) {
      case LessonStatus.scheduled:
        return (color: Colors.grey, label: '예정');
      case LessonStatus.inProgress:
        return (color: Colors.blue, label: '진행중');
      case LessonStatus.completed:
        return (color: Colors.green, label: '완료');
      case LessonStatus.missed:
        return (color: Colors.red, label: '미진행');
    }
  }
}

class _ScoreSummary extends StatelessWidget {
  final Map<String, int> scores;

  const _ScoreSummary({required this.scores});

  @override
  Widget build(BuildContext context) {
    final average = scores.values.isEmpty
        ? 0
        : scores.values.reduce((a, b) => a + b) / scores.values.length;

    return Row(
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          '평균 ${average.toStringAsFixed(1)}점',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback? onEvaluate;
  final VoidCallback? onStart;
  final VoidCallback? onEdit;

  const _ActionButtons({
    required this.lesson,
    this.onEvaluate,
    this.onStart,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // 완료 수업: 수정 버튼
    if (lesson.status == LessonStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: const Text('수정'),
        ),
      );
    }

    // 진행중 수업: 평가하기 버튼
    if (lesson.status == LessonStatus.inProgress) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onEvaluate,
          icon: const Icon(Icons.rate_review),
          label: const Text('평가하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    // 예정 수업: 수업 시작 버튼
    if (lesson.isToday && !lesson.isPast) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow),
          label: const Text('수업 시작'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
