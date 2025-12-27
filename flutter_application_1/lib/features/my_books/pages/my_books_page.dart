import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../data/local_book_repository.dart';
import '../models/local_book.dart';
import '../widgets/book_card.dart';

/// 내 책 목록 페이지
/// - 상단: 새 책 등록하기 버튼
/// - 하단: 책 카드 그리드
class MyBooksPage extends StatefulWidget {
  const MyBooksPage({super.key});

  @override
  State<MyBooksPage> createState() => _MyBooksPageState();
}

class _MyBooksPageState extends State<MyBooksPage> {
  final _repository = LocalBookRepository();
  List<LocalBook> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    safePrint('[MyBooks] 진입');
    try {
      setState(() => _isLoading = true);
      final books = await _repository.getBooks();
      setState(() {
        _books = books;
        _isLoading = false;
      });
      safePrint('[MyBooks] 책 ${books.length}개 로드');
    } catch (e) {
      safePrint('[MyBooks] ERROR: 책 로드 실패 - $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('책 목록을 불러올 수 없습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 책'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadBooks,
        child: CustomScrollView(
          slivers: [
            // 상단: 새 책 등록하기 버튼
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    safePrint('[MyBooks] 버튼 클릭: 새 책 등록하기');
                    final result = await context.push('/my-books/register');
                    if (result == true) {
                      _loadBooks(); // 등록 후 목록 새로고침
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('새 책 등록하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
            ),

            // 구분선
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('등록된 책', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 책 목록
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_books.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('등록된 책이 없습니다', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('위 버튼을 눌러 책을 등록해보세요',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = _books[index];
                      return BookCard(
                        book: book,
                        onTap: () {
                          safePrint('[MyBooks] 책 카드 탭: ${book.title}');
                          context.push('/my-books/${book.id}');
                        },
                      );
                    },
                    childCount: _books.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}