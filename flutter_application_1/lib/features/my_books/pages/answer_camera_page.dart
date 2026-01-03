import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/local_book.dart';
import '../data/local_book_repository.dart';
import '../widgets/volume_selector.dart';
import '../../textbook/book_camera_page.dart';
import '../../../shared/services/claude_api_service.dart';
import '../../../shared/services/pdf_to_image_service.dart';
import '../../../shared/services/answer_parser_service.dart';

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
  final _answerParser = AnswerParserService();
  LocalBook? _book;
  int _selectedVolumeIndex = 0;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String _analysisStatus = '';
  int _currentChunk = 0;
  int _totalChunks = 0;

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
      safePrint('[AnswerCamera] 촬영 결과 수신');
      
      // 이미지 파일로 OCR+AI 파싱
      final imageFile = result['image'] as File?;
      if (imageFile != null) {
        safePrint('[AnswerCamera] 이미지 파일로 OCR+AI 파싱 시작: ${imageFile.path}');
        
        setState(() {
          _isAnalyzing = true;
          _analysisStatus = '정답지 분석 중...';
        });
        
        try {
          final parsedPages = await _answerParser.extractAnswers(imageFile);
          
          setState(() => _isAnalyzing = false);
          
          if (parsedPages.isNotEmpty) {
            safePrint('[AnswerCamera] OCR+AI 파싱 완료: ${parsedPages.length}페이지');
            
            final pageResults = parsedPages.map((p) => p.toMap()).toList();
            final proceed = await _showExtractedTextDialog(pageResults);
            
            if (proceed == true) {
              final pages = parsedPages.map((p) => p.pageNumber).where((p) => p > 0).toList();
              final answerContents = <int, String>{};
              for (final p in parsedPages) {
                if (p.pageNumber > 0) {
                  answerContents[p.pageNumber] = p.rawContent;
                }
              }
              await _validateAndSavePagesWithAnswers(pages, answerContents);
            }
          } else {
            safePrint('[AnswerCamera] OCR+AI 파싱 결과 없음');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('정답지를 인식하지 못했습니다')),
              );
            }
          }
        } catch (e) {
          safePrint('[AnswerCamera] OCR+AI 파싱 실패: $e');
          setState(() => _isAnalyzing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('분석 실패: $e')),
            );
          }
        }
      } else {
        // 이미지 없으면 기존 방식 (페이지 번호만)
        safePrint('[AnswerCamera] 이미지 없음, 기존 방식 사용: pages=${result['pages']}');
        await _validateAndSavePages(result['pages'] as List<int>? ?? []);
      }
    }
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickFromGallery() async {
    safePrint('[AnswerCamera] 갤러리 선택 시작');

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {
        final imageFile = File(pickedFile.path);
        safePrint('[AnswerCamera] 갤러리 이미지 선택됨: ${imageFile.path}');

        setState(() {
          _isAnalyzing = true;
          _analysisStatus = '정답지 분석 중...';
        });

        try {
          final parsedPages = await _answerParser.extractAnswers(imageFile);

          setState(() => _isAnalyzing = false);

          if (parsedPages.isNotEmpty) {
            safePrint('[AnswerCamera] OCR+AI 파싱 완료: ${parsedPages.length}페이지');

            final pageResults = parsedPages.map((p) => p.toMap()).toList();
            final proceed = await _showExtractedTextDialog(pageResults);

            if (proceed == true) {
              final pages = parsedPages.map((p) => p.pageNumber).where((p) => p > 0).toList();
              final answerContents = <int, String>{};
              for (final p in parsedPages) {
                if (p.pageNumber > 0) {
                  answerContents[p.pageNumber] = p.rawContent;
                }
              }
              await _validateAndSavePagesWithAnswers(pages, answerContents);
            }
          } else {
            safePrint('[AnswerCamera] OCR+AI 파싱 결과 없음');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('정답지를 인식하지 못했습니다')),
              );
            }
          }
        } catch (e) {
          safePrint('[AnswerCamera] OCR+AI 파싱 실패: $e');
          setState(() => _isAnalyzing = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('분석 실패: $e')),
            );
          }
        }
      }
    } catch (e) {
      safePrint('[AnswerCamera] 갤러리 선택 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
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

  /// 전체 Volume PDF 한번에 업로드 (청크 분할 처리)
  /// 전체 Volume PDF 한번에 업로드 (BIG_140: 단순화 - 열 분리 없이 직접 OCR+AI)
  Future<void> _pickPdfForAll() async {
    safePrint('[PDF처리] ========================================');
    safePrint('[PDF처리] PDF 선택 시작 (BIG_140: 단순화 방식)');
    safePrint('[PDF처리] 열 분리/병합 제거, 이미지 그대로 OCR+AI');
    safePrint('[PDF처리] ========================================');

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        safePrint('[PDF처리] PDF 선택됨: ${file.path}');
        safePrint('[PDF처리] 파일 크기: ${(fileSize / 1024).toStringAsFixed(1)} KB');

        setState(() {
          _isAnalyzing = true;
          _analysisStatus = 'PDF → 이미지 변환 중...';
        });

        // 1. PDF → 이미지 변환 + AI 열 분리
        // ★ BIG_144: 책 이름 전달 + 2페이지만 테스트
        safePrint('[PDF처리] Step 1: PDF → 이미지 변환 + 열 분리 시작');
        final bookName = _book?.title?.replaceAll(RegExp(r'[^\w가-힣]'), '_') ?? 'book';
        safePrint('[PDF처리] 책 이름: $bookName');
        final stopwatch = Stopwatch()..start();
        final pageImages = await PdfToImageService.convertPdfToImages(
          file,
          maxPages: 2,  // BIG_144 테스트: 2페이지만 (1페이지=2열, 2페이지=4열)
          bookName: bookName,
        );
        stopwatch.stop();
        safePrint('[PDF처리] Step 1 완료: ${pageImages.length}개 열 이미지, ${stopwatch.elapsedMilliseconds}ms');
        
        // ★ BIG_142: 각 이미지 상세 정보 로그
        for (int i = 0; i < pageImages.length; i++) {
          final imgFile = pageImages[i];
          final imgSize = await imgFile.length();

          // 이미지 해상도 확인
          final imgBytes = await imgFile.readAsBytes();
          final decodedImage = await decodeImageFromList(imgBytes);

          safePrint('[PDF처리] - 이미지 ${i + 1}:');
          safePrint('[PDF처리]   경로: ${imgFile.path}');
          safePrint('[PDF처리]   크기: ${(imgSize / 1024).toStringAsFixed(1)} KB');
          safePrint('[PDF처리]   해상도: ${decodedImage.width} x ${decodedImage.height}');
        }

        setState(() {
          _totalChunks = pageImages.length;
          _currentChunk = 0;
        });

        List<Map<String, dynamic>> allExtractedPages = [];

        // 2. 각 열 이미지 OCR+AI 처리
        // ★ BIG_144: 모든 열 이미지 처리
        final imageCount = pageImages.length;
        safePrint('[PDF처리] Step 2: 각 열 이미지 OCR+AI 파싱 시작');
        safePrint('[PDF처리] ★ BIG_144: 총 $imageCount개 열 이미지 처리');
        for (int i = 0; i < imageCount; i++) {
          _currentChunk = i + 1;
          setState(() {
            _analysisStatus = '페이지 ${i + 1}/${pageImages.length} OCR+AI 분석 중...';
          });

          safePrint('[PDF처리] ====== PDF 페이지 ${i + 1}/${pageImages.length} ======');
          final pageStopwatch = Stopwatch()..start();

          try {
            // BIG_140: 열 분리/병합 제거, 이미지 그대로 OCR+AI
            safePrint('[PDF처리] 페이지 ${i + 1}: extractAnswers() 호출');
            final parsedPages = await _answerParser.extractAnswers(pageImages[i]);
            pageStopwatch.stop();
            
            safePrint('[PDF처리] 페이지 ${i + 1}: extractAnswers() 완료, ${pageStopwatch.elapsedMilliseconds}ms');
            safePrint('[PDF처리] 페이지 ${i + 1}: ${parsedPages.length}개 교재 페이지 인식');
            
            // 각 인식된 페이지 상세 로그
            for (int j = 0; j < parsedPages.length; j++) {
              final p = parsedPages[j];
              safePrint('[PDF처리] 페이지 ${i + 1} → 교재 p.${p.pageNumber}');
              safePrint('[PDF처리]   - sections: ${p.sections.keys.toList()}');
              safePrint('[PDF처리]   - content 길이: ${p.rawContent.length}자');
              if (p.rawContent.length > 100) {
                safePrint('[PDF처리]   - content 앞 100자: ${p.rawContent.substring(0, 100)}...');
              } else {
                safePrint('[PDF처리]   - content: ${p.rawContent}');
              }
            }
            
            final pageResults = parsedPages.map((p) => p.toMap()).toList();
            allExtractedPages.addAll(pageResults);

          } catch (e, stack) {
            safePrint('[PDF처리] 페이지 ${i + 1} 처리 실패: $e');
            safePrint('[PDF처리] 스택트레이스: $stack');
          }

          // Rate limit 대기 (OCR+AI 사이)
          if (i < pageImages.length - 1) {
            safePrint('[PDF처리] 다음 페이지 전 1초 대기...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }

        // 3. 이미지 파일들 정리
        // ★ BIG_143 테스트: cleanup 비활성화 (이미지 확인용)
        safePrint('[PDF처리] Step 3: ★★★ cleanup 비활성화 ★★★');
        safePrint('[PDF처리] 이미지 위치: DCIM/flutter_1/');
        // await PdfToImageService.cleanupImages(pageImages);
        // safePrint('[PDF처리] 임시 파일 정리 완료');

        setState(() => _isAnalyzing = false);

        // 4. 결과 처리
        safePrint('[PDF처리] Step 4: 결과 정리');
        safePrint('[PDF처리] 총 추출 결과: ${allExtractedPages.length}개 교재 페이지');
        
        if (allExtractedPages.isNotEmpty) {
          // 페이지 번호 순 정렬
          allExtractedPages.sort((a, b) {
            final aPage = a['pageNumber'] as int? ?? 0;
            final bPage = b['pageNumber'] as int? ?? 0;
            return aPage.compareTo(bPage);
          });

          // 정렬 후 페이지 번호 목록 로그
          final pageNumbers = allExtractedPages.map((p) => p['pageNumber']).toList();
          safePrint('[PDF처리] 정렬 후 페이지 번호: $pageNumbers');
          
          // 중복 체크
          final uniquePages = pageNumbers.toSet();
          if (uniquePages.length != pageNumbers.length) {
            safePrint('[PDF처리] ⚠️ 중복 페이지 발견! 원본: ${pageNumbers.length}개, 고유: ${uniquePages.length}개');
          }

          final proceed = await _showExtractedTextDialog(allExtractedPages);

          if (proceed == true) {
            final pages = <int>[];
            final answerContents = <int, String>{};

            for (final p in allExtractedPages) {
              final pageNum = p['pageNumber'] as int?;
              final content = p['content'] as String? ?? '';
              if (pageNum != null) {
                pages.add(pageNum);
                if (content.isNotEmpty) {
                  answerContents[pageNum] = content;
                }
              }
            }
            pages.sort();

            safePrint('[PDF처리] 저장할 페이지: $pages');
            safePrint('[PDF처리] 저장할 정답 내용: ${answerContents.length}개');

            if (pages.isNotEmpty) {
              await _validateAndSavePagesWithAnswers(pages, answerContents);
            }
          } else {
            safePrint('[PDF처리] 사용자가 취소함');
          }
        } else {
          safePrint('[PDF처리] ❌ 추출 결과 없음!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('페이지를 인식하지 못했습니다')),
            );
          }
        }
        
        safePrint('[PDF처리] ========================================');
        safePrint('[PDF처리] PDF 처리 완료');
        safePrint('[PDF처리] ========================================');
      }
    } catch (e, stack) {
      safePrint('[PDF처리] ❌ PDF 처리 실패: $e');
      safePrint('[PDF처리] 스택트레이스: $stack');
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 처리 실패: $e')),
        );
      }
    }
  }

  /// 목차 데이터 준비 (endPage 자동 계산)
  List<Map<String, dynamic>> _prepareTocEntries() {
    final rawToc = _book?.tableOfContents ?? [];
    final tocEntries = <Map<String, dynamic>>[];

    for (int i = 0; i < rawToc.length; i++) {
      final current = rawToc[i];
      final start = current.startPage;

      int end;
      if (current.endPage != null && current.endPage! > 0) {
        end = current.endPage!;
      } else if (i + 1 < rawToc.length) {
        end = rawToc[i + 1].startPage - 1;
      } else {
        end = _book?.totalPages ?? (start + 50);
      }

      tocEntries.add({
        'unitName': current.unitName,
        'startPage': start,
        'endPage': end,
      });
    }

    return tocEntries;
  }

  /// 청크 처리 with 재시도
  Future<List<Map<String, dynamic>>> _processChunkWithRetry(File chunk, {int maxRetries = 3}) async {
    // 목차 데이터 준비 (endPage 자동 계산)
    final rawToc = _book?.tableOfContents ?? [];
    final tocEntries = <Map<String, dynamic>>[];
    
    for (int i = 0; i < rawToc.length; i++) {
      final current = rawToc[i];
      final start = current.startPage;
      
      // endPage 계산: 명시적으로 있으면 사용, 없으면 다음 Unit의 startPage - 1
      int end;
      if (current.endPage != null && current.endPage! > 0) {
        end = current.endPage!;
      } else if (i + 1 < rawToc.length) {
        // 다음 Unit의 startPage - 1
        end = rawToc[i + 1].startPage - 1;
      } else {
        // 마지막 Unit이면 책의 totalPages 사용, 없으면 startPage + 50 (여유있게)
        end = _book?.totalPages ?? (start + 50);
      }
      
      tocEntries.add({
        'unitName': current.unitName,
        'startPage': start,
        'endPage': end,
      });
      
      safePrint('[AnswerCamera] 목차[$i]: ${current.unitName} → p.$start~$end');
    }

    safePrint('[AnswerCamera] 목차 ${tocEntries.length}개 항목으로 교차 검증 시작');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // 목차가 있으면 새 메서드 사용, 없으면 기존 메서드
        if (tocEntries.isNotEmpty) {
          return await _claudeService.extractPdfWithTocValidation(chunk, tocEntries);
        } else {
          safePrint('[AnswerCamera] 목차 없음 - 기존 방식 사용');
          return await _claudeService.extractPdfChunkText(chunk);
        }
      } catch (e) {
        final errorStr = e.toString();
        safePrint('[AnswerCamera] 청크 처리 실패 (시도 $attempt): $e');

        if (errorStr.contains('RATE_LIMIT') && attempt < maxRetries) {
          // Rate limit - 더 긴 딜레이 후 재시도
          final delaySeconds = attempt * 5;
          setState(() => _analysisStatus = 'API 제한 대기 중... (${delaySeconds}초)');
          await Future.delayed(Duration(seconds: delaySeconds));
          continue;
        }

        if (attempt == maxRetries) {
          return [];  // 최대 재시도 후 빈 결과 반환
        }
      }
    }
    return [];
  }

  /// 추출된 텍스트 확인 다이얼로그
  Future<bool?> _showExtractedTextDialog(List<Map<String, dynamic>> pages) async {
    // ★ BIG_115 디버그 로그 추가
    safePrint('[DEBUG] _showExtractedTextDialog 호출');
    safePrint('[DEBUG] pages.length: ${pages.length}');
    for (int i = 0; i < pages.length && i < 3; i++) {
      safePrint('[DEBUG] pages[$i]: ${pages[i]}');
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.fact_check, color: Colors.teal),
            const SizedBox(width: 8),
            Text('인식 결과 확인 (${pages.length}페이지)'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView.builder(
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              final pageNum = page['pageNumber'];
              final content = page['content'] as String? ?? '';

              // ★ BIG_115 디버그 로그 - 인덱스와 페이지 번호 비교
              if (index < 3) {
                safePrint('[DEBUG] ListView index=$index, pageNumber=$pageNum');
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 페이지 번호 헤더
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Page $pageNum',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 인식된 내용
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          content,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('정확함 - 저장'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
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

  /// 정답 내용과 함께 페이지 검증 후 저장
  Future<void> _validateAndSavePagesWithAnswers(List<int> pages, Map<int, String> answerContents) async {
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
    
    safePrint('[AnswerCamera] 인식된 페이지: $pages, 정답 내용: ${answerContents.length}개');
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
                      const Text('📚 등록된 책 페이지 범위',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      const SizedBox(height: 8),
                      Text(_getVolumeRangeInfo(), style: const TextStyle(fontSize: 13, height: 1.5)),
                      Text('총 ${book.totalPages}페이지', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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

    await _savePagesWithAnswers(pages, answerContents);
  }

  /// 정답 내용과 함께 저장
  Future<void> _savePagesWithAnswers(List<int> pages, Map<int, String> answerContents) async {
    try {
      safePrint('[AnswerCamera] 정답 내용 포함 저장: ${pages.length}페이지, ${answerContents.length}개 내용');
      
      await _repository.updatePagesWithAnswers(widget.bookId, pages, answerContents);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pages.length}페이지 + ${answerContents.length}개 정답 내용 등록 완료'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      safePrint('[AnswerCamera] 정답 내용 저장 실패: $e');
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
          if (_totalChunks > 0)
            Column(
              children: [
                // 프로그레스 바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: LinearProgressIndicator(
                    value: _currentChunk / _totalChunks,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '청크 $_currentChunk / $_totalChunks',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
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

            // 갤러리 선택 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library, size: 24),
                label: const Text('갤러리에서 선택', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
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

  /// 이미지 바이트에서 해상도 추출
  Future<ui.Image> decodeImageFromList(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
