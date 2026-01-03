import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/local_book.dart';
import '../models/book_volume.dart';
import '../models/problem.dart';
import '../data/local_book_repository.dart';
import '../data/problem_repository.dart';
import '../services/problem_split_service.dart';
import '../widgets/volume_selector.dart';
import '../../textbook/book_camera_page.dart';

/// 문제 촬영 페이지
/// - Volume 선택 후 촬영
/// - 촬영 결과 DB 저장 + 문제 분할
/// - 촬영 기록 표시
class ProblemCameraPage extends StatefulWidget {
  final String bookId;

  const ProblemCameraPage({super.key, required this.bookId});

  @override
  State<ProblemCameraPage> createState() => _ProblemCameraPageState();
}

class _ProblemCameraPageState extends State<ProblemCameraPage> {
  final _bookRepository = LocalBookRepository();
  final _problemRepository = ProblemRepository();
  final _problemSplitService = ProblemSplitService();
  
  LocalBook? _book;
  int _selectedVolumeIndex = 0;
  bool _isLoading = true;
  bool _isProcessing = false; // 문제 분할 중
  
  // 이번 세션 촬영 기록 (UI용)
  List<CaptureRecord> _sessionRecords = [];
  
  // 이번 세션 분할된 문제 수
  int _sessionProblemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    safePrint('[ProblemCamera] 진입: ${widget.bookId}');
    try {
      final book = await _bookRepository.getBook(widget.bookId);
      setState(() {
        _book = book;
        _isLoading = false;
      });
      safePrint('[ProblemCamera] 책 로드: ${book?.title}, volumes: ${book?.volumes.length}, 기존 촬영기록: ${book?.captureRecords.length}건');
    } catch (e) {
      safePrint('[ProblemCamera] 책 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startCamera() async {
    final volume = _book!.volumes[_selectedVolumeIndex];
    safePrint('[ProblemCamera] 촬영 시작 - Volume: ${volume.name}');

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BookCameraPage()),
    );

    if (result != null && mounted) {
      safePrint('[ProblemCamera] 촬영 결과: pages=${result['pages']}');
      await _processResult(result, volume);
    }
  }

  Future<void> _processResult(Map<String, dynamic> result, BookVolume volume) async {
    final pages = result['pages'] as List<int>? ?? [];
    if (pages.isEmpty) {
      safePrint('[ProblemCamera] 인식된 페이지 없음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
      );
      return;
    }

    final tempImageFile = result['image'] as File?;
    if (tempImageFile == null) {
      safePrint('[ProblemCamera] 이미지 없음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 받지 못했습니다')),
      );
      return;
    }

    // 처리 중 표시
    setState(() => _isProcessing = true);

    String? savedImagePath;
    List<Problem> splitProblems = [];

    try {
      // ★ 임시 파일을 영구 저장소로 즉시 복사 (임시 파일 삭제 대비)
      final documentsDir = await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${documentsDir.path}/captures/${widget.bookId}/pages');
      if (!await capturesDir.exists()) {
        await capturesDir.create(recursive: true);
        safePrint('[ProblemCamera] captures 폴더 생성: ${capturesDir.path}');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      savedImagePath = '${capturesDir.path}/capture_$timestamp.jpg';
      
      // 임시 파일 존재 확인
      if (!await tempImageFile.exists()) {
        safePrint('[ProblemCamera] ❌ 임시 파일 없음: ${tempImageFile.path}');
        throw Exception('임시 이미지 파일이 삭제됨');
      }
      
      final imageFile = await tempImageFile.copy(savedImagePath);
      safePrint('[ProblemCamera] ✅ 이미지 영구 저장: $savedImagePath');

      // 1. 각 페이지에 대해 문제 분할 실행 (영구 저장된 파일 사용)
      for (final page in pages) {
        safePrint('[ProblemCamera] 페이지 $page 문제 분할 시작...');
        
        final problems = await _problemSplitService.splitProblems(
          imageFile: imageFile,  // 복사된 파일 사용
          bookId: widget.bookId,
          page: page,
          volumeName: volume.name,
        );
        
        // 분할된 문제들 DB에 저장
        if (problems.isNotEmpty) {
          await _problemRepository.saveProblems(problems);
          splitProblems.addAll(problems);
          safePrint('[ProblemCamera] 페이지 $page: ${problems.length}개 문제 저장');
        }
      }

    } catch (e, stackTrace) {
      safePrint('[ProblemCamera] 문제 분할/저장 실패: $e');
      safePrint('[ProblemCamera] 스택트레이스: $stackTrace');
    }

    // 3. CaptureRecord 생성 및 저장
    final record = CaptureRecord(
      pages: pages,
      volumeName: volume.name,
      timestamp: DateTime.now(),
      imagePath: savedImagePath,
    );

    try {
      final updatedBook = await _bookRepository.addCaptureRecord(widget.bookId, record);

      setState(() {
        _book = updatedBook;
        _sessionRecords.insert(0, record);
        _sessionProblemCount += splitProblems.length;
        _isProcessing = false;
      });

      safePrint('[ProblemCamera] 촬영 완료: pages=$pages, 분할된 문제=${splitProblems.length}개');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              splitProblems.isNotEmpty
                  ? '${pages.join(", ")}p 저장 + ${splitProblems.length}개 문제 분할됨'
                  : '${pages.join(", ")}p 저장됨 (${volume.name})',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      safePrint('[ProblemCamera] 촬영 기록 저장 실패: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 촬영'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다'))
              : Stack(
                  children: [
                    _buildContent(),
                    // 처리 중 오버레이
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                '문제 분할 중...',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'AI가 문제 영역을 감지하고 있습니다',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildContent() {
    final book = _book!;
    final allRecords = book.captureRecords;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(book.publisher, style: TextStyle(color: Colors.grey[600])),

            const SizedBox(height: 24),

            const Text('어느 부분을 촬영하나요?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            VolumeSelector(
              volumes: book.volumes,
              initialIndex: _selectedVolumeIndex,
              onVolumeChanged: (index) {
                setState(() => _selectedVolumeIndex = index);
                safePrint('[ProblemCamera] Volume 선택: ${book.volumes[index].name}');
              },
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('"${book.volumes[_selectedVolumeIndex].name}" 문제를 촬영합니다', style: const TextStyle(color: Colors.blue))),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 사용 안내 - 문제 분할 추가 설명
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.purple, size: 18),
                      const SizedBox(width: 8),
                      Text('AI 문제 분할', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[700])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '촬영 후 AI가 자동으로 개별 문제를 감지하고 분할합니다.\n'
                    '분할된 문제는 나중에 틀린 문제 복습에 사용됩니다.',
                    style: TextStyle(color: Colors.purple[600], fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 촬영 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _startCamera,
                icon: const Icon(Icons.camera_alt, size: 28),
                label: const Text('촬영 시작', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ========== 이번 세션 촬영 기록 ==========
            if (_sessionRecords.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text('이번 세션 (${_sessionRecords.length}건)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        // 분할된 문제 수 표시
                        if (_sessionProblemCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_sessionProblemCount문제 분할',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._sessionRecords.map((record) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                            child: Text('${record.pages.join(", ")}p', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(record.volumeName, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 8),
                          Text(_formatTime(record.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    safePrint('[ProblemCamera] 촬영 완료 - 세션: ${_sessionRecords.length}건, 문제: $_sessionProblemCount개');
                    context.pop(true);
                  },
                  icon: const Icon(Icons.done_all),
                  label: Text('촬영 완료 (${_sessionRecords.length}건, $_sessionProblemCount문제)'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ========== 전체 촬영 기록 (DB 저장된 것) ==========
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text('전체 촬영 기록 (${allRecords.length}건)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('총 ${book.totalCapturedPages}페이지', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (allRecords.isEmpty)
                    Text('아직 촬영 기록이 없습니다', style: TextStyle(color: Colors.grey[500], fontSize: 13))
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: allRecords.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final record = allRecords[allRecords.length - 1 - index];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Center(child: Text('${allRecords.length - index}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                            ),
                            title: Text('${record.pages.join(", ")}p', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text('${record.volumeName} • ${_formatDateTime(record.timestamp)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            trailing: record.imagePath != null 
                                ? const Icon(Icons.image, size: 16, color: Colors.green)
                                : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year && time.month == now.month && time.day == now.day;
    
    if (isToday) {
      return '오늘 ${_formatTime(time)}';
    }
    return '${time.month}/${time.day} ${_formatTime(time)}';
  }
}
