import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../models/ModelProvider.dart';

class TextbookListPage extends StatefulWidget {
  const TextbookListPage({super.key});

  @override
  State<TextbookListPage> createState() => _TextbookListPageState();
}

class _TextbookListPageState extends State<TextbookListPage> {
  List<Textbook> _textbooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTextbooks();
  }

  Future<void> _loadTextbooks() async {
    print('[TextbookList] 진입');
    try {
      final request = ModelQueries.list(Textbook.classType);
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        setState(() {
          _textbooks = response.data!.items.whereType<Textbook>().toList();
          _isLoading = false;
        });
        print('[TextbookList] 데이터 로드: 성공, ${_textbooks.length}개');
      } else {
        setState(() {
          _isLoading = false;
        });
        print('[TextbookList] 데이터 로드: 실패');
      }
    } catch (e) {
      print('[TextbookList] ERROR: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교재 목록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _textbooks.isEmpty
              ? const Center(child: Text('교재가 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _textbooks.length,
                  itemBuilder: (context, index) {
                    final textbook = _textbooks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          textbook.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('출판사: ${textbook.publisher}'),
                            Text('학년/학기: ${textbook.grade} - ${textbook.semester}학기'),
                            Text('에디션: ${textbook.edition}'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          print('[TextbookList] 버튼 클릭: ${textbook.title}');
                          context.push('/textbooks/${textbook.id}/chapters');
                        },
                      ),
                    );
                  },
                ),
    );
  }
}