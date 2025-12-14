import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';

class EvaluationDialog extends StatefulWidget {
  final Lesson lesson;
  final List<String> studentNames; // studentId별 이름 매핑 필요

  const EvaluationDialog({
    super.key,
    required this.lesson,
    required this.studentNames,
  });

  @override
  State<EvaluationDialog> createState() => _EvaluationDialogState();
}

class _EvaluationDialogState extends State<EvaluationDialog> {
  final Map<String, int> _scores = {};
  final Map<String, bool> _attendance = {};
  final _memoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 초기값 설정
    for (final studentId in widget.lesson.studentIds) {
      _scores[studentId] = 70; // 기본 70점
      _attendance[studentId] = true; // 기본 출석
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.lesson.studentIds.length,
                itemBuilder: (context, index) {
                  final studentId = widget.lesson.studentIds[index];
                  final studentName = widget.studentNames.length > index
                      ? widget.studentNames[index]
                      : '학생 ${index + 1}';
                  return _StudentEvaluationItem(
                    studentName: studentName,
                    score: _scores[studentId]!,
                    isPresent: _attendance[studentId]!,
                    onScoreChanged: (score) {
                      setState(() => _scores[studentId] = score);
                    },
                    onAttendanceChanged: (present) {
                      setState(() => _attendance[studentId] = present);
                    },
                  );
                },
              ),
            ),
            _buildMemoSection(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.rate_review, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '수업 평가',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMemoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _memoController,
        decoration: const InputDecoration(
          labelText: '메모 (선택)',
          hintText: '수업 내용, 특이사항 등',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    Navigator.pop(context, {
      'scores': _scores,
      'attendance': _attendance,
      'memo': _memoController.text.isEmpty ? null : _memoController.text,
    });
  }
}

class _StudentEvaluationItem extends StatelessWidget {
  final String studentName;
  final int score;
  final bool isPresent;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<bool> onAttendanceChanged;

  const _StudentEvaluationItem({
    required this.studentName,
    required this.score,
    required this.isPresent,
    required this.onScoreChanged,
    required this.onAttendanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text('출석'),
                Checkbox(
                  value: isPresent,
                  onChanged: (value) => onAttendanceChanged(value ?? true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('평가 점수'),
                const SizedBox(width: 16),
                Expanded(
                  child: _ScoreSlider(
                    score: score,
                    onChanged: onScoreChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 50,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$score점',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
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
}

class _ScoreSlider extends StatelessWidget {
  final int score;
  final ValueChanged<int> onChanged;

  const _ScoreSlider({
    required this.score,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: score.toDouble(),
          min: 0,
          max: 100,
          divisions: 20, // 5점 단위
          label: '$score점',
          onChanged: (value) => onChanged(value.toInt()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('50', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text('100', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}
