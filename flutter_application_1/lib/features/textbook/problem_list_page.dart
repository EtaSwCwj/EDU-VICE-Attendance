import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../models/ModelProvider.dart';

class ProblemListPage extends StatefulWidget {
  final String textbookId;
  final String chapterId;

  const ProblemListPage({
    super.key,
    required this.textbookId,
    required this.chapterId,
  });

  @override
  State<ProblemListPage> createState() => _ProblemListPageState();
}

class _ProblemListPageState extends State<ProblemListPage> {
  List<Problem> _problems = [];
  TextbookChapter? _chapter;
  bool _isLoading = true;
  final Set<String> _expandedProblems = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('[ProblemList] 진입');
    await Future.wait([
      _loadChapter(),
      _loadProblems(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadChapter() async {
    try {
      final request = ModelQueries.list(TextbookChapter.classType, where: TextbookChapter.ID.eq(widget.chapterId));
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        _chapter = response.data?.items.firstOrNull;
      }
    } catch (e) {
      print('[ProblemList] ERROR loading chapter: $e');
    }
  }

  Future<void> _loadProblems() async {
    try {
      final request = ModelQueries.list(
        Problem.classType,
        where: Problem.CHAPTERID.eq(widget.chapterId),
      );
      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final problems = response.data!.items.whereType<Problem>().toList();
        // 문제 번호로 정렬
        problems.sort((a, b) => a.number.compareTo(b.number));
        setState(() {
          _problems = problems;
        });
        print('[ProblemList] 데이터 로드: 성공, ${_problems.length}개');
      } else {
        print('[ProblemList] 데이터 로드: 실패');
      }
    } catch (e) {
      print('[ProblemList] ERROR: $e');
    }
  }

  Color _getDifficultyColor(Difficulty? difficulty) {
    switch (difficulty) {
      case Difficulty.BASIC:
        return Colors.green;
      case Difficulty.MEDIUM:
        return Colors.orange;
      case Difficulty.HARD:
        return Colors.red;
      case null:
        return Colors.grey;
    }
  }

  String _getDifficultyText(Difficulty? difficulty) {
    switch (difficulty) {
      case Difficulty.BASIC:
        return '기본';
      case Difficulty.MEDIUM:
        return '보통';
      case Difficulty.HARD:
        return '어려움';
      case null:
        return '-';
    }
  }

  Color _getCategoryColor(ProblemCategory? category) {
    switch (category) {
      case ProblemCategory.CONCEPT:
        return Colors.blue;
      case ProblemCategory.APPLICATION:
        return Colors.teal;
      case null:
        return Colors.grey;
    }
  }

  String _getCategoryText(ProblemCategory? category) {
    switch (category) {
      case ProblemCategory.CONCEPT:
        return '개념';
      case ProblemCategory.APPLICATION:
        return '응용';
      case null:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_chapter?.title ?? '문제 목록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _problems.isEmpty
              ? const Center(child: Text('문제가 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _problems.length,
                  itemBuilder: (context, index) {
                    final problem = _problems[index];
                    final isExpanded = _expandedProblems.contains(problem.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(
                                problem.number,
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              problem.question ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Text('p.${problem.page}'),
                                  const SizedBox(width: 12),
                                  Chip(
                                    label: Text(
                                      _getDifficultyText(problem.difficulty),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _getDifficultyColor(problem.difficulty),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      _getCategoryText(problem.category),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: _getCategoryColor(problem.category),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedProblems.remove(problem.id);
                                  } else {
                                    _expandedProblems.add(problem.id);
                                  }
                                });
                              },
                            ),
                          ),
                          if (isExpanded)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              color: Theme.of(context).primaryColor.withOpacity(0.05),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '정답',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    problem.answer,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  if (problem.concepts?.isNotEmpty == true) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      '관련 개념',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8.0,
                                      children: problem.concepts!.map((concept) => Chip(
                                        label: Text(
                                          concept,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.grey.shade200,
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}