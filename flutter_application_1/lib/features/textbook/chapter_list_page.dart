import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:go_router/go_router.dart';
import '../../models/ModelProvider.dart';

class ChapterListPage extends StatefulWidget {
  final String textbookId;

  const ChapterListPage({
    super.key,
    required this.textbookId,
  });

  @override
  State<ChapterListPage> createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  List<TextbookChapter> _chapters = [];
  Textbook? _textbook;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('[ChapterList] 진입');
    await Future.wait([
      _loadTextbook(),
      _loadChapters(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadTextbook() async {
    try {
      final request = ModelQueries.list(Textbook.classType, where: Textbook.ID.eq(widget.textbookId));
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        _textbook = response.data?.items.firstOrNull;
      }
    } catch (e) {
      print('[ChapterList] ERROR loading textbook: $e');
    }
  }

  Future<void> _loadChapters() async {
    try {
      final request = ModelQueries.list(
        TextbookChapter.classType,
        where: TextbookChapter.TEXTBOOKID.eq(widget.textbookId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final chapters = response.data!.items.whereType<TextbookChapter>().toList();
        // 단원 번호로 정렬
        chapters.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
        setState(() {
          _chapters = chapters;
        });
        print('[ChapterList] 데이터 로드: 성공, ${_chapters.length}개');
      } else {
        print('[ChapterList] 데이터 로드: 실패');
      }
    } catch (e) {
      print('[ChapterList] ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_textbook?.title ?? '단원 목록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chapters.isEmpty
              ? const Center(child: Text('단원이 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: Text(
                            '${chapter.number ?? 0}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('섹션: ${chapter.section ?? '-'}'),
                            Text('페이지: ${chapter.startPage ?? 0} ~ ${chapter.endPage ?? 0}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          print('[ChapterList] 버튼 클릭: ${chapter.title}');
                          context.go('/textbooks/${widget.textbookId}/chapters/${chapter.id}/problems');
                        },
                      ),
                    );
                  },
                ),
    );
  }
}