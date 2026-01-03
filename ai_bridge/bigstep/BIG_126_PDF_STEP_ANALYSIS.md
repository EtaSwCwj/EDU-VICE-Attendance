# BIG_126: PDF 정답지 인식 - 단계별 분석 + 목차 교차 검증

> 생성일: 2025-01-03
> 목표: PDF 정답지를 단계별로 분석하고 목차와 교차 검증하여 정확한 페이지 번호/정답 추출

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 로컬 코드 확인했나? (view 도구로 실제 파일 열어봄)
- [x] 수정할 파일/줄 번호 특정했나?
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나?
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?**

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### 템플릿 먼저 읽기!
```
ai_bridge/templates/BIGSTEP_TEMPLATE.md 읽은 후 작업 시작!
```

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일:
  - `flutter_application_1/lib/features/my_books/pages/answer_camera_page.dart`
  - `flutter_application_1/lib/shared/services/claude_api_service.dart`

---

## 🔴 현재 문제점

### 1. 한 번에 모든 걸 시킴 → Claude 혼란
```dart
// 현재: 프롬프트 하나에 모든 요구사항
"페이지 번호 찾아 + 정답 추출해 + 구조화해..."
→ Claude가 JSON 대신 대화체로 응답 → 파싱 실패
```

### 2. 목차 데이터 활용 안 함
```dart
// _book.tableOfContents 있는데 API에 전달 안 함
// 목차: Unit 01 = p.8~10, Unit 02 = p.10~12...
// 이걸 활용하면 교차 검증 가능
```

### 3. 열 구조 무시
```
실제 PDF: 2열 구조 (왼쪽 Unit 01~03, 오른쪽 Unit 04 + Grammar)
현재: 순서 무시하고 막 읽음 → 정답 뒤섞임
```

---

## 🎯 CP 피드백 기반 해결 방향

### 단계별 분석 (5단계)
```
Step 1: 열 구조 파악 (1열? 2열?)
        → 로그: "정답지가 2열 구조입니다"

Step 2: 왼쪽 위부터 한 열씩 해석
        → 로그: "왼쪽 열 분석 시작"

Step 3: 목차와 교차 검증
        → 로그: "Unit 01 문장을 이루는 요소 발견, 
                 목차 DB: p.8~10 범위에서 페이지 찾는 중..."

Step 4: 페이지 번호 검증
        → 로그: "p.09 발견, 목차 범위(8~10) 내 일치 ✓"

Step 5: 정답 구조화
        → 로그: "A섹션 4문제, B섹션 4문제 추출 완료"
```

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. 콘솔에 5단계 분석 로그 출력
2. 정확한 교재 페이지 번호 (Page 2 → Page 9)
3. 정답이 섹션별로 정확히 분리 (A: 1~4, B: 1~4)
4. 범위 초과 경고 없음

### 테스트 시나리오
```
1. Grammar Effect PDF 업로드
2. 콘솔 로그 확인:
   - "[PDF분석] Step 1: 2열 구조 감지"
   - "[PDF분석] Step 2: 왼쪽 열 분석 - Unit 01 발견"
   - "[PDF분석] Step 3: 목차 교차검증 - Unit 01 (p.8~10)"
   - "[PDF분석] Step 4: 페이지 번호 p.09 → 목차 범위 내 ✓"
   - "[PDF분석] Step 5: A섹션 4문제, B섹션 4문제"
3. "인식 결과 확인" 다이얼로그:
   - Page 9 (Page 2 아님!)
   - A) 1~4번, B) 1~4번 정확
```

---

## 스몰스텝

### 1. ClaudeApiService에 새 메서드 추가 (단계별 분석)

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 위치: 파일 끝 (extractTableOfContents 다음)

**새 메서드 추가:**
```dart
/// PDF 정답지 단계별 분석 (목차 교차 검증)
/// 
/// Step 1: 열 구조 파악
/// Step 2: 왼쪽 위부터 순서대로 읽기
/// Step 3: 목차와 교차 검증
/// Step 4: 페이지 번호 검증
/// Step 5: 정답 구조화
Future<List<Map<String, dynamic>>> extractPdfWithTocValidation(
  File pdfChunk,
  List<Map<String, dynamic>> tocEntries,  // 목차 데이터
) async {
  final apiKey = await _getApiKey();
  if (apiKey == null) {
    throw Exception('API 키가 설정되지 않았습니다');
  }

  final bytes = await pdfChunk.readAsBytes();
  final base64Data = base64Encode(bytes);

  // 목차 정보를 프롬프트용 문자열로 변환
  final tocInfo = tocEntries.map((e) {
    final name = e['unitName'] ?? '';
    final start = e['startPage'] ?? 0;
    final end = e['endPage'] ?? start;
    return '$name: p.$start~$end';
  }).join('\n');

  debugPrint('[PDF분석] ========== 단계별 분석 시작 ==========');
  debugPrint('[PDF분석] 목차 정보:\n$tocInfo');

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
        'max_tokens': 4000,
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

★★★ 목차 정보 (교차 검증용) ★★★
$tocInfo

★★★ 단계별 분석 (반드시 순서대로!) ★★★

Step 1: 열 구조 파악
- PDF가 1열인지 2열인지 확인
- 2열이면 왼쪽/오른쪽 구분

Step 2: 왼쪽 위부터 순서대로 읽기
- 2열이면: 왼쪽 열 전체 → 오른쪽 열 전체
- 1열이면: 위에서 아래로

Step 3: Unit 제목으로 목차 매칭
- "Unit 01 문장을 이루는 요소" 발견 → 목차에서 찾기
- 목차에 없으면 "Grammar & Writing" 등으로 검색

Step 4: 페이지 번호 검증
- "p. 09" 또는 하단 숫자 "9" 찾기
- 찾은 페이지가 목차 범위(예: 8~10) 안에 있는지 확인
- 범위 밖이면 경고 표시

Step 5: 정답 구조화
- 섹션(A, B, C, D)별로 분리
- 각 문제 번호와 정답 추출

JSON 형식으로만 반환:
{
  "analysis": {
    "columnLayout": 1 또는 2,
    "readingOrder": ["왼쪽 열", "오른쪽 열"] 또는 ["단일 열"]
  },
  "pages": [
    {
      "unitName": "Unit 01 문장을 이루는 요소",
      "tocMatched": true,
      "pageNumber": 9,
      "pageValidation": "목차 범위(8~10) 내 일치",
      "sections": {
        "A": ["목적어", "동사", "수식어", "보어"],
        "B": ["wrote", "My teacher", "great", "dinner"],
        "C": ["주어, 동사, 보어", "주어, 동사, 목적어, 수식어", "주어, 동사, 보어", "주어, 동사, 목적어, 수식어"],
        "D": ["Tom and I go to the same school.", "She was writing in a diary.", "It is very surprising news.", "We saw that movie at the theater."]
      }
    }
  ]
}

주의:
- JSON만 반환! 다른 텍스트 금지!
- 각 섹션의 정답 개수 정확히 (A가 4개면 4개만)
- pageNumber는 교재에 인쇄된 번호 (PDF 순서 아님!)''',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'] as String;
      debugPrint('[PDF분석] API 응답 길이: ${content.length}');

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
        
        // 분석 결과 로그
        final analysis = parsed['analysis'] as Map<String, dynamic>?;
        if (analysis != null) {
          debugPrint('[PDF분석] Step 1: ${analysis['columnLayout']}열 구조 감지');
          debugPrint('[PDF분석] Step 2: 읽기 순서 - ${analysis['readingOrder']}');
        }

        final pages = parsed['pages'] as List<dynamic>? ?? [];
        final results = <Map<String, dynamic>>[];
        
        for (final page in pages) {
          final unitName = page['unitName'] ?? '';
          final tocMatched = page['tocMatched'] ?? false;
          final pageNum = page['pageNumber'];
          final validation = page['pageValidation'] ?? '';
          final sections = page['sections'] as Map<String, dynamic>? ?? {};

          debugPrint('[PDF분석] Step 3: $unitName ${tocMatched ? "목차 매칭 ✓" : "목차 매칭 ✗"}');
          debugPrint('[PDF분석] Step 4: p.$pageNum - $validation');
          
          // 섹션별 문제 수 로그
          final sectionInfo = sections.entries
              .map((e) => '${e.key}섹션 ${(e.value as List).length}문제')
              .join(', ');
          debugPrint('[PDF분석] Step 5: $sectionInfo');

          // 정답 내용을 구조화된 문자열로 변환
          final contentBuffer = StringBuffer();
          contentBuffer.writeln(unitName);
          contentBuffer.writeln();
          
          for (final entry in sections.entries) {
            final sectionName = entry.key;
            final answers = entry.value as List<dynamic>;
            contentBuffer.writeln('$sectionName)');
            for (int i = 0; i < answers.length; i++) {
              contentBuffer.writeln('${i + 1}. ${answers[i]}');
            }
            contentBuffer.writeln();
          }

          results.add({
            'pageNumber': pageNum,
            'content': contentBuffer.toString().trim(),
            'unitName': unitName,
            'tocMatched': tocMatched,
          });
        }

        debugPrint('[PDF분석] ========== 분석 완료: ${results.length}페이지 ==========');
        return results;

      } catch (e) {
        debugPrint('[PDF분석] JSON 파싱 실패: $e');
        debugPrint('[PDF분석] 원본 응답 앞 500자: ${content.substring(0, content.length > 500 ? 500 : content.length)}');
        return [];
      }
    } else if (response.statusCode == 429) {
      debugPrint('[PDF분석] Rate limit 초과 (429)');
      throw Exception('RATE_LIMIT');
    } else {
      debugPrint('[PDF분석] API 에러: ${response.statusCode}');
      throw Exception('API 호출 실패: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('[PDF분석] 예외: $e');
    rethrow;
  }
}
```

---

### 2. answer_camera_page.dart에서 목차 전달

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/answer_camera_page.dart`
- [ ] 위치: `_processChunkWithRetry` 메서드 (약 170번째 줄)

**기존 코드 (삭제):**
```dart
Future<List<Map<String, dynamic>>> _processChunkWithRetry(File chunk, {int maxRetries = 3}) async {
  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await _claudeService.extractPdfChunkText(chunk);
```

**새 코드 (추가):**
```dart
Future<List<Map<String, dynamic>>> _processChunkWithRetry(File chunk, {int maxRetries = 3}) async {
  // 목차 데이터 준비
  final tocEntries = _book?.tableOfContents.map((e) => {
    'unitName': e.unitName,
    'startPage': e.startPage,
    'endPage': e.endPage ?? e.startPage,
  }).toList() ?? [];
  
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
```

---

### 3. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -20
```

- [ ] 에러 0개 확인

---

### 4. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 전 확인:**
- Grammar Effect 책에 **목차가 등록되어 있어야 함**
- 목차 없으면 먼저 목차 촬영부터!

**테스트 순서:**
1. Grammar Effect 책 선택
2. 목차 섹션 확인 (33개 항목 있어야 함)
3. "정답지 등록" → "PDF 업로드"
4. 콘솔 로그 확인:
   ```
   [AnswerCamera] 목차 33개 항목으로 교차 검증 시작
   [PDF분석] ========== 단계별 분석 시작 ==========
   [PDF분석] 목차 정보:
   Unit 01 문장을 이루는 요소: p.8~10
   Unit 02 1형식, 2형식: p.10~12
   ...
   [PDF분석] Step 1: 2열 구조 감지
   [PDF분석] Step 2: 읽기 순서 - [왼쪽 열, 오른쪽 열]
   [PDF분석] Step 3: Unit 01 문장을 이루는 요소 목차 매칭 ✓
   [PDF분석] Step 4: p.9 - 목차 범위(8~10) 내 일치
   [PDF분석] Step 5: A섹션 4문제, B섹션 4문제, C섹션 4문제, D섹션 4문제
   ```
5. "인식 결과 확인" 다이얼로그:
   - Page 9 (Page 2 아님!)
   - 정답이 구조화됨:
     ```
     Unit 01 문장을 이루는 요소
     
     A)
     1. 목적어
     2. 동사
     3. 수식어
     4. 보어
     
     B)
     1. wrote
     2. My teacher
     3. great
     4. dinner
     ```

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지 (토큰 초과)
- `grep -i "PDF분석\|AnswerCamera" [로그] | tail -50` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_126_report.md` 작성:

```markdown
# BIG_126 보고서

## 수정 내용
- extractPdfWithTocValidation 메서드 추가: O/X
- answer_camera_page 목차 전달: O/X

## 테스트 결과
- 5단계 로그 출력: O/X
- 열 구조 감지: O/X (1열? 2열?)
- 목차 교차 검증: O/X
- 페이지 번호 정확: O/X (Page 2 → Page ?)
- 정답 구조화: O/X (섹션별 분리)
- 범위 초과 경고: O/X (없어야 성공)

## 콘솔 로그 (핵심만)
```
[PDF분석] Step 1: X열 구조 감지
[PDF분석] Step 3: Unit XX 목차 매칭 ✓/✗
[PDF분석] Step 4: p.XX - 검증 결과
[PDF분석] Step 5: A섹션 X문제, B섹션 X문제...
```

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] extractPdfWithTocValidation 메서드 추가
2. [ ] answer_camera_page에서 목차 전달
3. [ ] flutter analyze 에러 0개
4. [ ] 테스트 - 5단계 로그 출력 확인
5. [ ] 테스트 - 열 구조 감지 (2열)
6. [ ] 테스트 - 목차 교차 검증 동작
7. [ ] 테스트 - 페이지 번호 정확 (Page 9)
8. [ ] 테스트 - 정답 구조화 (A: 1~4, B: 1~4...)
9. [ ] **보고서 작성 완료** (ai_bridge/report/big_126_report.md)
10. [ ] **/compact 실행**
11. [ ] **CP에게 결과 보고**
12. [ ] CP가 "테스트 종료" 입력

---

## 참고: 실제 PDF 정답지 구조 (2번 이미지)

```
┌─────────────────────┬─────────────────────┐
│ CHAPTER 01 문장의 형식 │ UNIT 04 5형식      │
│                     │ Practice    p. 15   │
│ UNIT 01 문장을 이루는 요소│                     │
│ Practice    p. 09   │ A 1 to be  2 healthy│
│                     │ B 1 difficult       │
│ A 1 목적어  2 동사     │ C 1 to go up       │
│   3 수식어  4 보어     │ D 1 found the show │
│ B 1 wrote           │                     │
│   2 My teacher      │─────────────────────│
│   3 great           │ Grammar & Writing   │
│   4 dinner          │         pp. 16-17   │
│ C 1 주어, 동사, 보어   │                     │
│ ...                 │ Task 1              │
│                     │ 1 They are jogging  │
│ UNIT 02 1형식, 2형식  │ 2 This drink tastes │
│ Practice    p. 11   │ ...                 │
│                     │                     │
│ A 1 angry  2 an artist│                    │
│ ...                 │                  1  │
└─────────────────────┴─────────────────────┘

→ 2열 구조
→ 왼쪽: Unit 01, 02, 03
→ 오른쪽: Unit 04, Grammar & Writing
→ 하단 중앙에 "1" = PDF 1페이지 (교재 페이지 아님!)
→ "p. 09", "p. 11", "p. 13", "p. 15", "pp. 16-17" = 교재 페이지
```
