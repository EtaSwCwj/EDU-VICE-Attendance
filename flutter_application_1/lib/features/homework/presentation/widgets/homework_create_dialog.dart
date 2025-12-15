import 'package:flutter/material.dart';

/// 테스트용 책 데이터 (실제로는 BookRepository에서 가져옴)
class _TestBook {
  final String id;
  final String title;
  final String subject;
  final List<String> chapters;

  const _TestBook(this.id, this.title, this.subject, this.chapters);
}

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
  // 마감일
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  
  // 책/진도 정보
  _TestBook? _selectedBook;
  String? _selectedChapter;
  final _startPageController = TextEditingController();
  final _endPageController = TextEditingController();
  final _descriptionController = TextEditingController();

  // 테스트 책 데이터 (BookRepository와 동일하게 유지!)
  final _testBooks = [
    const _TestBook('book-math-elementary-01', '초등 수학의 정석', '수학', 
      ['1단원 자연수', '2단원 분수', '3단원 소수', '4단원 도형', '5단원 측정', '6단원 규칙성']),
    const _TestBook('book-eng-elementary-01', '초등 영어 첫걸음', '영어', 
      ['Unit 1 Greetings', 'Unit 2 Family', 'Unit 3 School', 'Unit 4 Food', 'Unit 5 Animals', 'Unit 6 Weather']),
    const _TestBook('book-sci-elementary-01', '초등 과학 탐구', '과학', 
      ['1단원 생물의 세계', '2단원 물질의 성질', '3단원 힘과 운동', '4단원 지구와 우주']),
    const _TestBook('book-kor-elementary-01', '초등 국어 독해력', '국어', 
      ['1장 문장 이해하기', '2장 단락 파악하기', '3장 글의 구조', '4장 추론하기', '5장 비판적 읽기']),
  ];

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_add, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            '숙제 발급',
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
    final isValid = _selectedBook != null && _selectedChapter != null;

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
          ElevatedButton.icon(
            onPressed: isValid ? _submit : null,
            icon: const Icon(Icons.send),
            label: const Text('발급'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final result = {
      'studentId': widget.studentId,
      'bookId': _selectedBook?.id,
      'bookTitle': _selectedBook?.title,
      'subject': _selectedBook?.subject,
      'chapter': _selectedChapter,
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
