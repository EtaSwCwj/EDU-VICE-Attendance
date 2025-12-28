import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../models/local_book.dart';
import '../data/local_book_repository.dart';
import '../widgets/volume_selector.dart';
import '../../textbook/book_camera_page.dart';
import '../../../shared/services/claude_api_service.dart';

/// 정답지 촬영/업로드 페이지
class AnswerCameraPage extends StatefulWidget {
  final String bookId;

  const AnswerCameraPage({super.key, required this.bookId});

  @override
  State<AnswerCameraPage> createState() => _AnswerCameraPageState();
}

class _AnswerCameraPageState extends State<AnswerCameraPage> {
  final _repository = LocalBookRepository();
  final _claudeService = ClaudeApiService();
  LocalBook? _book;
  int _selectedVolumeIndex = 0;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _analysisStatus = '';

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    safePrint('[AnswerCamera] 진입: ${widget.bookId}');
    try {
      final book = await _repository.getBook(widget.bookId);
      setState(() {
        _book = book;
        _isLoading = false;
      });
      safePrint('[AnswerCamera] 책 로드: ${book?.title}, volumes: ${book?.volumes.length}, totalPages: ${book?.totalPages}');
    } catch (e) {
      safePrint('[AnswerCamera] 책 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 페이지 범위 미설정 여부 확인
  bool _hasUnsetVolumes() {
    if (_book == null) return false;
    return _book!.volumes.any((vol) => (vol.totalPages ?? 0) == 0);
  }

  /// 분권별 페이지 범위 정보 문자열 생성
  String _getVolumeRangeInfo() {
    final book = _book!;
    final ranges = <String>[];
    
    for (final vol in book.volumes) {
      final start = vol.startPage ?? 1;
      final end = vol.totalPages ?? 0;
      if (end > 0) {
        ranges.add('${vol.name}: p.$start~$end');
      } else {
        ranges.add('${vol.name}: 미설정');
      }
    }
    
    return ranges.join('\n');
  }

  /// 페이지 범위 검증 결과
  Map<String, List<int>> _validatePagesAgainstVolumes(List<int> pages) {
    final result = <String, List<int>>{
      'valid': [],
      'overflow': [],
      'unknown': [],
    };
    
    final book = _book!;
    final totalPages = book.totalPages;
    
    for (final page in pages) {
      if (totalPages > 0 && page > totalPages) {
        result['overflow']!.add(page);
      } else {
        result['valid']!.add(page);
      }
    }
    
    return result;
  }

  Future<void> _startCamera() async {
    safePrint('[AnswerCamera] 카메라 촬영 시작 - Volume: ${_book!.volumes[_selectedVolumeIndex].name}');

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BookCameraPage()),
    );

    if (result != null && mounted) {
      safePrint('[AnswerCamera] 촬영 결과: pages=${result['pages']}');
      await _validateAndSavePages(result['pages'] as List<int>? ?? []);
    }
  }

  /// PDF 업로드
  Future<void> _pickPdf() async {
    safePrint('[AnswerCamera] PDF 선택 시작');

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        safePrint('[AnswerCamera] PDF 선택됨: ${file.path}');

        setState(() {
          _isAnalyzing = true;
          _analysisStatus = 'PDF 분석 중...';
        });

        final pages = await _analyzePdfWithRetry(file);

        setState(() => _isAnalyzing = false);

        if (pages.isNotEmpty) {
          safePrint('[AnswerCamera] PDF 분석 완료: $pages');
          await _validateAndSavePages(pages);
        } else {
          safePrint('[AnswerCamera] PDF에서 페이지 번호 인식 실패');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
            );
          }
        }
      }
    } catch (e) {
      safePrint('[AnswerCamera] PDF 처리 실패: $e');
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 처리 실패: $e')),
        );
      }
    }
  }

  /// 전체 Volume PDF 한번에 업로드
  Future<void> _pickPdfForAll() async {
    safePrint('[AnswerCamera] PDF 선택 시작 (전체 Volume)');

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        safePrint('[AnswerCamera] PDF 선택됨 (전체): ${file.path}');

        setState(() {
          _isAnalyzing = true;
          _analysisStatus = '전체 정답지 PDF 분석 중...';
        });

        final pages = await _analyzePdfWithRetry(file);

        setState(() => _isAnalyzing = false);

        if (pages.isNotEmpty) {
          safePrint('[AnswerCamera] 전체 PDF 분석 완료: $pages (총 ${pages.length}페이지)');
          await _validateAndSavePages(pages);
        } else {
          safePrint('[AnswerCamera] PDF에서 페이지 번호 인식 실패');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
            );
          }
        }
      }
    } catch (e) {
      safePrint('[AnswerCamera] 전체 PDF 처리 실패: $e');
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 처리 실패: $e')),
        );
      }
    }
  }

  /// PDF 분석 with 재시도 (API 429 대응) - 딜레이 늘림
  Future<List<int>> _analyzePdfWithRetry(File file, {int maxRetries = 5}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        safePrint('[AnswerCamera] PDF 분석 시도 $attempt/$maxRetries');
        
        if (attempt > 1) {
          // 재시도 전 딜레이 (429 Rate limit 대응) - 5초, 10초, 15초...
          final delaySeconds = attempt * 5;
          setState(() {
            _analysisStatus = 'API 제한으로 대기 중... (${delaySeconds}초)';
          });
          await Future.delayed(Duration(seconds: delaySeconds));
          setState(() {
            _analysisStatus = 'PDF 분석 중... (재시도 $attempt/$maxRetries)';
          });
        }
        
        return await _claudeService.analyzePdfPages(file);
      } catch (e) {
        final errorStr = e.toString();
        safePrint('[AnswerCamera] PDF 분석 실패 (시도 $attempt): $e');
        
        // 429 에러면 재시도
        if (errorStr.contains('429') && attempt < maxRetries) {
          safePrint('[AnswerCamera] Rate limit 감지, 재시도 예정...');
          continue;
        }
        
        // 마지막 시도거나 다른 에러면 throw
        if (attempt == maxRetries) {
          rethrow;
        }
      }
    }
    return [];
  }

  /// 페이지 범위 검증 후 저장
  Future<void> _validateAndSavePages(List<int> pages) async {
    if (pages.isEmpty) {
      safePrint('[AnswerCamera] 저장할 페이지 없음');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
      );
      return;
    }

    final book = _book!;
    final validation = _validatePagesAgainstVolumes(pages);
    final overflowPages = validation['overflow']!;
    
    safePrint('[AnswerCamera] 인식된 페이지: $pages');
    safePrint('[AnswerCamera] 검증 결과: valid=${validation['valid']}, overflow=$overflowPages');

    // 범위 초과가 있으면 경고 다이얼로그
    if (overflowPages.isNotEmpty && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('페이지 범위 불일치'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 현재 책의 분권별 범위
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📚 등록된 책 페이지 범위',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(_getVolumeRangeInfo(), style: const TextStyle(fontSize: 13, height: 1.5)),
                      Text('총 ${book.totalPages}페이지', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // 초과 페이지
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('⚠️ 범위 초과 페이지', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const SizedBox(height: 8),
                      Text('${overflowPages.join(", ")}p', style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text('그래도 저장하시겠습니까?', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );

      if (proceed != true) {
        safePrint('[AnswerCamera] 사용자가 저장 취소');
        return;
      }
    }

    await _savePages(pages);
  }

  Future<void> _savePages(List<int> pages) async {
    try {
      safePrint('[AnswerCamera] 페이지 저장: $pages');
      
      final existingPages = _book!.registeredPages;
      final allPages = {...existingPages, ...pages}.toList()..sort();
      
      await _repository.updateRegisteredPages(widget.bookId, allPages);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pages.length}페이지 등록 완료 (총 ${allPages.length}페이지)'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      safePrint('[AnswerCamera] 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정답지 등록'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('책 정보를 불러올 수 없습니다'))
              : _isAnalyzing
                  ? _buildAnalyzingView()
                  : _buildContent(),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_analysisStatus, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text('잠시만 기다려주세요...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final book = _book!;
    final hasMultipleVolumes = book.volumes.length > 1;
    final hasUnsetVolumes = _hasUnsetVolumes();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 제목
            Text(book.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(book.publisher, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                  child: Text('총 ${book.totalPages}페이지', style: const TextStyle(fontSize: 11)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ⚠️ 미설정 경고 + 수정 버튼
            if (hasUnsetVolumes)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('페이지 범위가 설정되지 않았습니다!', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '정답지 등록 전에 먼저 각 분권의 페이지 범위를 설정해주세요.\n'
                      '페이지 범위가 없으면 정답지 검증이 제대로 되지 않습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: 책 수정 페이지로 이동 (현재는 라우트 없으므로 안내만)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('책 수정 기능은 추후 추가 예정입니다. 현재는 책을 삭제 후 다시 등록해주세요.'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('책 정보 수정하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 분권별 페이지 범위 표시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book, size: 16, color: Colors.blue),
                      SizedBox(width: 6),
                      Text('등록된 페이지 범위', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...book.volumes.map((vol) {
                    final start = vol.startPage ?? 1;
                    final end = vol.totalPages ?? 0;
                    final isUnset = end == 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(vol.name, style: const TextStyle(fontSize: 12)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isUnset ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isUnset ? '❌ 미설정' : '✅ p.$start ~ p.$end',
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnset ? Colors.red : Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 전체 등록 버튼 (여러 Volume일 때만)
            if (hasMultipleVolumes) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('전체 정답지 한번에 등록', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('본책+워크북 정답지가 하나의 PDF라면 여기서 등록하세요', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _pickPdfForAll,
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                        label: const Text('전체 PDF 업로드'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Volume 선택
            const Text('개별 Volume 등록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            VolumeSelector(
              volumes: book.volumes,
              initialIndex: _selectedVolumeIndex,
              onVolumeChanged: (index) {
                setState(() => _selectedVolumeIndex = index);
                safePrint('[AnswerCamera] Volume 선택: ${book.volumes[index].name}');
              },
            ),

            const SizedBox(height: 16),

            // 안내
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('"${book.volumes[_selectedVolumeIndex].name}" 정답지를 등록합니다', style: const TextStyle(color: Colors.teal))),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 카메라 촬영 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startCamera,
                icon: const Icon(Icons.camera_alt, size: 24),
                label: const Text('카메라 촬영', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),

            const SizedBox(height: 12),

            // PDF 업로드 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                label: const Text('PDF 업로드', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
