import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../shared/services/claude_api_service.dart';
import 'book_camera_page.dart';

// ============================================================
// DB 클래스들
// ============================================================

class TextbookDB {
  final String title;
  final Map<int, PageAnswerDB> pages;
  TextbookDB({required this.title, required this.pages});
}

class PageAnswerDB {
  final int page;
  final String unit;
  final String title;
  final Map<String, Map<int, String>> answers;
  
  PageAnswerDB({
    required this.page,
    required this.unit,
    required this.title,
    required this.answers,
  });
  
  String? getAnswer(String section, int number) => answers[section]?[number];
  
  int get totalProblems {
    int count = 0;
    for (final section in answers.values) {
      count += section.length;
    }
    return count;
  }
}

class ProcessedPage {
  final int pageNumber;
  final File imageFile;
  final Map<String, dynamic>? sectionBounds;
  
  ProcessedPage({
    required this.pageNumber, 
    required this.imageFile,
    this.sectionBounds,
  });
}

class ExtractedProblem {
  final String section;
  final int number;
  final double yStart;
  final double yEnd;
  final String? answer;
  final File? imageFile;
  final bool ocrFound;  // OCR로 찾았는지 여부
  
  ExtractedProblem({
    required this.section,
    required this.number,
    required this.yStart,
    required this.yEnd,
    this.answer,
    this.imageFile,
    this.ocrFound = true,
  });
  
  String get displayName => '$section.$number';
}

// ============================================================
// DB 데이터
// ============================================================

final grammarEffect2 = TextbookDB(
  title: 'Grammar Effect 2',
  pages: {
    9: PageAnswerDB(
      page: 9,
      unit: 'Unit 01',
      title: '문장을 이루는 요소',
      answers: {
        'A': {1: '목적어', 2: '동사', 3: '수식어', 4: '보어'},
        'B': {1: 'wrote', 2: 'My teacher', 3: 'great', 4: 'dinner'},
        'C': {1: '주어, 동사, 보어', 2: '주어, 동사, 목적어, 수식어', 3: '주어, 동사, 보어', 4: '주어, 동사, 목적어, 수식어'},
        'D': {1: 'Tom and I go to the same school.', 2: 'She was writing in a diary.', 3: 'It is very surprising news.', 4: 'We saw that movie at the theater.'},
      },
    ),
    11: PageAnswerDB(
      page: 11,
      unit: 'Unit 02',
      title: '1형식, 2형식',
      answers: {
        'A': {1: 'angry', 2: 'an artist', 3: 'X', 4: 'fantastic'},
        'B': {1: 'well', 2: 'happy', 3: 'sweet', 4: 'dark'},
        'C': {1: 'bad', 2: 'perfect', 3: 'nice', 4: 'rich'},
        'D': {1: 'fur coat looks expensive', 2: 'The beef stew smells delicious', 3: 'Your idea sounds very good', 4: 'the tomato soup taste spicy'},
      },
    ),
  },
);

// ============================================================
// 메인 페이지
// ============================================================

class OcrTestPage extends StatefulWidget {
  const OcrTestPage({super.key});
  @override
  State<OcrTestPage> createState() => _OcrTestPageState();
}

class _OcrTestPageState extends State<OcrTestPage> {
  final _claudeService = ClaudeApiService();

  File? _selectedFile;
  bool _isLoading = false;
  String _status = '';
  String? _error;

  int _step = 0;
  int _rotation = 0;
  int _pageCount = 1;
  List<ProcessedPage> _pages = [];
  Map<int, PageAnswerDB?> _matchedDBs = {};
  Map<int, List<ExtractedProblem>> _extractedProblems = {};

  TextbookDB get _db => grammarEffect2;

  // ============================================================
  // 카메라 촬영
  // ============================================================
  
  Future<void> _openCamera() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const BookCameraPage()),
    );

    if (result != null) {
      final pageMode = result['pageMode'] as int? ?? 1;
      final pages = (result['pages'] as List<dynamic>?)?.cast<int>() ?? [];
      final individualImages = result['individualImages'] as List<File>?;

      if (individualImages != null && individualImages.isNotEmpty) {
        setState(() {
          _selectedFile = individualImages.first;
          _pageCount = pageMode;
          _rotation = 0;
          _step = 0;
          _pages = [];
          _matchedDBs = {};
          _extractedProblems = {};
          _error = null;
        });

        if (pages.isNotEmpty && pages.any((p) => p > 0)) {
          await _processFromScanner(individualImages, pages);
        } else {
          await _runStep1();
        }
      }
    }
  }

  // ============================================================
  // 스캐너 결과 처리
  // ============================================================
  
  Future<void> _processFromScanner(List<File> images, List<int> detectedPages) async {
    setState(() {
      _isLoading = true;
      _step = 2;
      _status = '📄 페이지 처리 중...';
    });

    try {
      final tempDir = await getTemporaryDirectory();
      _pages = [];

      for (int i = 0; i < images.length; i++) {
        final pageNum = i < detectedPages.length ? detectedPages[i] : 0;
        
        final bytes = await images[i].readAsBytes();
        final newFile = File('${tempDir.path}/page_$i.png');
        await newFile.writeAsBytes(bytes);
        
        setState(() => _status = '🔢 페이지 ${i + 1} 분석 중...');
        final result = await _claudeService.analyzePageComplete(newFile);
        
        final actualPageNum = result?['pageNumber'] as int? ?? pageNum;
        final sectionBounds = result?['sectionBounds'] as Map<String, dynamic>?;
        
        safePrint('[Scanner] 페이지 ${i + 1}: p.$actualPageNum, 섹션: ${sectionBounds?.keys.toList()}');
        
        _pages.add(ProcessedPage(
          pageNumber: actualPageNum,
          imageFile: newFile,
          sectionBounds: sectionBounds,
        ));
      }

      setState(() {
        _step = 4;
        _status = '📚 DB 매칭 중...';
      });

      _matchedDBs = {};
      for (final page in _pages) {
        _matchedDBs[page.pageNumber] = _db.pages[page.pageNumber];
      }

      setState(() {
        _step = 5;
        _isLoading = false;
        _status = '';
      });

    } catch (e) {
      safePrint('[Scanner] 오류: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // 갤러리에서 선택
  // ============================================================
  
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _step = 0;
        _rotation = 0;
        _pageCount = 1;
        _pages = [];
        _matchedDBs = {};
        _extractedProblems = {};
        _error = null;
      });

      await _runStep1();
    }
  }

  // ============================================================
  // Step 1: 회전 감지
  // ============================================================
  
  Future<void> _runStep1() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _step = 1;
      _status = '📐 회전 감지 중...';
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception('이미지 로드 실패');
      
      final tempDir = await getTemporaryDirectory();
      int bestRotation = 0;
      int bestScore = 0;
      
      for (final rotation in [0, 90, 180, 270]) {
        setState(() => _status = '📐 회전 $rotation° 테스트 중...');
        
        var testImage = originalImage;
        if (rotation != 0) {
          testImage = img.copyRotate(originalImage, angle: rotation.toDouble());
        }
        
        final testFile = File('${tempDir.path}/test_$rotation.jpg');
        await testFile.writeAsBytes(img.encodeJpg(testImage, quality: 70));
        
        final score = await _claudeService.checkTextReadability(testFile);
        safePrint('[Step1] 회전 $rotation° 점수: $score');
        
        if (score > bestScore) {
          bestScore = score;
          bestRotation = rotation;
        }
        
        if (score >= 90) break;
      }
      
      _rotation = bestRotation;
      
      var rotatedImage = originalImage;
      if (_rotation != 0) {
        rotatedImage = img.copyRotate(originalImage, angle: _rotation.toDouble());
      }
      
      _pageCount = rotatedImage.width > rotatedImage.height * 1.3 ? 2 : 1;

      setState(() {
        _isLoading = false;
        _status = '';
      });
      
      await _runStep2ToEnd();
      
    } catch (e) {
      safePrint('[Step1] 오류: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // Step 2~4: 페이지 분리 → AI 분석 → DB 매칭
  // ============================================================
  
  Future<void> _runStep2ToEnd() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      setState(() {
        _step = 2;
        _status = '🔄 페이지 분리 중...';
      });
      
      final bytes = await _selectedFile!.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) throw Exception('이미지 로드 실패');

      if (_rotation != 0) {
        image = img.copyRotate(image, angle: _rotation.toDouble());
      }

      final tempDir = await getTemporaryDirectory();
      final pageImages = <File>[];

      if (_pageCount == 2) {
        final isVertical = image.height > image.width;
        
        if (isVertical) {
          final halfHeight = image.height ~/ 2;
          final margin = (image.height * 0.05).round();
          
          final topImage = img.copyCrop(image, x: 0, y: 0, 
              width: image.width, height: (halfHeight + margin).clamp(0, image.height));
          final bottomStart = (halfHeight - margin).clamp(0, image.height - 1);
          final bottomImage = img.copyCrop(image, x: 0, y: bottomStart, 
              width: image.width, height: image.height - bottomStart);
          
          final topFile = File('${tempDir.path}/page_top.png');
          final bottomFile = File('${tempDir.path}/page_bottom.png');
          await topFile.writeAsBytes(img.encodePng(topImage));
          await bottomFile.writeAsBytes(img.encodePng(bottomImage));
          
          pageImages.add(topFile);
          pageImages.add(bottomFile);
        } else {
          final halfWidth = image.width ~/ 2;
          final margin = (image.width * 0.03).round();
          
          final leftImage = img.copyCrop(image, x: 0, y: 0, 
              width: (halfWidth + margin).clamp(0, image.width), height: image.height);
          final rightStart = (halfWidth - margin).clamp(0, image.width - 1);
          final rightImage = img.copyCrop(image, x: rightStart, y: 0, 
              width: image.width - rightStart, height: image.height);
          
          final leftFile = File('${tempDir.path}/page_left.png');
          final rightFile = File('${tempDir.path}/page_right.png');
          await leftFile.writeAsBytes(img.encodePng(leftImage));
          await rightFile.writeAsBytes(img.encodePng(rightImage));
          
          pageImages.add(leftFile);
          pageImages.add(rightFile);
        }
      } else {
        final file = File('${tempDir.path}/page_single.png');
        await file.writeAsBytes(img.encodePng(image));
        pageImages.add(file);
      }

      // Step 3: AI 분석
      setState(() {
        _step = 3;
        _status = '🔢 페이지 분석 중...';
      });

      _pages = [];
      for (int i = 0; i < pageImages.length; i++) {
        setState(() => _status = '🔢 페이지 ${i + 1}/${pageImages.length} 분석 중...');
        
        final result = await _claudeService.analyzePageComplete(pageImages[i]);
        
        final pageNum = result?['pageNumber'] as int? ?? 0;
        final sectionBounds = result?['sectionBounds'] as Map<String, dynamic>?;
        
        safePrint('[Step3] 페이지 ${i + 1} → p.$pageNum, 섹션: ${sectionBounds?.keys.toList()}');
        
        _pages.add(ProcessedPage(
          pageNumber: pageNum,
          imageFile: pageImages[i],
          sectionBounds: sectionBounds,
        ));
      }

      // Step 4: DB 매칭
      setState(() {
        _step = 4;
        _status = '📚 DB 매칭 중...';
      });

      _matchedDBs = {};
      for (final page in _pages) {
        _matchedDBs[page.pageNumber] = _db.pages[page.pageNumber];
      }

      setState(() {
        _step = 5;
        _isLoading = false;
        _status = '';
      });

    } catch (e) {
      safePrint('[Step2-4] 오류: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // Step 5: 문제 추출 (섹션 분할 → OCR → crop)
  // ============================================================
  
  Future<void> _runExtraction() async {
    setState(() {
      _isLoading = true;
      _extractedProblems = {};
    });

    try {
      final tempDir = await getTemporaryDirectory();
      
      for (final page in _pages) {
        final pageDB = _matchedDBs[page.pageNumber];
        if (pageDB == null) continue;
        
        final sectionBounds = page.sectionBounds;
        if (sectionBounds == null) {
          safePrint('[Extract] p.${page.pageNumber} sectionBounds 없음');
          continue;
        }
        
        final bytes = await page.imageFile.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image == null) continue;
        
        final problems = <ExtractedProblem>[];
        
        for (final sectionName in sectionBounds.keys) {
          final bounds = sectionBounds[sectionName] as Map<String, dynamic>?;
          if (bounds == null) continue;
          
          setState(() => _status = '✂️ p.${page.pageNumber} Section $sectionName...');
          
          // 1. 섹션 영역 crop
          final xStart = ((bounds['xStart'] as num?)?.toDouble() ?? 0) / 100 * image.width;
          final xEnd = ((bounds['xEnd'] as num?)?.toDouble() ?? 100) / 100 * image.width;
          final yStart = ((bounds['yStart'] as num?)?.toDouble() ?? 0) / 100 * image.height;
          final yEnd = ((bounds['yEnd'] as num?)?.toDouble() ?? 100) / 100 * image.height;
          
          final sectionWidth = (xEnd - xStart).round().clamp(1, image.width);
          final sectionHeight = (yEnd - yStart).round().clamp(1, image.height);
          
          final sectionImg = img.copyCrop(
            image,
            x: xStart.round().clamp(0, image.width - 1),
            y: yStart.round().clamp(0, image.height - 1),
            width: sectionWidth,
            height: sectionHeight,
          );
          
          final sectionFile = File('${tempDir.path}/p${page.pageNumber}_section_$sectionName.png');
          await sectionFile.writeAsBytes(img.encodePng(sectionImg));
          
          safePrint('[Extract] Section $sectionName crop: ${sectionWidth}x$sectionHeight');
          
          // 2. DB에서 문제 개수 확인
          final sectionAnswers = pageDB.answers[sectionName];
          if (sectionAnswers == null) continue;
          
          final expectedCount = sectionAnswers.length;
          
          // 3. OCR로 문제 번호 위치 찾기
          final ocrPositions = await _findProblemNumbersWithOCR(
            sectionFile, expectedCount, sectionName,
          );
          
          safePrint('[Extract] Section $sectionName: OCR ${ocrPositions.length}/$expectedCount 발견');
          
          // 4. 각 문제별로 crop (찾은 것만!)
          for (int i = 0; i < ocrPositions.length; i++) {
            final pos = ocrPositions[i];
            final number = pos['number'] as int;
            final yPx = pos['y'] as int;
            
            // 다음 문제까지 영역
            int yEndPx;
            if (i < ocrPositions.length - 1) {
              yEndPx = ocrPositions[i + 1]['y'] as int;
            } else {
              yEndPx = sectionImg.height;
            }
            
            // 마진
            final marginTop = (sectionImg.height * 0.01).round();
            final marginBottom = (sectionImg.height * 0.02).round();
            
            final cropY = (yPx - marginTop).clamp(0, sectionImg.height - 1);
            final cropYEnd = (yEndPx + marginBottom).clamp(cropY + 1, sectionImg.height);
            
            final problemImg = img.copyCrop(
              sectionImg,
              x: 0,
              y: cropY,
              width: sectionImg.width,
              height: cropYEnd - cropY,
            );
            
            final problemFile = File('${tempDir.path}/p${page.pageNumber}_${sectionName}_$number.png');
            await problemFile.writeAsBytes(img.encodePng(problemImg));
            
            // % 변환
            final globalYStart = yStart + cropY;
            final globalYEnd = yStart + cropYEnd;
            final yStartPercent = globalYStart / image.height * 100;
            final yEndPercent = globalYEnd / image.height * 100;
            
            problems.add(ExtractedProblem(
              section: sectionName,
              number: number,
              yStart: yStartPercent,
              yEnd: yEndPercent,
              answer: pageDB.getAnswer(sectionName, number),
              imageFile: problemFile,
              ocrFound: true,
            ));
          }
          
          // 5. 못 찾은 문제 표시
          for (int num = 1; num <= expectedCount; num++) {
            final found = ocrPositions.any((p) => p['number'] == num);
            if (!found) {
              problems.add(ExtractedProblem(
                section: sectionName,
                number: num,
                yStart: 0,
                yEnd: 0,
                answer: pageDB.getAnswer(sectionName, num),
                imageFile: null,
                ocrFound: false,  // ⚠️ 미감지
              ));
            }
          }
        }
        
        // 정렬
        problems.sort((a, b) {
          final sectionCmp = a.section.compareTo(b.section);
          if (sectionCmp != 0) return sectionCmp;
          return a.number.compareTo(b.number);
        });
        
        _extractedProblems[page.pageNumber] = problems;
        safePrint('[Extract] p.${page.pageNumber}: ${problems.length}개 완료');
      }

      setState(() {
        _isLoading = false;
        _status = '';
      });

    } catch (e) {
      safePrint('[Extract] 오류: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // OCR로 문제 번호 위치 찾기 (찾은 것만 반환!)
  // ============================================================
  
  Future<List<Map<String, int>>> _findProblemNumbersWithOCR(
    File sectionImage,
    int expectedCount,
    String sectionName,
  ) async {
    try {
      final inputImage = InputImage.fromFile(sectionImage);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();
      
      final foundPositions = <Map<String, int>>[];
      final targetNumbers = List.generate(expectedCount, (i) => i + 1);
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final text = line.text.trim();
          
          for (final targetNum in targetNumbers) {
            // 이미 찾았으면 스킵
            if (foundPositions.any((p) => p['number'] == targetNum)) continue;
            
            // 패턴 매칭: "1", "1.", "1 xxx", "1. xxx"
            final isMatch = text == '$targetNum' ||
                text == '$targetNum.' ||
                text.startsWith('$targetNum ') ||
                text.startsWith('$targetNum. ') ||
                RegExp('^$targetNum\\s').hasMatch(text) ||
                RegExp('^$targetNum\\.\\s').hasMatch(text);
            
            if (isMatch) {
              final boundingBox = line.boundingBox;
              if (boundingBox != null) {
                foundPositions.add({
                  'number': targetNum,
                  'y': boundingBox.top.round(),
                });
                safePrint('[OCR] $sectionName: $targetNum 발견 "$text" y=${boundingBox.top.round()}');
              }
              break;
            }
          }
        }
      }
      
      // Y 좌표 순으로 정렬
      foundPositions.sort((a, b) => a['y']!.compareTo(b['y']!));
      
      return foundPositions;
      
    } catch (e) {
      safePrint('[OCR] 오류: $e');
      return [];
    }
  }

  // ============================================================
  // UI
  // ============================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 자동 문제 추출 v2'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPipelineStatus(),
            const SizedBox(height: 16),
            _buildCaptureCard(),
            if (_isLoading) _buildLoadingCard(),
            if (_error != null) _buildErrorCard(),
            if (_pages.isNotEmpty && !_isLoading) ...[
              const SizedBox(height: 16),
              const Text('📄 인식된 페이지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ..._pages.map(_buildPageCard),
            ],
            if (_matchedDBs.values.any((db) => db != null) && !_isLoading && _extractedProblems.isEmpty) ...[
              const SizedBox(height: 16),
              _buildExtractButton(),
            ],
            if (_extractedProblems.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._buildExtractionResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineStatus() {
    final steps = [
      ('Step 1: 회전 감지', _rotation != 0 ? ' → $_rotation°' : ''),
      ('Step 2: 페이지 분리', _pages.isNotEmpty ? ' → ${_pages.length}개' : ''),
      ('Step 3: AI 분석', ''),
      ('Step 4: DB 매칭', ''),
      ('Step 5: 문제 추출', ''),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔄 파이프라인', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((e) {
              final i = e.key;
              final (step, suffix) = e.value;
              final isComplete = _step > i + 1;
              final isCurrent = _step == i + 1;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : (isCurrent ? Icons.play_circle : Icons.circle_outlined),
                      color: isComplete ? Colors.green : (isCurrent ? Colors.blue : Colors.grey),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(step, style: TextStyle(
                      color: isComplete ? Colors.green.shade700 : (isCurrent ? Colors.blue : Colors.grey),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    )),
                    if (suffix.isNotEmpty)
                      Text(suffix, style: TextStyle(color: Colors.green.shade600, fontSize: 11)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📷 책 페이지 촬영', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_selectedFile != null) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(_selectedFile!, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _openCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('카메라'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickFile,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('갤러리'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 16),
            Expanded(child: Text(_status)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildPageCard(ProcessedPage page) {
    final db = _matchedDBs[page.pageNumber];
    final isMatched = db != null;
    
    return Card(
      color: isMatched ? Colors.green.shade50 : Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(page.imageFile, height: 60, width: 45, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('p.${page.pageNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMatched ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMatched ? '✓ DB' : '✗',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  if (isMatched)
                    Text('${db.unit}: ${db.title}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: _runExtraction,
          icon: const Icon(Icons.content_cut),
          label: const Text('Step 5: 문제 추출하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExtractionResults() {
    final widgets = <Widget>[];
    
    widgets.add(const Text('✂️ 추출된 문제', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));
    
    for (final entry in _extractedProblems.entries) {
      final pageNum = entry.key;
      final problems = entry.value;
      final pageDB = _matchedDBs[pageNum];
      
      if (problems.isEmpty) continue;

      widgets.add(const SizedBox(height: 8));
      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.teal.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('📄 p.$pageNum - ${pageDB?.unit ?? ""}: ${pageDB?.title ?? ""}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      );
      
      // 섹션별 그룹화
      final sectionGroups = <String, List<ExtractedProblem>>{};
      for (final p in problems) {
        sectionGroups.putIfAbsent(p.section, () => []).add(p);
      }
      
      for (final sectionEntry in sectionGroups.entries) {
        final sectionName = sectionEntry.key;
        final sectionProblems = sectionEntry.value;
        final foundCount = sectionProblems.where((p) => p.ocrFound).length;
        final totalCount = sectionProblems.length;
        
        widgets.add(const SizedBox(height: 8));
        widgets.add(Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Section $sectionName',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text('$foundCount/$totalCount 감지',
                        style: TextStyle(
                          fontSize: 11,
                          color: foundCount == totalCount ? Colors.green : Colors.orange,
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ...sectionProblems.map((problem) {
                  if (!problem.ocrFound) {
                    // ⚠️ 미감지
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Text('${problem.displayName} 미감지',
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('정답: ${problem.answer ?? "?"}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }
                  
                  // 정상 감지
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: Colors.grey.shade100,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(problem.displayName,
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Text('정답: ${problem.answer ?? "?"}',
                                  style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                              const Spacer(),
                              Text('${problem.yStart.toInt()}%~${problem.yEnd.toInt()}%',
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        if (problem.imageFile != null)
                          Image.file(problem.imageFile!, fit: BoxFit.contain),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ));
      }
    }
    
    return widgets;
  }
}
