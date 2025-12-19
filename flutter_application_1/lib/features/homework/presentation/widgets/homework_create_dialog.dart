import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/ModelProvider.dart' as aws;
import '../../../../core/di/injection_container.dart';
import '../../../books/data/repositories/book_aws_repository.dart';

/// 숙제 발급 다이얼로그
/// 학생 상세 페이지에서 호출됨
class HomeworkCreateDialog extends StatefulWidget {
  final String studentId;
  final String studentName;

  const HomeworkCreateDialog({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<HomeworkCreateDialog> createState() => _HomeworkCreateDialogState();
}

class _HomeworkCreateDialogState extends State<HomeworkCreateDialog> {
  final BookAwsRepository _bookRepo = getIt<BookAwsRepository>();

  // 마감일
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));

  // 책/진도 정보
  aws.Book? _selectedBook;
  aws.Chapter? _selectedChapter;
  String? _manualChapter; // 수기 입력 챕터
  final _startPageController = TextEditingController();
  final _endPageController = TextEditingController();
  final _descriptionController = TextEditingController();

  // AWS Book 데이터
  List<aws.Book> _books = [];
  bool _loadingBooks = true;
  String? _bookLoadError;

  // AWS Chapter 데이터
  List<aws.Chapter> _chapters = [];
  bool _loadingChapters = false;
  String? _chapterLoadError;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _loadingBooks = true;
      _bookLoadError = null;
    });

    try {
      safePrint('[HomeworkCreateDialog] Loading books from AWS...');
      final books = await _bookRepo.getAll();

      if (mounted) {
        setState(() {
          _books = books;
          _loadingBooks = false;
        });
        safePrint('[HomeworkCreateDialog] Loaded ${books.length} books');
      }
    } catch (e) {
      safePrint('[HomeworkCreateDialog] Error loading books: $e');
      if (mounted) {
        setState(() {
          _bookLoadError = '교재 목록을 불러오는데 실패했습니다: $e';
          _loadingBooks = false;
        });
      }
    }
  }

  Future<void> _loadChapters(String bookId) async {
    setState(() {
      _loadingChapters = true;
      _chapterLoadError = null;
      _chapters = [];
      _selectedChapter = null;
      _manualChapter = null;
    });

    try {
      safePrint('[HomeworkCreateDialog] Loading chapters for book: $bookId');
      final chapters = await _bookRepo.getChaptersByBookId(bookId);

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _loadingChapters = false;
        });
        safePrint('[HomeworkCreateDialog] Loaded ${chapters.length} chapters');
      }
    } catch (e) {
      safePrint('[HomeworkCreateDialog] Error loading chapters: $e');
      if (mounted) {
        setState(() {
          _chapterLoadError = '챕터 목록을 불러오는데 실패했습니다: $e';
          _loadingChapters = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
                    _buildStudentInfo(),
                    const SizedBox(height: 20),
                    _buildDueDateSection(),
                    const SizedBox(height: 20),
                    _buildBookSection(),
                    const SizedBox(height: 20),
                    _buildDescriptionSection(),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.assignment_add, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '숙제 발급',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
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

  Widget _buildDueDateSection() {
    final daysRemaining = _dueDate.difference(DateTime.now()).inDays;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📅 마감일', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDueDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '마감일',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(_dueDate)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          daysRemaining > 0 ? 'D-$daysRemaining' : (daysRemaining == 0 ? '오늘 마감' : 'D+${-daysRemaining} (기한 초과)'),
          style: TextStyle(
            color: daysRemaining > 0 ? Colors.blue : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBookSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📚 교재/범위', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              });
              if (book != null) {
                _loadChapters(book.id);
              }
            },
          ),

        if (_selectedBook != null) ...[
          const SizedBox(height: 12),
          if (_loadingChapters)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_chapterLoadError != null)
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
                    child: Text(_chapterLoadError!, style: const TextStyle(color: Colors.red)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => _loadChapters(_selectedBook!.id),
                    tooltip: '다시 시도',
                  ),
                ],
              ),
            )
          else if (_chapters.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '등록된 목차 없음',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '챕터/단원 (예: 1단원, Unit 1)',
                    border: OutlineInputBorder(),
                    hintText: '챕터 또는 단원명 입력',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _manualChapter = value.isNotEmpty ? value : null;
                    });
                  },
                ),
              ],
            )
          else
            DropdownButtonFormField<aws.Chapter>(
              decoration: const InputDecoration(
                labelText: '챕터 선택',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedChapter,
              items: _chapters.map((chapter) {
                return DropdownMenuItem(
                  value: chapter,
                  child: Text('${chapter.orderIndex}. ${chapter.title}'),
                );
              }).toList(),
              onChanged: (chapter) {
                setState(() {
                  _selectedChapter = chapter;
                });
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

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📝 숙제 내용', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '숙제 내용 (예: 문제풀이, 단어암기)',
            border: OutlineInputBorder(),
            hintText: '예: 1~20번 문제풀이',
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildActions() {
    final isValid = _selectedBook != null && (_selectedChapter != null || _manualChapter != null || _descriptionController.text.isNotEmpty);

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
          FilledButton.icon(
            onPressed: isValid ? _submit : null,
            icon: const Icon(Icons.send),
            label: const Text('발급'),
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

    // 챕터 정보: 드롭다운에서 선택했으면 그 제목, 아니면 수기 입력 사용
    final chapterText = _selectedChapter?.title ?? _manualChapter;

    final result = {
      'studentId': widget.studentId,
      'bookId': _selectedBook!.id, // AWS Book ID 사용
      'bookTitle': _selectedBook!.title,
      'subject': subjectString,
      'chapter': chapterText,
      'startPage': int.tryParse(_startPageController.text),
      'endPage': int.tryParse(_endPageController.text),
      'description': _descriptionController.text,
      'dueDate': _dueDate,
      'assignedAt': DateTime.now(),
    };

    Navigator.pop(context, result);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
