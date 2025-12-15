import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';

/// 테스트용 책 데이터
class _TestBook {
  final String id;
  final String title;
  final String subject;
  final List<String> chapters;

  const _TestBook(this.id, this.title, this.subject, this.chapters);
}

/// 수업 추가 다이얼로그
/// 학생 상세 페이지에서 호출됨 (학생은 이미 선택됨)
class LessonCreateDialog extends StatefulWidget {
  final String? studentId; // 학생 ID (학생 상세에서 전달)
  final String? studentName; // 학생 이름
  
  const LessonCreateDialog({
    super.key,
    this.studentId,
    this.studentName,
  });

  @override
  State<LessonCreateDialog> createState() => _LessonCreateDialogState();
}

class _LessonCreateDialogState extends State<LessonCreateDialog> {
  // 일시
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  // 책/진도 정보
  _TestBook? _selectedBook;
  String? _selectedChapter;
  final _startPageController = TextEditingController();
  final _endPageController = TextEditingController();

  // 반복 설정
  bool _isRecurring = false;
  int _weekInterval = 1;
  int _occurrences = 4;
  final Set<int> _selectedDays = {};

  // 테스트 책 데이터
  final _testBooks = [
    const _TestBook('book-math-01', '초등 수학의 정석', '수학', ['1단원 자연수', '2단원 분수', '3단원 소수', '4단원 도형', '5단원 측정']),
    const _TestBook('book-eng-01', '초등 영어 첫걸음', '영어', ['Unit 1 Greetings', 'Unit 2 Family', 'Unit 3 School', 'Unit 4 Food']),
    const _TestBook('book-sci-01', '초등 과학 탐구', '과학', ['1장 생물', '2장 화학', '3장 물리', '4장 지구과학']),
    const _TestBook('book-kor-01', '초등 국어 독해력', '국어', ['1장 문장 이해', '2장 단락 파악', '3장 글의 구조']),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays.add(_date.weekday);
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }

  int get _durationMinutes {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes - startMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 학생 정보 (읽기 전용)
                    if (widget.studentName != null) _buildStudentInfo(),
                    if (widget.studentName != null) const SizedBox(height: 20),
                    _buildDateTimeSection(),
                    const SizedBox(height: 20),
                    _buildBookSection(),
                    const SizedBox(height: 20),
                    _buildRecurringSection(),
                    if (_isRecurring) ...[
                      const SizedBox(height: 16),
                      _buildRecurringOptions(),
                    ],
                  ],
                ),
              ),
            ),
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
          const Icon(Icons.add_circle, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '수업 추가',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '학생: ${widget.studentName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📅 일시', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        // 날짜 선택
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '날짜',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(_date)),
          ),
        ),
        const SizedBox(height: 12),
        // 시작/끝 시간
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _pickStartTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '시작',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_startTime.format(context)),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('~'),
            ),
            Expanded(
              child: InkWell(
                onTap: _pickEndTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '종료',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_endTime.format(context)),
                ),
              ),
            ),
          ],
        ),
        if (_durationMinutes > 0) ...[
          const SizedBox(height: 8),
          Text(
            '수업 시간: $_durationMinutes분',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildBookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📚 교재/진도', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        DropdownButtonFormField<_TestBook>(
          decoration: const InputDecoration(
            labelText: '교재 선택',
            border: OutlineInputBorder(),
          ),
          items: _testBooks.map((book) {
            return DropdownMenuItem(
              value: book,
              child: Text('${book.title} (${book.subject})'),
            );
          }).toList(),
          onChanged: (book) {
            setState(() {
              _selectedBook = book;
              _selectedChapter = null;
            });
          },
        ),
        if (_selectedBook != null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: '챕터 선택',
              border: OutlineInputBorder(),
            ),
            items: _selectedBook!.chapters.map((chapter) {
              return DropdownMenuItem(
                value: chapter,
                child: Text(chapter),
              );
            }).toList(),
            onChanged: (chapter) {
              setState(() => _selectedChapter = chapter);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _startPageController,
                  decoration: const InputDecoration(
                    labelText: '시작 페이지',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('~'),
              ),
              Expanded(
                child: TextField(
                  controller: _endPageController,
                  decoration: const InputDecoration(
                    labelText: '끝 페이지',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRecurringSection() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('🔁 반복 수업'),
      subtitle: const Text('N주 동안 반복 생성'),
      value: _isRecurring,
      onChanged: (value) {
        setState(() => _isRecurring = value);
      },
    );
  }

  Widget _buildRecurringOptions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('반복 주기', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('매주')),
              ButtonSegment(value: 2, label: Text('격주')),
              ButtonSegment(value: 4, label: Text('4주')),
            ],
            selected: {_weekInterval},
            onSelectionChanged: (Set<int> selected) {
              setState(() => _weekInterval = selected.first);
            },
          ),
          const SizedBox(height: 16),
          const Text('요일 선택', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildDaySelector(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('총 회차:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
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
      ),
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

    return Wrap(
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
    );
  }

  Widget _buildActions() {
    final isValid = _selectedBook != null && _durationMinutes > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isValid ? _submit : null,
            child: Text(_isRecurring ? '$_occurrences회 생성' : '생성'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final progress = LessonProgress(
      chapterName: _selectedChapter,
      startPage: int.tryParse(_startPageController.text),
      endPage: int.tryParse(_endPageController.text),
    );

    final result = {
      'date': _date,
      'startTime': _startTime,
      'endTime': _endTime,
      'duration': _durationMinutes,
      'studentId': widget.studentId,
      'bookId': _selectedBook?.id,
      'subject': _selectedBook?.subject,
      'progress': progress,
      'isRecurring': _isRecurring,
      if (_isRecurring) ...{
        'recurrenceRule': RecurrenceRule(
          weekInterval: _weekInterval,
          occurrences: _occurrences,
          startDate: _date,
          daysOfWeek: _selectedDays.toList()..sort(),
        ),
      },
    };

    Navigator.pop(context, result);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        if (!_isRecurring) {
          _selectedDays.clear();
          _selectedDays.add(picked.weekday);
        }
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // 종료 시간이 시작보다 이르면 1시간 뒤로 설정
        final startMinutes = picked.hour * 60 + picked.minute;
        final endMinutes = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          _endTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      final startMinutes = _startTime.hour * 60 + _startTime.minute;
      final endMinutes = picked.hour * 60 + picked.minute;
      if (endMinutes > startMinutes) {
        setState(() => _endTime = picked);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('종료 시간은 시작 시간보다 뒤여야 합니다')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
