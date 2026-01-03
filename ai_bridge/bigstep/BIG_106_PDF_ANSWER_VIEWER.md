# BIG_106: PDF 정답지 인식 결과 확인 UI

> 생성일: 2025-01-01
> 목표: PDF 정답지 업로드 후 인식된 내용을 화면에 표시하여 정확도 검증

---

## ⚠️ 작성 전 체크리스트

### 기본 확인
- [x] 로컬 코드 확인 → claude_api_service.dart, answer_camera_page.dart
- [x] 수정할 파일 특정 → 2개 파일
- [x] safePrint 로그 추가 지시 → 포함

### 테스트 환경
- [x] 빌드 필요 → 폰 빌드
- [ ] 듀얼 필요 → 불필요

### 플로우 확인
- [x] 진입 경로 → 책 상세 → 정답지 등록 → PDF 업로드
- [x] 영향 범위 → answer_camera_page.dart, claude_api_service.dart

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 수정 파일:
  1. `lib/shared/services/claude_api_service.dart`
  2. `lib/features/my_books/pages/answer_camera_page.dart`

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- PDF 업로드 후 **"인식된 내용 그대로"** 화면에 표시
- 예: `Page 9: A 1 목적어 2 동사 3 수식어 4 보어 / B 1 wrote 2 My teacher...`
- CP가 실제 PDF와 비교해서 인식 정확도 확인 가능

### 테스트 시나리오
```
1. 앱 → 내 교재 → 책 선택 → 정답지 등록
2. "전체 PDF 업로드" 클릭
3. Grammar Effect 2 Answer Keys.pdf 선택
4. 분석 완료 → 결과 다이얼로그 표시
5. 페이지별 인식 내용 확인 (실제 PDF와 비교)
6. 정확하면 "저장", 아니면 "취소"
```

---

## 스몰스텝

### 1. Claude API에 PDF 텍스트 추출 함수 추가

파일: `lib/shared/services/claude_api_service.dart`
위치: 파일 끝 `analyzePdfPages` 함수 아래에 추가

```dart
/// PDF 정답지 텍스트 추출 (인식 확인용)
/// 반환: List<Map> - [{pageNumber: 9, content: "A 1 목적어 2 동사..."}, ...]
Future<List<Map<String, dynamic>>> extractPdfText(File pdfFile) async {
  final apiKey = await _getApiKey();
  if (apiKey == null) {
    throw Exception('API 키가 설정되지 않았습니다');
  }

  final bytes = await pdfFile.readAsBytes();
  final base64Data = base64Encode(bytes);

  debugPrint('[ClaudeAPI] PDF 텍스트 추출 시작');

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
        'max_tokens': 16000,
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
                'text': '''이 PDF는 영어 교재 정답지입니다.

각 페이지에서 보이는 내용을 **그대로** 추출해주세요.
- 페이지 번호 (p. XX 형식으로 인쇄된 것)
- 섹션 (A, B, C, D, Practice, Unit 등)
- 문제 번호와 정답

JSON 형식:
{
  "pages": [
    {
      "pageNumber": 9,
      "content": "Unit 01 문장을 이루는 요소\\nPractice\\nA 1 목적어 2 동사 3 수식어 4 보어\\nB 1 wrote 2 My teacher 3 great 4 dinner\\nC 1 주어, 동사, 보어 2 주어, 동사, 목적어, 수식어..."
    },
    {
      "pageNumber": 11,
      "content": "Unit 02 1형식, 2형식\\nA 1 angry 2 an artist..."
    }
  ]
}

content에는 해당 페이지에서 보이는 텍스트를 줄바꿈(\\n)으로 구분해서 넣어주세요.
모든 페이지를 빠짐없이 추출해주세요.''',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;
      debugPrint('[ClaudeAPI] PDF 텍스트 추출 응답 길이: ${content.length}');

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
        
        debugPrint('[ClaudeAPI] 텍스트 추출 완료: ${pages.length}페이지');
        return pages;
      } catch (e) {
        debugPrint('[ClaudeAPI] JSON 파싱 실패: $e');
        debugPrint('[ClaudeAPI] 원본 앞부분: ${content.substring(0, content.length > 500 ? 500 : content.length)}');
        return [];
      }
    } else {
      debugPrint('[ClaudeAPI] 에러: ${response.statusCode}');
      debugPrint('[ClaudeAPI] 응답: ${response.body}');
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('[ClaudeAPI] PDF 텍스트 추출 예외: $e');
    rethrow;
  }
}
```

### 2. answer_camera_page.dart - _pickPdfForAll 함수 수정

파일: `lib/features/my_books/pages/answer_camera_page.dart`

**기존 `_pickPdfForAll` 함수 전체**를 아래로 교체:

```dart
/// 전체 Volume PDF 한번에 업로드 (인식 결과 확인 포함)
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
        _analysisStatus = 'PDF 텍스트 추출 중...';
      });

      // 1. 텍스트 추출 (인식 확인용)
      List<Map<String, dynamic>> extractedPages = [];
      try {
        extractedPages = await _claudeService.extractPdfText(file);
        safePrint('[AnswerCamera] 텍스트 추출 완료: ${extractedPages.length}페이지');
      } catch (e) {
        safePrint('[AnswerCamera] 텍스트 추출 실패: $e');
      }

      setState(() => _isAnalyzing = false);

      if (extractedPages.isNotEmpty) {
        // 2. 인식 결과 확인 다이얼로그
        final proceed = await _showExtractedTextDialog(extractedPages);
        
        if (proceed == true) {
          // 3. 페이지 번호만 추출해서 저장
          final pages = extractedPages
              .map((p) => p['pageNumber'] as int?)
              .whereType<int>()
              .toList()
            ..sort();
          
          if (pages.isNotEmpty) {
            await _validateAndSavePages(pages);
          }
        }
      } else {
        // 텍스트 추출 실패 시 기존 방식으로 폴백
        safePrint('[AnswerCamera] 텍스트 추출 실패, 기존 방식 시도');
        setState(() {
          _isAnalyzing = true;
          _analysisStatus = '페이지 번호 추출 중...';
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

/// 추출된 텍스트 확인 다이얼로그
Future<bool?> _showExtractedTextDialog(List<Map<String, dynamic>> pages) async {
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
```

### 3. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```
- 에러 0개 확인

### 4. 폰 빌드 및 테스트

```bash
flutter run -d RFCY40MNBLL
```

테스트:
1. 앱 → 내 교재 → 책 선택 → 정답지 등록
2. "전체 PDF 업로드" 클릭
3. Grammar Effect 2 Answer Keys.pdf 선택
4. **인식 결과 다이얼로그에서 내용 확인**
   - Page 9: `A 1 목적어 2 동사...` 보이는지
   - 실제 PDF와 비교
5. CP가 정확도 확인

---

## ⚠️ 컨텍스트 관리 (필수!)

1. 스몰스텝 2~3개 완료할 때마다 로그 저장
2. 로그 저장 후 /compact 실행
3. 파일 수정은 1개씩

---

## 완료 조건

1. PDF 업로드 후 **인식된 텍스트**가 다이얼로그에 표시됨
2. 페이지별로 내용 구분되어 표시됨
3. flutter analyze 에러 0개
4. CP가 실제 PDF와 비교하여 정확도 확인
5. CP가 "테스트 종료" 입력
6. 보고서: ai_bridge/report/big_106_report.md
