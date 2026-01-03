# BIG_133: PDF 열 분리 + 세로 병합 방식으로 전환

> 생성일: 2026-01-03
> 목표: 2페이지 펼침 PDF를 열별 크롭 → 세로 병합 → 1열 이미지로 정답 추출

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

- [x] 로컬 코드 확인했나? → answer_camera_page.dart, claude_api_service.dart 확인 완료
- [x] 수정할 파일/줄 번호 특정했나? → 아래 상세 기술
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?** → 각 단계마다 로그 필수

---

## 🎯 문제 상황

### 현재 문제
```
PDF 1페이지 = 교재 2페이지 펼침 스캔
[왼쪽 페이지 | 오른쪽 페이지]
     ↓
API가 복잡한 2열 구조 직접 읽기 → 누락/오인식 많음
17페이지 중 10페이지만 인식 (41% 누락)
```

### 해결 방안
```
Step 1: PDF 페이지 → 이미지 변환
Step 2: 열 개수 감지 (1열 / 2열 / 4열)
Step 3: 열별 크롭 → [왼쪽 이미지, 오른쪽 이미지]
Step 4: 세로 병합 → 긴 1열 이미지
Step 5: 1열 이미지로 정답 추출 (AI가 단순하게 읽기 가능)
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 새 파일:
  - `lib/shared/services/pdf_to_image_service.dart`
  - `lib/shared/services/image_processor_service.dart`
- 수정 파일:
  - `lib/shared/services/claude_api_service.dart`
  - `lib/features/my_books/pages/answer_camera_page.dart`

---

## 스몰스텝

### 1. PDF → 이미지 변환 서비스 생성

**파일**: `lib/shared/services/pdf_to_image_service.dart`

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// PDF를 이미지로 변환하는 서비스
class PdfToImageService {
  
  /// PDF 파일의 각 페이지를 이미지로 변환
  /// 반환: List<File> - 각 페이지의 PNG 이미지 파일들
  static Future<List<File>> convertPdfToImages(File pdfFile) async {
    debugPrint('[PdfToImage] PDF → 이미지 변환 시작: ${pdfFile.path}');
    
    final images = <File>[];
    final tempDir = await getTemporaryDirectory();
    
    try {
      final bytes = await pdfFile.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      
      debugPrint('[PdfToImage] 총 $pageCount 페이지');
      
      for (int i = 0; i < pageCount; i++) {
        debugPrint('[PdfToImage] 페이지 ${i + 1}/$pageCount 변환 중...');
        
        // Syncfusion PDF에서 이미지 추출
        // 주의: Syncfusion Flutter PDF는 직접 이미지 렌더링 미지원
        // pdfviewer의 extractImage 또는 다른 방법 필요
        
        // TODO: 실제 이미지 추출 구현
        // 방법 1: syncfusion_flutter_pdfviewer 사용
        // 방법 2: pdf_render 패키지 사용
        // 방법 3: native code (platform channel)
        
        final imagePath = '${tempDir.path}/pdf_page_${i + 1}.png';
        // await _renderPageToImage(document.pages[i], imagePath);
        
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          images.add(imageFile);
        }
      }
      
      document.dispose();
      debugPrint('[PdfToImage] 변환 완료: ${images.length}개 이미지');
      
    } catch (e) {
      debugPrint('[PdfToImage] 변환 실패: $e');
      rethrow;
    }
    
    return images;
  }
  
  /// 임시 이미지 파일들 정리
  static Future<void> cleanupImages(List<File> images) async {
    for (final image in images) {
      try {
        if (await image.exists()) {
          await image.delete();
          debugPrint('[PdfToImage] 이미지 삭제: ${image.path}');
        }
      } catch (e) {
        debugPrint('[PdfToImage] 이미지 삭제 실패: $e');
      }
    }
  }
}
```

**⚠️ 중요**: Syncfusion Flutter PDF는 PDF → 이미지 렌더링을 직접 지원하지 않음!
- `pdf_render` 패키지 사용 권장: `pdf_render: ^1.4.12`
- 또는 `pdfx` 패키지: `pdfx: ^2.6.0`

**pubspec.yaml에 추가**:
```yaml
dependencies:
  pdfx: ^2.6.0  # PDF 이미지 렌더링용
```

**pdf_render 또는 pdfx 사용 버전**:
```dart
import 'package:pdfx/pdfx.dart';

static Future<List<File>> convertPdfToImages(File pdfFile) async {
  debugPrint('[PdfToImage] PDF → 이미지 변환 시작');
  
  final images = <File>[];
  final tempDir = await getTemporaryDirectory();
  
  final document = await PdfDocument.openFile(pdfFile.path);
  final pageCount = document.pagesCount;
  
  debugPrint('[PdfToImage] 총 $pageCount 페이지');
  
  for (int i = 1; i <= pageCount; i++) {
    debugPrint('[PdfToImage] 페이지 $i/$pageCount 변환 중...');
    
    final page = await document.getPage(i);
    final pageImage = await page.render(
      width: page.width * 2,  // 2배 해상도
      height: page.height * 2,
    );
    
    final imagePath = '${tempDir.path}/pdf_page_$i.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(pageImage!.bytes);
    
    images.add(imageFile);
    await page.close();
  }
  
  await document.close();
  debugPrint('[PdfToImage] 변환 완료: ${images.length}개 이미지');
  
  return images;
}
```

- [ ] `pdfx: ^2.6.0` pubspec.yaml에 추가
- [ ] `flutter pub get` 실행
- [ ] pdf_to_image_service.dart 생성

---

### 2. 이미지 크롭/병합 서비스 생성

**파일**: `lib/shared/services/image_processor_service.dart`

```dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// 이미지 크롭 및 병합 서비스
class ImageProcessorService {
  
  /// 이미지를 열 개수에 따라 세로로 분할
  /// columns: 1, 2, 4
  /// 반환: 왼쪽부터 순서대로 크롭된 이미지들
  static Future<List<File>> cropByColumns(File imageFile, int columns) async {
    debugPrint('[ImageProcessor] 열 분할 시작: $columns열');
    
    if (columns <= 1) {
      debugPrint('[ImageProcessor] 1열 - 분할 불필요');
      return [imageFile];
    }
    
    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    
    if (original == null) {
      debugPrint('[ImageProcessor] 이미지 디코딩 실패');
      return [imageFile];
    }
    
    final width = original.width;
    final height = original.height;
    final columnWidth = width ~/ columns;
    
    debugPrint('[ImageProcessor] 원본: ${width}x$height, 열당 너비: $columnWidth');
    
    final tempDir = await getTemporaryDirectory();
    final croppedImages = <File>[];
    
    for (int i = 0; i < columns; i++) {
      final x = i * columnWidth;
      final cropped = img.copyCrop(
        original,
        x: x,
        y: 0,
        width: columnWidth,
        height: height,
      );
      
      final croppedPath = '${tempDir.path}/column_${i + 1}.png';
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodePng(cropped));
      
      croppedImages.add(croppedFile);
      debugPrint('[ImageProcessor] 열 ${i + 1} 크롭 완료: $croppedPath');
    }
    
    return croppedImages;
  }
  
  /// 여러 이미지를 세로로 병합
  /// 반환: 병합된 단일 이미지 파일
  static Future<File> mergeVertically(List<File> images) async {
    debugPrint('[ImageProcessor] 세로 병합 시작: ${images.length}개 이미지');
    
    if (images.isEmpty) {
      throw Exception('병합할 이미지가 없습니다');
    }
    
    if (images.length == 1) {
      debugPrint('[ImageProcessor] 1개 이미지 - 병합 불필요');
      return images.first;
    }
    
    // 모든 이미지 로드
    final loadedImages = <img.Image>[];
    int totalHeight = 0;
    int maxWidth = 0;
    
    for (final file in images) {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        loadedImages.add(decoded);
        totalHeight += decoded.height;
        if (decoded.width > maxWidth) {
          maxWidth = decoded.width;
        }
      }
    }
    
    debugPrint('[ImageProcessor] 병합 크기: ${maxWidth}x$totalHeight');
    
    // 새 캔버스 생성
    final merged = img.Image(width: maxWidth, height: totalHeight);
    
    // 흰색 배경
    img.fill(merged, color: img.ColorRgb8(255, 255, 255));
    
    // 이미지들 세로로 배치
    int currentY = 0;
    for (final image in loadedImages) {
      img.compositeImage(merged, image, dstX: 0, dstY: currentY);
      currentY += image.height;
    }
    
    // 파일로 저장
    final tempDir = await getTemporaryDirectory();
    final mergedPath = '${tempDir.path}/merged_${DateTime.now().millisecondsSinceEpoch}.png';
    final mergedFile = File(mergedPath);
    await mergedFile.writeAsBytes(img.encodePng(merged));
    
    debugPrint('[ImageProcessor] 병합 완료: $mergedPath');
    return mergedFile;
  }
  
  /// 임시 파일들 정리
  static Future<void> cleanup(List<File> files) async {
    for (final file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('[ImageProcessor] 파일 삭제 실패: $e');
      }
    }
  }
}
```

**pubspec.yaml에 추가**:
```yaml
dependencies:
  image: ^4.1.3  # 이미지 처리용
```

- [ ] `image: ^4.1.3` pubspec.yaml에 추가
- [ ] `flutter pub get` 실행
- [ ] image_processor_service.dart 생성

---

### 3. Claude API에 열 감지 + 이미지 기반 정답 추출 메서드 추가

**파일**: `lib/shared/services/claude_api_service.dart`

**추가할 메서드 2개**:

```dart
/// 이미지에서 열 개수 감지 (1, 2, 4)
Future<int> detectColumnCount(File imageFile) async {
  final apiKey = await _getApiKey();
  if (apiKey == null) {
    throw Exception('API 키가 설정되지 않았습니다');
  }

  final bytes = await imageFile.readAsBytes();
  final base64Data = base64Encode(bytes);
  
  final extension = imageFile.path.split('.').last.toLowerCase();
  final mediaType = switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'image/png',
  };

  try {
    debugPrint('[ClaudeAPI] 열 개수 감지 시작');
    
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _modelHaiku,  // 빠른 처리를 위해 Haiku 사용
        'max_tokens': 50,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Data,
                },
              },
              {
                'type': 'text',
                'text': '''이 이미지는 교재 정답지입니다.
정답이 몇 열로 배치되어 있나요?

- 1열: 정답이 세로로 한 줄
- 2열: 정답이 좌/우 2개 열 (2페이지 펼침)
- 4열: 정답이 4개 열 (2페이지 펼침 + 각 페이지 2열)

숫자만 답하세요: 1, 2, 또는 4''',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['content'][0]['text'] as String;
      debugPrint('[ClaudeAPI] 열 감지 응답: $text');
      
      final match = RegExp(r'[124]').firstMatch(text);
      if (match != null) {
        final columns = int.parse(match.group(0)!);
        debugPrint('[ClaudeAPI] 감지된 열 개수: $columns');
        return columns;
      }
    }
    
    debugPrint('[ClaudeAPI] 열 감지 실패, 기본값 2 반환');
    return 2;  // 기본값
  } catch (e) {
    debugPrint('[ClaudeAPI] 열 감지 예외: $e');
    return 2;
  }
}

/// 병합된 1열 이미지에서 정답 추출
Future<List<Map<String, dynamic>>> extractAnswersFromMergedImage(
  File mergedImage,
  List<Map<String, dynamic>> tocEntries,
) async {
  final apiKey = await _getApiKey();
  if (apiKey == null) {
    throw Exception('API 키가 설정되지 않았습니다');
  }

  final bytes = await mergedImage.readAsBytes();
  final base64Data = base64Encode(bytes);

  // 목차 정보 문자열
  final tocInfo = tocEntries.map((e) {
    final name = e['unitName'] ?? '';
    final start = e['startPage'] ?? 0;
    final end = e['endPage'] ?? start;
    return '$name: p.$start~$end';
  }).join('\n');

  debugPrint('[ClaudeAPI] 병합 이미지에서 정답 추출 시작');
  debugPrint('[ClaudeAPI] 목차:\n$tocInfo');

  try {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _modelHaiku,
        'max_tokens': 8000,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/png',
                  'data': base64Data,
                },
              },
              {
                'type': 'text',
                'text': '''이 이미지는 영어 교재 정답지입니다.
이미지가 세로로 길게 이어져 있습니다. 위에서 아래로 순서대로 읽어주세요.

★★★ 목차 정보 ★★★
$tocInfo

★★★ 추출 방법 ★★★
1. "p.XX", "pp.XX-YY" 형식의 페이지 번호 찾기
2. 각 페이지의 섹션(A, B, C, D...) 구분
3. 각 섹션의 문제 번호와 정답 추출

JSON 형식:
{
  "pages": [
    {
      "pageNumber": 9,
      "unitName": "Unit 01 문장을 이루는 요소",
      "sections": {
        "A": ["정답1", "정답2", "정답3"],
        "B": ["정답1", "정답2"]
      }
    }
  ]
}

규칙:
- 위에서 아래로 순서대로 모든 페이지 추출
- pageNumber는 이미지에 보이는 실제 페이지 번호
- JSON만 반환, 다른 텍스트 금지''',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;
      debugPrint('[ClaudeAPI] 정답 추출 응답 길이: ${content.length}');

      try {
        String jsonStr = content;
        if (content.contains('```json')) {
          jsonStr = content.split('```json')[1].split('```')[0].trim();
        } else if (content.contains('```')) {
          jsonStr = content.split('```')[1].split('```')[0].trim();
        } else if (content.contains('{')) {
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}') + 1;
          jsonStr = content.substring(start, end);
        }

        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        final pages = parsed['pages'] as List<dynamic>? ?? [];
        
        final results = <Map<String, dynamic>>[];
        for (final page in pages) {
          final pageNum = page['pageNumber'] as int?;
          final unitName = page['unitName'] as String? ?? '';
          final sections = page['sections'] as Map<String, dynamic>? ?? {};
          
          // 정답 내용을 문자열로 변환
          final contentBuffer = StringBuffer();
          contentBuffer.writeln(unitName);
          contentBuffer.writeln();
          
          for (final entry in sections.entries) {
            contentBuffer.writeln('${entry.key})');
            final answers = entry.value as List<dynamic>? ?? [];
            for (int i = 0; i < answers.length; i++) {
              contentBuffer.writeln('${i + 1}. ${answers[i]}');
            }
            contentBuffer.writeln();
          }
          
          results.add({
            'pageNumber': pageNum,
            'content': contentBuffer.toString().trim(),
            'unitName': unitName,
          });
        }
        
        debugPrint('[ClaudeAPI] 추출 완료: ${results.length}페이지');
        return results;
        
      } catch (e) {
        debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
        return [];
      }
    } else {
      debugPrint('[ClaudeAPI] API 에러: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    debugPrint('[ClaudeAPI] 정답 추출 예외: $e');
    return [];
  }
}
```

- [ ] claude_api_service.dart에 `detectColumnCount` 메서드 추가
- [ ] claude_api_service.dart에 `extractAnswersFromMergedImage` 메서드 추가

---

### 4. answer_camera_page.dart 수정

**`_pickPdfForAll` 메서드 전체 교체**:

```dart
/// 전체 Volume PDF 한번에 업로드 (열 분리 + 세로 병합 방식)
Future<void> _pickPdfForAll() async {
  safePrint('[AnswerCamera] PDF 선택 시작 (열 분리 방식)');

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
        _analysisStatus = 'PDF → 이미지 변환 중...';
      });

      // 1. PDF → 이미지 변환
      final pageImages = await PdfToImageService.convertPdfToImages(file);
      safePrint('[AnswerCamera] ${pageImages.length}개 페이지 이미지 생성');

      setState(() {
        _totalChunks = pageImages.length;
        _currentChunk = 0;
      });

      List<Map<String, dynamic>> allExtractedPages = [];

      // 2. 각 페이지 처리
      for (int i = 0; i < pageImages.length; i++) {
        _currentChunk = i + 1;
        setState(() {
          _analysisStatus = '페이지 ${i + 1}/${pageImages.length} 처리 중...';
        });

        safePrint('[AnswerCamera] === 페이지 ${i + 1} 처리 시작 ===');

        try {
          // 2-1. 열 개수 감지
          setState(() => _analysisStatus = '페이지 ${i + 1}: 열 구조 분석 중...');
          final columns = await _claudeService.detectColumnCount(pageImages[i]);
          safePrint('[AnswerCamera] 페이지 ${i + 1}: $columns열 감지');

          // 2-2. 열별 크롭
          setState(() => _analysisStatus = '페이지 ${i + 1}: 열 분리 중...');
          final croppedColumns = await ImageProcessorService.cropByColumns(pageImages[i], columns);
          safePrint('[AnswerCamera] 페이지 ${i + 1}: ${croppedColumns.length}개 열 분리');

          // 2-3. 세로 병합
          setState(() => _analysisStatus = '페이지 ${i + 1}: 이미지 병합 중...');
          final mergedImage = await ImageProcessorService.mergeVertically(croppedColumns);
          safePrint('[AnswerCamera] 페이지 ${i + 1}: 병합 완료');

          // 2-4. 정답 추출
          setState(() => _analysisStatus = '페이지 ${i + 1}: 정답 추출 중...');
          
          // 목차 준비
          final tocEntries = _prepareTocEntries();
          
          final pageResults = await _claudeService.extractAnswersFromMergedImage(
            mergedImage, 
            tocEntries,
          );
          
          allExtractedPages.addAll(pageResults);
          safePrint('[AnswerCamera] 페이지 ${i + 1}: ${pageResults.length}개 교재 페이지 추출');

          // 임시 파일 정리
          await ImageProcessorService.cleanup(croppedColumns);
          if (mergedImage.path != croppedColumns.first.path) {
            await mergedImage.delete();
          }

        } catch (e) {
          safePrint('[AnswerCamera] 페이지 ${i + 1} 처리 실패: $e');
        }

        // Rate limit 대기
        if (i < pageImages.length - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // 3. 이미지 파일들 정리
      await PdfToImageService.cleanupImages(pageImages);

      setState(() => _isAnalyzing = false);

      // 4. 결과 처리
      if (allExtractedPages.isNotEmpty) {
        allExtractedPages.sort((a, b) {
          final aPage = a['pageNumber'] as int? ?? 0;
          final bPage = b['pageNumber'] as int? ?? 0;
          return aPage.compareTo(bPage);
        });

        safePrint('[AnswerCamera] 총 ${allExtractedPages.length}페이지 추출 완료');

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

          if (pages.isNotEmpty) {
            await _validateAndSavePagesWithAnswers(pages, answerContents);
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('페이지를 인식하지 못했습니다')),
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
```

**import 추가** (파일 상단):
```dart
import '../../../shared/services/pdf_to_image_service.dart';
import '../../../shared/services/image_processor_service.dart';
```

- [ ] answer_camera_page.dart에 import 추가
- [ ] `_pickPdfForAll` 메서드 교체
- [ ] `_prepareTocEntries` 헬퍼 메서드 추가

---

### 5. flutter analyze

- [ ] `cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1`
- [ ] `flutter pub get`
- [ ] `flutter analyze 2>&1 | tail -30`
- [ ] 에러 0개 확인

---

### 6. 테스트

- [ ] `flutter run -d RFCY40MNBLL`
- [ ] 내 책 → Grammar Effect → 정답지 등록
- [ ] PDF 업로드
- [ ] 콘솔 로그 확인:
  - `[PdfToImage] PDF → 이미지 변환 시작`
  - `[ClaudeAPI] 열 감지 응답: 2`
  - `[ImageProcessor] 열 분할 시작: 2열`
  - `[ImageProcessor] 세로 병합 시작`
  - `[ClaudeAPI] 병합 이미지에서 정답 추출`
- [ ] "인식 결과 확인" 다이얼로그에서 인식률 확인
- [ ] **기대: 17페이지 중 15개 이상 인식** (기존 10개에서 증가)

---

## 완료 조건

1. [ ] pdfx, image 패키지 추가 완료
2. [ ] pdf_to_image_service.dart 생성 완료
3. [ ] image_processor_service.dart 생성 완료
4. [ ] claude_api_service.dart에 2개 메서드 추가 완료
5. [ ] answer_camera_page.dart 수정 완료
6. [ ] flutter analyze 에러 0개
7. [ ] **인식률 개선 확인** (10페이지 → 15페이지 이상)
8. [ ] 로그 저장: ai_bridge/logs/big_133_test.log
9. [ ] 보고서 작성: ai_bridge/report/big_133_report.md
10. [ ] CP가 "테스트 종료" 입력

---

## ⚠️ 주의사항

1. **pdfx 패키지**: Windows에서 동작 확인 필요. 안되면 `pdf_render` 시도
2. **메모리**: 이미지 처리 후 반드시 cleanup 호출
3. **Rate limit**: 페이지당 API 2번 호출 (열 감지 + 정답 추출) → 딜레이 필수
4. **이미지 크기**: 너무 크면 API 제한 걸림 → 적절한 해상도 조절 필요
