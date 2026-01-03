# BIG_107: PDF 정답지 페이지 분할 처리

> 생성일: 2025-01-01
> 목표: 대용량 PDF(90페이지 등)를 10페이지 단위로 분할하여 순차 처리, 인식 결과 표시

---

## ⚠️ 작성 전 체크리스트

### 기본 확인
- [x] 로컬 코드 확인 → claude_api_service.dart, answer_camera_page.dart 확인 완료
- [x] 수정할 파일 특정 → 4개 파일 (pubspec.yaml, pdf_chunker.dart 신규, claude_api_service.dart, answer_camera_page.dart)
- [x] safePrint 로그 추가 지시 → 포함

### 테스트 환경
- [x] 빌드 필요 → 폰 빌드
- [ ] 듀얼 필요 → 불필요

### 플로우 확인
- [x] 진입 경로 → 책 상세 → 정답지 등록 → 전체 PDF 업로드
- [x] 영향 범위 → answer_camera_page.dart, claude_api_service.dart, 신규 pdf_chunker.dart

### 의존성 확인
- [x] 새로 import 필요한 패키지 → `pdf: ^3.10.8` 또는 `syncfusion_flutter_pdf` 추가 필요
- [ ] schema/모델 변경 → 없음

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 수정 파일:
  1. `pubspec.yaml` - PDF 패키지 추가
  2. `lib/shared/services/pdf_chunker.dart` - 신규 생성
  3. `lib/shared/services/claude_api_service.dart` - 청크별 분석 함수 추가
  4. `lib/features/my_books/pages/answer_camera_page.dart` - 분할 처리 로직 + 프로그레스 UI

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 90페이지 PDF 업로드해도 **멈추지 않고** 순차 처리됨
- 프로그레스 표시: "페이지 1-10 처리 중... (1/9)"
- 각 청크 처리 후 1~2초 딜레이로 Rate limit 회피
- 모든 청크 완료 후 결과 합쳐서 인식 결과 다이얼로그 표시

### 테스트 시나리오
```
1. 앱 → 내 교재 → 책 선택 → 정답지 등록
2. "전체 PDF 업로드" 클릭
3. Grammar Effect 2 Answer Keys.pdf (90페이지) 선택
4. 프로그레스 확인: "1-10페이지 처리 중 (1/9)..." → "11-20페이지..." → ...
5. 완료 후 인식 결과 다이얼로그 표시
6. 페이지별 내용 확인 (p.9, p.11, p.13... 정답 내용)
7. "정확함 - 저장" 클릭 → 페이지 번호 저장
```

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. pubspec.yaml에 PDF 패키지 추가

- [ ] 파일: `pubspec.yaml`
- [ ] 위치: dependencies 섹션 (line 60 근처, `google_mlkit_text_recognition` 아래)
- [ ] 추가할 코드:

```yaml
  # PDF Processing
  syncfusion_flutter_pdf: ^24.2.9
```

> **참고**: `syncfusion_flutter_pdf`는 무료 커뮤니티 라이선스로 사용 가능 (연매출 $1M 미만)
> `pdf` 패키지보다 PDF 분할/병합 기능이 강력함

- [ ] 추가 후: `flutter pub get` 실행

---

### 2. pdf_chunker.dart 신규 생성

- [ ] 파일: `lib/shared/services/pdf_chunker.dart` (신규)
- [ ] 전체 코드:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDF 파일을 청크로 분할하는 유틸리티
class PdfChunker {
  /// PDF 파일을 지정된 페이지 수로 분할
  /// 반환: List<File> - 분할된 PDF 파일들 (임시 파일)
  static Future<List<File>> splitPdf(File pdfFile, {int pagesPerChunk = 10}) async {
    safePrint('[PdfChunker] PDF 분할 시작: ${pdfFile.path}');
    
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final totalPages = document.pages.count;
    
    safePrint('[PdfChunker] 총 페이지 수: $totalPages, 청크당 페이지: $pagesPerChunk');
    
    final tempDir = await getTemporaryDirectory();
    final chunks = <File>[];
    
    // 청크 수 계산
    final chunkCount = (totalPages / pagesPerChunk).ceil();
    safePrint('[PdfChunker] 생성할 청크 수: $chunkCount');
    
    for (int i = 0; i < chunkCount; i++) {
      final startPage = i * pagesPerChunk;
      final endPage = (startPage + pagesPerChunk).clamp(0, totalPages);
      
      safePrint('[PdfChunker] 청크 ${i + 1}/$chunkCount: 페이지 ${startPage + 1}~$endPage');
      
      // 새 PDF 문서 생성
      final chunkDoc = PdfDocument();
      
      // 원본에서 페이지 복사
      for (int j = startPage; j < endPage; j++) {
        final template = document.pages[j].createTemplate();
        final page = chunkDoc.pages.add();
        page.graphics.drawPdfTemplate(
          template,
          const Offset(0, 0),
        );
      }
      
      // 임시 파일로 저장
      final chunkPath = '${tempDir.path}/pdf_chunk_${i + 1}.pdf';
      final chunkBytes = await chunkDoc.save();
      final chunkFile = File(chunkPath);
      await chunkFile.writeAsBytes(chunkBytes);
      
      chunks.add(chunkFile);
      chunkDoc.dispose();
      
      safePrint('[PdfChunker] 청크 ${i + 1} 생성 완료: $chunkPath');
    }
    
    document.dispose();
    
    safePrint('[PdfChunker] PDF 분할 완료: ${chunks.length}개 청크');
    return chunks;
  }
  
  /// 청크별 페이지 범위 정보 반환
  static List<Map<String, int>> getChunkRanges(int totalPages, {int pagesPerChunk = 10}) {
    final ranges = <Map<String, int>>[];
    final chunkCount = (totalPages / pagesPerChunk).ceil();
    
    for (int i = 0; i < chunkCount; i++) {
      final startPage = i * pagesPerChunk + 1;  // 1-indexed for display
      final endPage = ((i + 1) * pagesPerChunk).clamp(1, totalPages);
      ranges.add({
        'start': startPage,
        'end': endPage,
        'index': i,
      });
    }
    
    return ranges;
  }
  
  /// PDF 총 페이지 수 확인
  static Future<int> getPageCount(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final count = document.pages.count;
    document.dispose();
    return count;
  }
  
  /// 임시 청크 파일들 삭제
  static Future<void> cleanupChunks(List<File> chunks) async {
    for (final chunk in chunks) {
      try {
        if (await chunk.exists()) {
          await chunk.delete();
          safePrint('[PdfChunker] 청크 삭제: ${chunk.path}');
        }
      } catch (e) {
        safePrint('[PdfChunker] 청크 삭제 실패: $e');
      }
    }
  }
}
```

---

### 3. claude_api_service.dart에 단일 청크 분석 함수 추가

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 위치: `extractPdfText` 함수 아래 (파일 끝 부분)
- [ ] 추가할 코드:

```dart
  /// 단일 PDF 청크 텍스트 추출 (분할 처리용)
  /// 작은 PDF(10페이지 이하)에 최적화
  Future<List<Map<String, dynamic>>> extractPdfChunkText(File pdfChunk) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    final bytes = await pdfChunk.readAsBytes();
    final base64Data = base64Encode(bytes);

    debugPrint('[ClaudeAPI] PDF 청크 텍스트 추출 시작');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 4000,  // 청크당 4000 토큰으로 제한
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'document',
                  'source': {
                    'type': 'base64',
                    'media_type': 'application/pdf',
                    'data': base64Data,
                  },
                },
                {
                  'type': 'text',
                  'text': '''이 PDF는 영어 교재 정답지의 일부입니다.

각 페이지에서 보이는 내용을 추출해주세요:
- 페이지 번호 (p. XX 형식)
- 섹션 (A, B, C, D, Practice, Unit 등)
- 문제 번호와 정답

JSON 형식:
{
  "pages": [
    {
      "pageNumber": 9,
      "content": "Unit 01 문장을 이루는 요소\\nA 1 목적어 2 동사 3 수식어..."
    }
  ]
}

content에는 해당 페이지 텍스트를 줄바꿈(\\n)으로 구분해서 넣어주세요.''',
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        debugPrint('[ClaudeAPI] 청크 응답 길이: ${content.length}');

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
          final pages = (parsed['pages'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();

          debugPrint('[ClaudeAPI] 청크에서 ${pages.length}페이지 추출');
          return pages;
        } catch (e) {
          debugPrint('[ClaudeAPI] 청크 JSON 파싱 실패: $e');
          return [];
        }
      } else if (response.statusCode == 429) {
        debugPrint('[ClaudeAPI] Rate limit 초과 (429)');
        throw Exception('RATE_LIMIT');
      } else {
        debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ClaudeAPI] 청크 처리 예외: $e');
      rethrow;
    }
  }
```

---

### 4. answer_camera_page.dart 수정 - import 추가

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 위치: import 섹션 맨 아래 (line 11 근처)
- [ ] 추가할 코드:

```dart
import '../../../shared/services/pdf_chunker.dart';
```

---

### 5. answer_camera_page.dart 수정 - State 변수 추가

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 위치: `_analysisStatus` 변수 아래 (line 28 근처)
- [ ] 추가할 코드:

```dart
  int _currentChunk = 0;
  int _totalChunks = 0;
```

---

### 6. answer_camera_page.dart 수정 - _pickPdfForAll 함수 전체 교체

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 위치: `_pickPdfForAll` 함수 전체 (line 90 ~ line 167 근처)
- [ ] 기존 함수 삭제 후 아래 코드로 교체:

```dart
  /// 전체 Volume PDF 한번에 업로드 (청크 분할 처리)
  Future<void> _pickPdfForAll() async {
    safePrint('[AnswerCamera] PDF 선택 시작 (전체 Volume)');

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
          _analysisStatus = 'PDF 페이지 수 확인 중...';
        });

        // 1. PDF 페이지 수 확인
        final totalPages = await PdfChunker.getPageCount(file);
        safePrint('[AnswerCamera] PDF 총 페이지: $totalPages');

        List<Map<String, dynamic>> allExtractedPages = [];

        // 2. 20페이지 이하면 분할 없이 처리
        if (totalPages <= 20) {
          safePrint('[AnswerCamera] 소용량 PDF - 단일 처리');
          setState(() => _analysisStatus = 'PDF 텍스트 추출 중...');
          
          try {
            allExtractedPages = await _claudeService.extractPdfText(file);
          } catch (e) {
            safePrint('[AnswerCamera] 단일 처리 실패: $e');
          }
        } else {
          // 3. 대용량 PDF - 청크 분할 처리
          safePrint('[AnswerCamera] 대용량 PDF - 청크 분할 처리');
          
          setState(() => _analysisStatus = 'PDF 분할 중...');
          final chunks = await PdfChunker.splitPdf(file, pagesPerChunk: 10);
          
          setState(() {
            _totalChunks = chunks.length;
            _currentChunk = 0;
          });
          
          safePrint('[AnswerCamera] ${chunks.length}개 청크로 분할 완료');

          // 4. 각 청크 순차 처리
          for (int i = 0; i < chunks.length; i++) {
            _currentChunk = i + 1;
            final chunkStart = i * 10 + 1;
            final chunkEnd = ((i + 1) * 10).clamp(1, totalPages);
            
            setState(() {
              _analysisStatus = '페이지 $chunkStart~$chunkEnd 처리 중... ($_currentChunk/$_totalChunks)';
            });
            
            safePrint('[AnswerCamera] 청크 ${i + 1}/${chunks.length} 처리 시작');

            try {
              final chunkResult = await _processChunkWithRetry(chunks[i]);
              allExtractedPages.addAll(chunkResult);
              safePrint('[AnswerCamera] 청크 ${i + 1} 완료: ${chunkResult.length}페이지 추출');
            } catch (e) {
              safePrint('[AnswerCamera] 청크 ${i + 1} 실패: $e');
              // 실패해도 계속 진행 (부분 결과라도 보여주기 위해)
            }

            // Rate limit 회피를 위한 딜레이 (마지막 청크 제외)
            if (i < chunks.length - 1) {
              setState(() => _analysisStatus = '다음 청크 준비 중... (2초 대기)');
              await Future.delayed(const Duration(seconds: 2));
            }
          }

          // 5. 임시 청크 파일 정리
          await PdfChunker.cleanupChunks(chunks);
        }

        setState(() => _isAnalyzing = false);

        // 6. 결과 확인
        if (allExtractedPages.isNotEmpty) {
          // 페이지 번호로 정렬
          allExtractedPages.sort((a, b) {
            final aPage = a['pageNumber'] as int? ?? 0;
            final bPage = b['pageNumber'] as int? ?? 0;
            return aPage.compareTo(bPage);
          });
          
          safePrint('[AnswerCamera] 총 ${allExtractedPages.length}페이지 추출 완료');
          
          // 인식 결과 확인 다이얼로그
          final proceed = await _showExtractedTextDialog(allExtractedPages);

          if (proceed == true) {
            final pages = allExtractedPages
                .map((p) => p['pageNumber'] as int?)
                .whereType<int>()
                .toList()
              ..sort();

            if (pages.isNotEmpty) {
              await _validateAndSavePages(pages);
            }
          }
        } else {
          // 텍스트 추출 완전 실패 시 기존 방식으로 폴백
          safePrint('[AnswerCamera] 텍스트 추출 실패, 페이지 번호만 추출 시도');
          setState(() {
            _isAnalyzing = true;
            _analysisStatus = '페이지 번호 추출 중... (대체 방식)';
          });

          final pages = await _analyzePdfWithRetry(file);
          setState(() => _isAnalyzing = false);

          if (pages.isNotEmpty) {
            await _validateAndSavePages(pages);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('페이지 번호를 인식하지 못했습니다')),
              );
            }
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

  /// 청크 처리 with 재시도
  Future<List<Map<String, dynamic>>> _processChunkWithRetry(File chunk, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _claudeService.extractPdfChunkText(chunk);
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
```

---

### 7. answer_camera_page.dart 수정 - _buildAnalyzingView 업데이트

- [ ] 파일: `lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 위치: `_buildAnalyzingView` 함수 (line 320 근처)
- [ ] 기존 함수를 아래로 교체:

```dart
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
```

---

### 8. flutter pub get 실행

- [ ] 명령어:
```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter pub get
```

---

### 9. flutter analyze

- [ ] 명령어:
```bash
flutter analyze
```
- [ ] 에러 0개 확인

---

### 10. 폰 빌드 및 테스트

- [ ] 명령어:
```bash
flutter run -d RFCY40MNBLL
```

- [ ] 테스트 시나리오:
  1. 앱 → 내 교재 → Grammar Effect 2 선택
  2. 정답지 등록 → "전체 PDF 업로드" 클릭
  3. Grammar Effect 2 Answer Keys.pdf (90페이지) 선택
  4. **프로그레스 확인**:
     - "PDF 페이지 수 확인 중..."
     - "PDF 분할 중..."
     - "페이지 1~10 처리 중... (1/9)"
     - "다음 청크 준비 중... (2초 대기)"
     - "페이지 11~20 처리 중... (2/9)"
     - ... (반복)
  5. **인식 결과 다이얼로그** 표시 확인
     - Page 9: Unit 01 문장을 이루는 요소 / A 1 목적어 2 동사...
     - Page 11: Unit 02 1형식, 2형식 / A 1 angry 2 an artist...
  6. 실제 PDF와 비교하여 정확도 확인
  7. "정확함 - 저장" 클릭
  8. 페이지 저장 확인

---

## ⚠️ 컨텍스트 관리 (필수!)

1. 스몰스텝 2~3개 완료할 때마다 로그 저장
2. 로그 저장 후 /compact 실행
3. 파일 수정은 1개씩

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정
- **프로그레스 표시 + 인식 결과 다이얼로그가 핵심!**

---

## ⚠️ Opus 필수: 로그 직접 확인!

보고서만 읽지 말고, 로그 파일도 직접 확인할 것!

```
확인할 로그:
- ai_bridge/logs/big_107_step_XX.log
- Flutter 콘솔: [PdfChunker], [ClaudeAPI], [AnswerCamera] 로그
```

---

## 완료 조건

1. 90페이지 PDF 업로드 시 **멈추지 않고** 청크별 순차 처리됨
2. 프로그레스 UI가 정상 표시됨 (청크 X/Y, 프로그레스 바)
3. 모든 청크 완료 후 **인식 결과 다이얼로그** 정상 표시
4. flutter analyze 에러 0개
5. CP가 실제 PDF와 비교하여 정확도 확인
6. CP가 "테스트 종료" 입력
7. 보고서: ai_bridge/report/big_107_report.md
