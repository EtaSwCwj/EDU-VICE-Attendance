import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../data/local_book_repository.dart';
import '../models/local_book.dart';
import '../widgets/page_map_widget.dart';

/// 책 상세 페이지
/// - 상단: 책 정보 (표지, 제목, 출판사, 진행률)
/// - 중앙: 페이지 맵 위젯
/// - 하단: "정답지 등록" / "문제 촬영" 버튼
class BookDetailPage extends StatefulWidget {
  final String bookId;

  const BookDetailPage({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final _repository = LocalBookRepository();
  LocalBook? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    safePrint('[BookDetail] 진입: ${widget.bookId}');
    try {
      final book = await _repository.getBook(widget.bookId);
      if (book != null) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
        safePrint('[BookDetail] 책 로드 성공: ${book.title}');
      } else {
        setState(() => _isLoading = false);
        safePrint('[BookDetail] 책을 찾을 수 없음: ${widget.bookId}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('책을 찾을 수 없습니다')),
          );
          context.pop();
        }
      }
    } catch (e) {
      safePrint('[BookDetail] ERROR: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('책 정보 로드 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book?.title ?? '책 상세'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_book != null)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirmed = await _showDeleteDialog();
                  if (confirmed == true) {
                    await _deleteBook();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상단: 책 정보
                      _buildBookInfo(),

                      const Divider(height: 32),

                      // 중앙: 페이지 맵
                      _buildPageMapSection(),

                      const SizedBox(height: 24),

                      // 하단: 액션 버튼들
                      _buildActionButtons(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBookInfo() {
    final book = _book!;
    final progressPercent = (book.progress * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 표지
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
            ),
            child: book.coverImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(book.coverImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultCover(),
                    ),
                  )
                : _buildDefaultCover(),
          ),
          const SizedBox(width: 16),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.publisher,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.school, book.grade),
                    const SizedBox(width: 8),
                    _buildInfoChip(_getSubjectIcon(book.subject), book.subject),
                  ],
                ),
                const SizedBox(height: 12),
                // 진행률
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '진행률: $progressPercent% (${book.registeredPages.length}/${book.totalPages}페이지)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: book.progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCover() {
    final book = _book!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          _getSubjectIcon(book.subject),
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPageMapSection() {
    final book = _book!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '페이지 맵',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '녹색: 정답지 등록됨, 회색: 미등록',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PageMapWidget(
              totalPages: book.totalPages,
              registeredPages: book.registeredPages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 정답지 등록
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                safePrint('[BookDetail] 버튼 클릭: 정답지 등록');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('정답지 등록 기능은 준비 중입니다')),
                );
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('정답지 등록'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 문제 촬영
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                safePrint('[BookDetail] 버튼 클릭: 문제 촬영');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('문제 촬영 기능은 준비 중입니다')),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('문제 촬영'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('책 삭제'),
        content: Text('정말로 "${_book?.title}"을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook() async {
    try {
      await _repository.deleteBook(widget.bookId);
      safePrint('[BookDetail] 책 삭제 완료');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('책이 삭제되었습니다')),
        );
        context.pop();
      }
    } catch (e) {
      safePrint('[BookDetail] 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  IconData _getSubjectIcon(String subject) {
    switch (subject.toUpperCase()) {
      case 'ENGLISH':
        return Icons.abc;
      case 'MATH':
        return Icons.calculate;
      case 'KOREAN':
        return Icons.translate;
      case 'SCIENCE':
        return Icons.science;
      default:
        return Icons.menu_book;
    }
  }
}