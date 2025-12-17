import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../models/ModelProvider.dart';
import '../data/repositories/chapter_aws_repository.dart';
import '../../../shared/services/storage_service.dart';

/// 단원 관리 페이지
/// 교재의 단원(대단원/중단원/소단원)을 계층 구조로 관리
class ChapterManagementPage extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const ChapterManagementPage({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  State<ChapterManagementPage> createState() => _ChapterManagementPageState();
}

class _ChapterManagementPageState extends State<ChapterManagementPage> {
  final ChapterAwsRepository _chapterRepository = const ChapterAwsRepository();
  final StorageService _storageService = const StorageService();

  List<Chapter> _chapters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chapters = await _chapterRepository.getChaptersByBookId(widget.bookId);
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '단원 목록을 불러오지 못했습니다.';
        _isLoading = false;
      });
      safePrint('[ChapterManagementPage] ERROR: $e');
    }
  }

  /// 계층 구조로 단원 분류
  Map<String, List<Chapter>> _organizeChapters() {
    final Map<String, List<Chapter>> organized = {
      'root': [], // 대단원 (parentId == null, level == 1)
    };

    for (final chapter in _chapters) {
      if (chapter.parentId == null || chapter.level == 1) {
        organized['root']!.add(chapter);
        organized[chapter.id] = [];
      }
    }

    // 중단원/소단원 분류
    for (final chapter in _chapters) {
      if (chapter.parentId != null && chapter.level != 1) {
        final parentId = chapter.parentId!;
        if (organized.containsKey(parentId)) {
          organized[parentId]!.add(chapter);
        }
      }
    }

    return organized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookTitle} - 단원 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChapters,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChapterDialog(null),
        tooltip: '대단원 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChapters,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_chapters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('등록된 단원이 없습니다.'),
            SizedBox(height: 8),
            Text('+ 버튼을 눌러 대단원을 추가하세요.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final organized = _organizeChapters();
    final rootChapters = organized['root']!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rootChapters.length,
      itemBuilder: (context, index) {
        final chapter = rootChapters[index];
        final children = organized[chapter.id] ?? [];
        return _buildChapterTile(chapter, children, 0);
      },
    );
  }

  /// 단원 타일 (계층 구조)
  Widget _buildChapterTile(Chapter chapter, List<Chapter> children, int depth) {
    final levelName = _getLevelName(chapter.level ?? 1);
    final hasChildren = children.isNotEmpty;
    final indent = depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _getLevelColor(chapter.level ?? 1),
            child: Text(
              '${chapter.orderIndex + 1}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            chapter.title,
            style: TextStyle(
              fontWeight: depth == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            '$levelName${chapter.startPage != null ? ' | ${chapter.startPage}~${chapter.endPage ?? ""}p' : ''}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chapter.answerImageUrl != null)
                const Icon(Icons.image, color: Colors.green, size: 20),
              PopupMenuButton<String>(
                onSelected: (value) => _handleChapterAction(value, chapter),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('수정')),
                  const PopupMenuItem(value: 'add_child', child: Text('하위 단원 추가')),
                  const PopupMenuItem(value: 'upload_answer', child: Text('답안지 업로드')),
                  if (chapter.answerImageUrl != null)
                    const PopupMenuItem(value: 'view_answer', child: Text('답안지 보기')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('삭제', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (hasChildren)
              ...children.map((child) {
                final grandchildren = _chapters
                    .where((c) => c.parentId == child.id)
                    .toList();
                return _buildChapterTile(child, grandchildren, depth + 1);
              }),
          ],
        ),
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return '대단원';
      case 2:
        return '중단원';
      case 3:
        return '소단원';
      default:
        return '단원';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleChapterAction(String action, Chapter chapter) {
    switch (action) {
      case 'edit':
        _showEditChapterDialog(chapter);
        break;
      case 'add_child':
        _showAddChapterDialog(chapter.id);
        break;
      case 'upload_answer':
        _uploadAnswerImage(chapter);
        break;
      case 'view_answer':
        _viewAnswerImage(chapter);
        break;
      case 'delete':
        _confirmDeleteChapter(chapter);
        break;
    }
  }

  /// 단원 추가 다이얼로그
  Future<void> _showAddChapterDialog(String? parentId) async {
    final titleController = TextEditingController();
    final startPageController = TextEditingController();
    final endPageController = TextEditingController();

    int level = 1;
    if (parentId != null) {
      final parent = _chapters.firstWhere((c) => c.id == parentId);
      level = (parent.level ?? 1) + 1;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getLevelName(level)} 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '단원명',
                  hintText: '예: 1. 수와 연산',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startPageController,
                      decoration: const InputDecoration(labelText: '시작 페이지'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endPageController,
                      decoration: const InputDecoration(labelText: '끝 페이지'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('추가'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      final siblingCount = _chapters
          .where((c) => c.parentId == parentId && c.level == level)
          .length;

      await _chapterRepository.createChapter(
        bookId: widget.bookId,
        title: titleController.text,
        orderIndex: siblingCount,
        parentId: parentId,
        level: level,
        startPage: int.tryParse(startPageController.text),
        endPage: int.tryParse(endPageController.text),
      );

      _loadChapters();
    }
  }

  /// 단원 수정 다이얼로그
  Future<void> _showEditChapterDialog(Chapter chapter) async {
    final titleController = TextEditingController(text: chapter.title);
    final startPageController = TextEditingController(
      text: chapter.startPage?.toString() ?? '',
    );
    final endPageController = TextEditingController(
      text: chapter.endPage?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단원 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '단원명'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startPageController,
                      decoration: const InputDecoration(labelText: '시작 페이지'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endPageController,
                      decoration: const InputDecoration(labelText: '끝 페이지'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedChapter = chapter.copyWith(
        title: titleController.text,
        startPage: int.tryParse(startPageController.text),
        endPage: int.tryParse(endPageController.text),
      );

      await _chapterRepository.updateChapter(updatedChapter);
      _loadChapters();
    }
  }

  /// 답안지 이미지 업로드
  Future<void> _uploadAnswerImage(Chapter chapter) async {
    final imageFile = await _storageService.pickImageFile();
    if (imageFile == null) return;

    _showLoadingDialog('답안지 업로드 중...');

    try {
      final s3Key = await _storageService.uploadAnswerImage(
        chapterId: chapter.id,
        imageFile: imageFile,
      );

      if (s3Key != null) {
        await _chapterRepository.updateAnswerImageUrl(
          chapterId: chapter.id,
          answerImageUrl: s3Key,
        );

        if (mounted) {
          Navigator.pop(context); // 로딩 다이얼로그 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('답안지가 업로드되었습니다.')),
          );
          _loadChapters();
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('업로드 실패')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  /// 답안지 이미지 보기
  Future<void> _viewAnswerImage(Chapter chapter) async {
    if (chapter.answerImageUrl == null) return;

    _showLoadingDialog('답안지 로딩 중...');

    final url = await _storageService.getAnswerImageUrl(chapter.answerImageUrl);

    if (mounted) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기

      if (url != null) {
        _showImageDialog(url, chapter.title);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('답안지를 불러올 수 없습니다.')),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String url, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('$title 답안지'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('이미지를 불러올 수 없습니다.'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 단원 삭제 확인
  Future<void> _confirmDeleteChapter(Chapter chapter) async {
    final hasChildren = _chapters.any((c) => c.parentId == chapter.id);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('단원 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${chapter.title}"을(를) 삭제하시겠습니까?'),
            if (hasChildren) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ 하위 단원도 함께 삭제됩니다.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (result == true) {
      // 하위 단원도 삭제
      if (hasChildren) {
        final childChapters = _chapters.where((c) => c.parentId == chapter.id).toList();
        for (final child in childChapters) {
          await _chapterRepository.deleteChapter(child.id);
        }
      }

      await _chapterRepository.deleteChapter(chapter.id);
      _loadChapters();
    }
  }
}
