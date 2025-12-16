import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../domain/entities/lesson.dart';
import '../../../../models/ModelProvider.dart' as aws;
import '../../../../core/di/injection_container.dart';
import '../../../books/data/repositories/book_aws_repository.dart';

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
  final BookAwsRepository _bookRepo = getIt<BookAwsRepository>();

  // 일시
  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  // 책/진도 정보
  aws.Book? _selectedBook;
  String? _selectedChapter;
  final _startPageController = TextEditingController();
  final _endPageController = TextEditingController();

  // 반복 설정
  bool _isRecurring = false;
  int _weekInterval = 1;
  int _occurrences = 4;
  final Set<int> _selectedDays = {};

  // AWS Book 데이터
  List<aws.Book> _books = [];
  bool _loadingBooks = true;
  String? _bookLoadError;

  @override
  void initState() {
    super.initState();
    _selectedDays.add(_date.weekday);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loadingBooks = true;
      _bookLoadError = null;
    });

    try {
      safePrint('[LessonCreateDialog] Loading books from AWS...');
      final books = await _bookRepo.getAll();

      if (mounted) {
        setState(() {
          _books = books;
          _loadingBooks = false;
        });
        safePrint('[LessonCreateDialog] Loaded ${books.length} books');
      }
    } catch (e) {
      safePrint('[LessonCreateDialog] Error loading books: $e');
      if (mounted) {
        setState(() {
          _bookLoadError = '교재 목록을 불러오는데 실패했습니다: $e';
          _loadingBooks = false;
        });
      }
    }
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

        if (_loadingBooks)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_bookLoadError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_bookLoadError!, style: const TextStyle(color: Colors.red)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBooks,
                  tooltip: '다시 시도',
                ),
              ],
            ),
          )
        else if (_books.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '등록된 교재가 없습니다. 교재 관리 페이지에서 교재를 먼저 등록해주세요.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<aws.Book>(
            decoration: const InputDecoration(
              labelText: '교재 선택',
              border: OutlineInputBorder(),
            ),
            items: _books.map((book) {
              final subjectName = _getSubjectName(book.subject);
              final gradeName = _getGradeName(book.grade);
              return DropdownMenuItem(
                value: book,
                child: Text('${book.title} ($subjectName, $gradeName)'),
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
          TextField(
            decoration: const InputDecoration(
              labelText: '챕터/단원 (예: 1단원, Unit 1)',
              border: OutlineInputBorder(),
              hintText: '챕터 또는 단원명 입력',
            ),
            onChanged: (value) {
              _selectedChapter = value.isNotEmpty ? value : null;
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

  String _getGradeName(aws.Grade grade) {
    switch (grade) {
      case aws.Grade.ELEMENTARY:
        return '초등';
      case aws.Grade.MIDDLE:
        return '중등';
      case aws.Grade.HIGH:
        return '고등';
    }
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
    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('교재를 선택해주세요')),
      );
      return;
    }

    final progress = LessonProgress(
      chapterName: _selectedChapter,
      startPage: int.tryParse(_startPageController.text),
      endPage: int.tryParse(_endPageController.text),
    );

    // AWS Book의 subject를 String으로 변환
    String subjectString;
    switch (_selectedBook!.subject) {
      case aws.Subject.MATH:
        subjectString = '수학';
        break;
      case aws.Subject.ENGLISH:
        subjectString = '영어';
        break;
      case aws.Subject.SCIENCE:
        subjectString = '과학';
        break;
      case aws.Subject.KOREAN:
        subjectString = '국어';
        break;
    }

    final result = {
      'date': _date,
      'startTime': _startTime,
      'endTime': _endTime,
      'duration': _durationMinutes,
      'studentId': widget.studentId,
      'bookId': _selectedBook!.id, // AWS Book ID 사용
      'subject': subjectString,
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
