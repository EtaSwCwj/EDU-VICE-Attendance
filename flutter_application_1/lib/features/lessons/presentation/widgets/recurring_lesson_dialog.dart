import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';

class RecurringLessonDialog extends StatefulWidget {
  const RecurringLessonDialog({super.key});

  @override
  State<RecurringLessonDialog> createState() => _RecurringLessonDialogState();
}

class _RecurringLessonDialogState extends State<RecurringLessonDialog> {
  DateTime _startDate = DateTime.now();
  int _weekInterval = 1; // 1=매주, 2=격주, 4=4주마다
  int _occurrences = 4; // 총 몇 회
  final Set<int> _selectedDays = {1}; // 1=월, 7=일

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'N주 반복 설정',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            _buildStartDatePicker(),
            const SizedBox(height: 16),
            _buildWeekIntervalSelector(),
            const SizedBox(height: 16),
            _buildDaySelector(),
            const SizedBox(height: 16),
            _buildOccurrencesSelector(),
            const SizedBox(height: 24),
            _buildPreview(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartDatePicker() {
    return InkWell(
      onTap: _pickStartDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '시작일',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildWeekIntervalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('반복 주기', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('매주')),
            ButtonSegment(value: 2, label: Text('격주')),
            ButtonSegment(value: 4, label: Text('4주마다')),
          ],
          selected: {_weekInterval},
          onSelectionChanged: (Set<int> selected) {
            setState(() => _weekInterval = selected.first);
          },
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    final days = [
      (1, '월'),
      (2, '화'),
      (3, '수'),
      (4, '목'),
      (5, '금'),
      (6, '토'),
      (7, '일'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('요일 선택', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: days.map((day) {
            final isSelected = _selectedDays.contains(day.$1);
            return FilterChip(
              label: Text(day.$2),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(day.$1);
                  } else {
                    if (_selectedDays.length > 1) {
                      _selectedDays.remove(day.$1);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOccurrencesSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('총 회차', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: _occurrences > 1 ? () => setState(() => _occurrences--) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$_occurrences회',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () => setState(() => _occurrences++),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final rule = RecurrenceRule(
      weekInterval: _weekInterval,
      occurrences: _occurrences,
      startDate: _startDate,
      daysOfWeek: _selectedDays.toList()..sort(),
    );

    final dates = rule.generateDates().take(5).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '미리보기 (최대 5개)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...dates.map((date) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} (${_getDayName(date.weekday)})',
                  style: const TextStyle(fontSize: 14),
                ),
              )),
          if (_occurrences > 5)
            Text(
              '... 외 ${_occurrences - 5}개',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final rule = RecurrenceRule(
              weekInterval: _weekInterval,
              occurrences: _occurrences,
              startDate: _startDate,
              daysOfWeek: _selectedDays.toList()..sort(),
            );
            Navigator.pop(context, rule);
          },
          child: const Text('생성'),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  String _getDayName(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }
}
