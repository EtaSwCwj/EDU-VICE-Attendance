# BIG_136: OCR 텍스트 → AI JSON 변환 (정규식 제거)

> 생성일: 2026-01-03
> 목표: 정규식 파싱 실패 → ML Kit OCR 텍스트를 Claude API에 보내서 JSON 구조화

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

### 기본 확인
- [x] 로컬 코드 확인했나? → answer_parser_service.dart, claude_api_service.dart 확인 완료
- [x] 수정할 파일/줄 번호 특정했나? → 아래 명시
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나? → O
- [x] 새 함수/로직에 safePrint 로그 추가 지시했나? → O (`[TextParse]` 태그)

### 테스트 환경
- [x] 테스트 계정 리셋 필요한가? → 불필요 (정답지 분석이라 계정 무관)
- [x] 빌드 필요한가? → O (폰에서 PDF 업로드 테스트)
- [x] 듀얼 빌드 필요한가? → X (단독 테스트)

### 플로우 확인
- [x] 진입 경로: 내 책 → 책 선택 → 정답지 등록 → 전체 PDF 업로드
- [x] 영향 범위: answer_camera_page.dart에서 _answerParser.extractAnswers() 호출

### 의존성 확인
- [x] 새로 import 필요한 패키지 있나? → 없음 (기존 http 패키지 사용)
- [x] schema/모델 변경 필요한가? → 없음

### 에러 케이스
- [x] 실패 시: 스낵바 "페이지를 인식하지 못했습니다" (기존 로직 유지)
- [x] 네트워크 오류: RATE_LIMIT 예외 처리 (기존 로직 유지)

---

## ⚠️ 사이드 이펙트 체크리스트

### 새 함수 추가 시
- [x] 관련된 기존 함수: `extractAnswers()` in answer_parser_service.dart
- [x] 이 함수를 호출하는 곳: answer_camera_page.dart line 207

### 테스트 시 로그 분석
- [ ] `[TextParse]` 로그 확인
- [ ] `[AnswerParser]` 로그 확인
- [ ] 예상 페이지 수 vs 실제 페이지 수 비교

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 경로: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 수정 파일:
  1. `lib/shared/services/claude_api_service.dart` (메서드 추가)
  2. `lib/shared/services/answer_parser_service.dart` (로직 교체)
- 테스트 파일: Grammar Effect 2 정답지 PDF

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. PDF 업로드 → ML Kit OCR → Claude API로 텍스트 전송 → JSON 응답 수신
2. 페이지 번호, 섹션, 정답이 정확하게 구조화됨
3. 정규식 오인식 문제 해결 (141페이지 → 실제 17페이지 정도로 정상 인식)

### 테스트 시나리오
```
1. 앱 실행 → 내 책 → Grammar Effect 2 선택 → 정답지 등록 클릭
2. 전체 PDF 업로드 클릭 → Grammar Effect 정답지 PDF 선택
3. "페이지 X/17 처리 중..." 진행 확인
4. 로그에서 [TextParse] 메시지 출력 확인
5. 인식 결과 확인 다이얼로그에서 페이지 번호 확인
6. 성공 조건: p.9, p.11, p.13, p.15... 등 실제 교재 페이지가 정확히 인식됨
```

---

## 스몰스텝

### 1. claude_api_service.dart에 parseOcrTextToAnswers 메서드 추가

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 위치: 파일 마지막 `}` 바로 앞 (약 line 1350 근처)
- [ ] 새 코드 (추가):

```dart
  /// OCR 텍스트를 JSON 정답 구조로 변환 (텍스트 전용 - 이미지 없음)
  /// 
  /// ML Kit OCR로 추출한 텍스트를 AI가 분석하여 구조화
  /// - 이미지 전송 없음 → 비용 절감 + 빠름
  /// - 텍스트 의미 이해 → 정규식보다 정확
  Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) {
      throw Exception('API 키가 설정되지 않았습니다');
    }

    safePrint('[TextParse] OCR 텍스트 파싱 시작, 길이: ${ocrText.length}');

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
              'content': '''당신은 교육용 학습 관리 시스템의 데이터 파서입니다.

[입력 데이터]
아래는 영어 교재 학습 자료를 OCR로 추출한 텍스트입니다.

$ocrText

[작업]
위 텍스트를 분석하여 교재 페이지별로 내용을 구조화하세요.

[페이지 번호 찾는 방법]
1. "p. 숫자", "p.숫자", "pp. 숫자-숫자" 패턴
2. "Practice p.XX", "Actual Test pp.XX-XX" 형식
3. 주의: "step.4", "cup.3" 같은 단어는 페이지 번호가 아님!

[섹션 구분]
- A, B, C, D 또는 Task 1, Task 2 등
- 대문자 하나 + ) 또는 . 형식: "A)", "B.", "C "
- 주의: 문장 중간의 대문자(I, X 등)는 섹션이 아님!

[출력 형식 - JSON만]
{
  "pages": [
    {
      "pageNumber": 9,
      "unitName": "Unit 01 문장을 이루는 요소",
      "sections": {
        "A": ["목적어", "동사", "수식어", "보어"],
        "B": ["wrote", "My teacher", "great", "dinner"]
      }
    }
  ]
}

[필수 규칙]
1. JSON만 반환! 설명 없이!
2. pageNumber는 반드시 숫자 (문자열 X)
3. 같은 페이지가 여러 번 나오면 하나만 (중복 제거)
4. 정답 내용은 원문 그대로 유지
5. 섹션이 없으면 "ALL" 키 사용''',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'] as String;
        safePrint('[TextParse] API 응답 길이: ${content.length}');

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
          final seenPages = <int>{};

          for (final page in pages) {
            final pageNum = page['pageNumber'] as int?;
            if (pageNum == null || seenPages.contains(pageNum)) continue;
            seenPages.add(pageNum);

            final unitName = page['unitName']?.toString() ?? '';
            final sections = page['sections'] as Map<String, dynamic>? ?? {};

            final contentBuffer = StringBuffer();
            if (unitName.isNotEmpty) {
              contentBuffer.writeln(unitName);
              contentBuffer.writeln();
            }

            for (final entry in sections.entries) {
              contentBuffer.writeln('${entry.key})');
              final answers = entry.value;
              if (answers is List) {
                for (int i = 0; i < answers.length; i++) {
                  contentBuffer.writeln('${i + 1}. ${answers[i]}');
                }
              }
              contentBuffer.writeln();
            }

            results.add({
              'pageNumber': pageNum,
              'content': contentBuffer.toString().trim(),
              'unitName': unitName,
              'sections': sections,
            });

            safePrint('[TextParse] 페이지 추출: p.$pageNum - $unitName');
          }

          safePrint('[TextParse] 총 ${results.length}페이지 파싱 완료');
          return results;

        } catch (e) {
          safePrint('[TextParse] JSON 파싱 실패: $e');
          return [];
        }
      } else if (response.statusCode == 429) {
        safePrint('[TextParse] Rate limit (429)');
        throw Exception('RATE_LIMIT');
      } else {
        safePrint('[TextParse] API 에러: ${response.statusCode}');
        throw Exception('API 호출 실패: ${response.statusCode}');
      }
    } catch (e) {
      safePrint('[TextParse] 예외: $e');
      rethrow;
    }
  }
```

### 2. answer_parser_service.dart 수정

- [ ] 파일: `lib/shared/services/answer_parser_service.dart`

#### 2-1. import 추가 (line 5 근처)
- [ ] 기존 코드 (유지):
```dart
import 'mlkit_ocr_service.dart';
```
- [ ] 새 코드 (바로 아래 추가):
```dart
import 'claude_api_service.dart';
```

#### 2-2. 클래스 필드 추가 (line 14 근처)
- [ ] 기존 코드 (유지):
```dart
  final MlKitOcrService _ocrService = MlKitOcrService();
```
- [ ] 새 코드 (바로 아래 추가):
```dart
  final ClaudeApiService _claudeService = ClaudeApiService();
```

#### 2-3. extractAnswers 메서드 교체 (line 17~45)
- [ ] 기존 코드 (삭제):
```dart
  /// 이미지에서 정답 추출 (ML Kit + 정규식)
  Future<List<ParsedPage>> extractAnswers(File imageFile) async {
    debugPrint('[AnswerParser] 이미지 분석 시작: ${imageFile.path}');
    
    // 1. ML Kit OCR로 텍스트 추출
    final ocrResult = await _ocrService.analyzeImage(imageFile);
    
    // 2. 블록들을 위→아래 순서로 정렬 (top 기준)
    final sortedBlocks = List<OcrTextBlock>.from(ocrResult.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    // 3. 전체 텍스트 합치기
    final fullText = sortedBlocks.map((b) => b.text).join('\n');
    debugPrint('[AnswerParser] OCR 텍스트 길이: ${fullText.length}');
    debugPrint('[AnswerParser] OCR 텍스트 앞 500자:\n${fullText.substring(0, fullText.length > 500 ? 500 : fullText.length)}');
    
    // 4. 정규식으로 구조 파싱
    final pages = _parseText(fullText);
    
    debugPrint('[AnswerParser] 파싱 완료: ${pages.length}개 페이지');
    return pages;
  }
```

- [ ] 새 코드 (추가):
```dart
  /// 이미지에서 정답 추출 (ML Kit OCR + Claude AI 파싱)
  /// 
  /// 기존 정규식 방식 제거 → AI가 텍스트 의미 이해하여 구조화
  Future<List<ParsedPage>> extractAnswers(File imageFile) async {
    debugPrint('[AnswerParser] 이미지 분석 시작: ${imageFile.path}');
    
    // 1. ML Kit OCR로 텍스트 추출
    final ocrResult = await _ocrService.analyzeImage(imageFile);
    
    // 2. 블록들을 위→아래 순서로 정렬 (top 기준)
    final sortedBlocks = List<OcrTextBlock>.from(ocrResult.blocks)
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));
    
    // 3. 전체 텍스트 합치기
    final fullText = sortedBlocks.map((b) => b.text).join('\n');
    debugPrint('[AnswerParser] OCR 텍스트 길이: ${fullText.length}');
    
    if (fullText.isEmpty) {
      debugPrint('[AnswerParser] OCR 텍스트 비어있음');
      return [];
    }
    
    // 4. Claude API로 텍스트 → JSON 구조화
    try {
      final apiResults = await _claudeService.parseOcrTextToAnswers(fullText);
      
      // 5. API 결과를 ParsedPage로 변환
      final pages = apiResults.map((result) {
        final sections = <String, List<String>>{};
        final rawSections = result['sections'] as Map<String, dynamic>? ?? {};
        
        for (final entry in rawSections.entries) {
          if (entry.value is List) {
            sections[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
          }
        }
        
        return ParsedPage(
          pageNumber: result['pageNumber'] as int? ?? 0,
          sections: sections,
          rawContent: result['content'] as String? ?? '',
        );
      }).toList();
      
      debugPrint('[AnswerParser] AI 파싱 완료: ${pages.length}개 페이지');
      return pages;
      
    } catch (e) {
      debugPrint('[AnswerParser] AI 파싱 실패: $e');
      return [];
    }
  }
```

#### 2-4. 기존 정규식 메서드 주석처리 (line 47~175)
- [ ] `_parseText`, `_parseSections`, `_parseAnswers` 메서드 주석처리
- [ ] 테스트 성공 후 삭제 예정

### 3. flutter analyze
- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인

### 4. 테스트 (폰 빌드)
- [ ] flutter run -d RFCY40MNBLL
- [ ] 테스트 시나리오 실행
- [ ] 로그에서 `[TextParse]` 확인
- [ ] 성공 조건: 실제 교재 페이지 번호 정확히 인식

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정
- `[TextParse]` 로그로 필터링해서 확인

---

## ⚠️ 컨텍스트 관리

- 스몰스텝 2개 완료마다 `/compact` 실행
- 긴 파일은 view_range 사용
- 로그는 grep 필터링

---

## 완료 조건

1. ML Kit OCR → Claude API 텍스트 파싱 동작
2. 정규식 오인식 해결 (141페이지 → 실제 페이지 수)
3. flutter analyze 에러 0개
4. CP가 "테스트 종료" 입력
5. 보고서 작성 완료 (`ai_bridge/report/big_136_report.md`)
