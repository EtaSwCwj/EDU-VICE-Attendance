// lib/features/books/presentation/pages/book_management_page.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import '../../data/repositories/book_aws_repository.dart';
import '../../../../models/ModelProvider.dart' as aws;
import '../../../book/pages/chapter_management_page.dart';

/// 교재 관리 페이지 (하단 탭용)
class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  final _bookRepo = GetIt.instance<BookAwsRepository>();
  String _filterSubject = '전체';
  List<aws.Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _loading = true);
    try {
      final books = await _bookRepo.getAll();
      if (mounted) {
        setState(() {
          _books = books;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('교재 목록 로딩 실패: $e')),
        );
      }
    }
  }

  List<aws.Book> get _filteredBooks {
    if (_filterSubject == '전체') return _books;
    return _books.where((b) {
      return subjectToKorean(b.subject) == _filterSubject;
    }).toList();
  }

  Future<void> _deleteBook(aws.Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('교재 삭제'),
        content: Text('"${book.title}"을(를) 삭제하시겠습니까?\n연결된 목차도 함께 삭제됩니다.'),
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
      safePrint('[BookManagementPage] Deleting book: ${book.id}');

      // 1. 먼저 연결된 목차 삭제
      await _bookRepo.deleteChaptersByBookId(book.id);

      // 2. 책 삭제
      await _bookRepo.deleteBook(book.id);

      await _loadBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${book.title}"이(가) 삭제되었습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교재 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooks,
            tooltip: '새로고침',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: '과목 필터',
            onSelected: (value) => setState(() => _filterSubject = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: '전체', child: Text('전체')),
              const PopupMenuItem(value: '수학', child: Text('수학')),
              const PopupMenuItem(value: '영어', child: Text('영어')),
              const PopupMenuItem(value: '과학', child: Text('과학')),
              const PopupMenuItem(value: '국어', child: Text('국어')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredBooks.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBooks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return _BookCard(
                        book: book,
                        onDelete: () => _deleteBook(book),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final result = await showDialog<aws.Book>(
            context: context,
            builder: (context) => const _BookAddDialog(),
          );
          if (result != null && mounted) {
            await _loadBooks();
            messenger.showSnackBar(
              SnackBar(content: Text('교재 "${result.title}"이(가) 추가되었습니다')),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('교재 추가'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _filterSubject == '전체' ? '등록된 교재가 없습니다' : '$_filterSubject 교재가 없습니다',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          const Text('+ 버튼을 눌러 교재를 추가하세요'),
        ],
      ),
    );
  }
}

class _BookCard extends StatefulWidget {
  final aws.Book book;
  final VoidCallback? onDelete;

  const _BookCard({required this.book, this.onDelete});

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  final _bookRepo = GetIt.instance<BookAwsRepository>();
  List<aws.Chapter> _chapters = [];
  bool _chaptersLoaded = false;

  Future<void> _loadChapters() async {
    if (_chaptersLoaded) return; // 이미 로드했으면 스킵

    safePrint('[BookManagementPage._BookCard] Loading chapters for book: ${widget.book.id}');

    try {
      final chapters = await _bookRepo.getChaptersByBookId(widget.book.id);

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _chaptersLoaded = true;
        });

        safePrint('[BookManagementPage._BookCard] Loaded ${chapters.length} chapters');
      }
    } catch (e) {
      safePrint('[BookManagementPage._BookCard] Error loading chapters: $e');
      if (mounted) {
        setState(() => _chaptersLoaded = true); // 에러여도 로드 완료로 표시
      }
    }
  }

  Color _getSubjectColor(aws.Subject subject) {
    return switch (subject) {
      aws.Subject.MATH => Colors.blue,
      aws.Subject.ENGLISH => Colors.green,
      aws.Subject.SCIENCE => Colors.orange,
      aws.Subject.KOREAN => Colors.purple,
    };
  }

  @override
  Widget build(BuildContext context) {
    final subjectName = subjectToKorean(widget.book.subject);
    final gradeName = gradeToKorean(widget.book.grade);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadChapters(); // 펼칠 때만 목차 로드
          }
        },
        leading: CircleAvatar(
          backgroundColor: _getSubjectColor(widget.book.subject),
          child: Text(
            subjectName[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(widget.book.title),
        subtitle: Text('$gradeName · ${widget.book.year ?? 2024}년'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.list_alt, color: Colors.indigo),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChapterManagementPage(
                      bookId: widget.book.id,
                      bookTitle: widget.book.title,
                    ),
                  ),
                );
              },
              tooltip: '단원 관리',
            ),
            if (widget.onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onDelete,
                tooltip: '삭제',
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('목차', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (_chaptersLoaded)
                      Text('${_chapters.length}개 챕터',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12))
                    else
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_chaptersLoaded && _chapters.isNotEmpty)
                  ..._chapters.map((chapter) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${chapter.orderIndex}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(chapter.title)),
                        ],
                      ),
                    );
                  })
                else if (_chaptersLoaded)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('등록된 목차가 없습니다', style: TextStyle(color: Colors.grey)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 교재 추가 다이얼로그
class _BookAddDialog extends StatefulWidget {
  const _BookAddDialog();

  @override
  State<_BookAddDialog> createState() => _BookAddDialogState();
}

class _BookAddDialogState extends State<_BookAddDialog> {
  final _bookRepo = GetIt.instance<BookAwsRepository>();
  final _titleController = TextEditingController();
  final _chapterController = TextEditingController();
  aws.Subject _selectedSubject = aws.Subject.MATH;
  aws.Grade _selectedGrade = aws.Grade.ELEMENTARY;
  int _publishYear = DateTime.now().year;
  final List<String> _chapters = [];
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _chapterController.dispose();
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
                    _buildBasicInfo(),
                    const SizedBox(height: 20),
                    _buildChapterSection(),
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
        color: Colors.indigo[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            '교재 추가',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('기본 정보', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: '교재 제목',
            border: OutlineInputBorder(),
            hintText: '예: 초등 수학의 정석',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<aws.Subject>(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: '과목',
                  border: OutlineInputBorder(),
                ),
                items: aws.Subject.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(subjectToKorean(s)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedSubject = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<aws.Grade>(
                initialValue: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: '학년',
                  border: OutlineInputBorder(),
                ),
                items: aws.Grade.values.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text(gradeToKorean(g)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedGrade = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _publishYear,
          decoration: const InputDecoration(
            labelText: '출판연도',
            border: OutlineInputBorder(),
          ),
          items: List.generate(10, (i) => DateTime.now().year - i).map((y) {
            return DropdownMenuItem(value: y, child: Text('$y년'));
          }).toList(),
          onChanged: (v) => setState(() => _publishYear = v!),
        ),
      ],
    );
  }

  Widget _buildChapterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('목차', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Spacer(),
            Text('${_chapters.length}개', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chapterController,
                decoration: const InputDecoration(
                  labelText: '챕터 추가',
                  border: OutlineInputBorder(),
                  hintText: '예: 1단원 자연수',
                ),
                onSubmitted: (_) => _addChapter(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addChapter,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_chapters.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('챕터를 추가해주세요', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _chapters.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _chapters.removeAt(oldIndex);
                _chapters.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return ListTile(
                key: ValueKey(_chapters[index]),
                leading: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${index + 1}'),
                ),
                title: Text(_chapters[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => setState(() => _chapters.removeAt(index)),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActions() {
    final isValid = _titleController.text.isNotEmpty && _chapters.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: (isValid && !_saving) ? _submit : null,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? '저장 중...' : '저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _addChapter() {
    final text = _chapterController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _chapters.add(text);
        _chapterController.clear();
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);

    try {
      safePrint('[BookManagementPage] Creating new book...');
      safePrint('[BookManagementPage] Chapters to save: ${_chapters.length}');

      // 1. 먼저 Book 생성
      final book = aws.Book(
        title: _titleController.text.trim(),
        subject: _selectedSubject,
        grade: _selectedGrade,
        year: _publishYear,
        chapters: null, // Book 자체의 chapters 필드는 null (별도 Chapter 테이블 사용)
      );

      final result = await _bookRepo.addBook(book);

      if (!mounted) return;

      if (result == null) {
        safePrint('[BookManagementPage] Book creation failed: result is null');
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장 실패: 결과가 null입니다')),
        );
        return;
      }

      safePrint('[BookManagementPage] Book created successfully: ${result.id}');

      // 2. 목차(Chapter) 저장
      if (_chapters.isNotEmpty) {
        safePrint('[BookManagementPage] Saving ${_chapters.length} chapters...');
        int successCount = 0;

        for (int i = 0; i < _chapters.length; i++) {
          final chapterTitle = _chapters[i];
          final chapter = await _bookRepo.createChapter(
            bookId: result.id,
            title: chapterTitle,
            orderIndex: i + 1, // 1부터 시작하는 순서
          );

          if (chapter != null) {
            successCount++;
            safePrint('[BookManagementPage] Chapter saved: $chapterTitle (order: ${i + 1})');
          } else {
            safePrint('[BookManagementPage] Failed to save chapter: $chapterTitle');
          }
        }

        safePrint('[BookManagementPage] Chapters saved: $successCount/${_chapters.length}');

        if (successCount != _chapters.length) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('경고: ${_chapters.length - successCount}개 목차 저장 실패'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      safePrint('[BookManagementPage] Book and chapters saved successfully');
      Navigator.pop(context, result);
    } catch (e, stackTrace) {
      safePrint('[BookManagementPage] Error creating book: $e');
      safePrint('[BookManagementPage] Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }
}
