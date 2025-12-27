import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:go_router/go_router.dart';
import '../../models/ModelProvider.dart';

/// 교재 탭 메인 페이지
/// - 상단: 새 페이지 분석 버튼
/// - 하단: 교재 목록
class TextbookMainPage extends StatefulWidget {
  const TextbookMainPage({super.key});

  @override
  State<TextbookMainPage> createState() => _TextbookMainPageState();
}

class _TextbookMainPageState extends State<TextbookMainPage> {
  List<Textbook> _textbooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTextbooks();
  }

  Future<void> _loadTextbooks() async {
    safePrint('[TextbookMain] 진입');
    try {
      final request = ModelQueries.list(Textbook.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        setState(() {
          _textbooks = response.data!.items.whereType<Textbook>().toList();
          _isLoading = false;
        });
        safePrint('[TextbookMain] 데이터 로드: 성공, ${_textbooks.length}개');
      } else {
        setState(() => _isLoading = false);
        safePrint('[TextbookMain] 데이터 로드: 실패');
      }
    } catch (e) {
      safePrint('[TextbookMain] ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadTextbooks,
        child: CustomScrollView(
          slivers: [
            // 상단: 새 페이지 분석 버튼
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.push('/textbook-analyzer'),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('새 페이지 분석'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/ocr-test'),
                      icon: const Icon(Icons.science),
                      label: const Text('OCR 테스트 (실험)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
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
                      child: Text('등록된 교재', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            
            // 교재 목록
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_textbooks.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('등록된 교재가 없습니다', style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('위 버튼을 눌러 교재 페이지를 분석해보세요', 
                           style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final textbook = _textbooks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.menu_book,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          title: Text(
                            textbook.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${textbook.grade} · ${textbook.publisher}'),
                              Text('${textbook.publishYear}년 · ${_subjectName(textbook.subject)}'),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            safePrint('[TextbookMain] 버튼 클릭: ${textbook.title}');
                            context.push('/textbooks/${textbook.id}/chapters');
                          },
                        ),
                      );
                    },
                    childCount: _textbooks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _subjectName(Subject s) {
    switch (s) {
      case Subject.MATH:
        return '수학';
      case Subject.ENGLISH:
        return '영어';
      case Subject.KOREAN:
        return '국어';
      case Subject.SCIENCE:
        return '과학';
    }
  }
}
