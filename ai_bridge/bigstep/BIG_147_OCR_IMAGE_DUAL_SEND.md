# BIG_147: OCR + 이미지 동시 전송으로 레이아웃 인식 개선

> 생성일: 2026-01-04
> 목표: AI가 OCR 텍스트 + 원본 이미지를 함께 분석하여 다열 레이아웃 순서 문제 해결

---

## ⚠️ 작업 전 필수: 템플릿 읽기!

**Opus는 반드시 이 파일 읽기:**
```
ai_bridge/templates/BIGSTEP_TEMPLATE.md
```

---

## 배경

### 현재 문제
- 4열 레이아웃(A|B|C|D가 가로 배치)에서 OCR 순서가 뒤죽박죽
- ML Kit가 위→아래로 읽으면서 A-1, B-1, C-1, D-1을 섞어버림
- 결과: B 섹션이 통째로 A에 합쳐지는 등 누락 발생

### 해결 방향 (B 방식)
```
현재: 이미지 → OCR(텍스트만) → AI 파싱
변경: 이미지 → OCR(텍스트) → AI에게 (텍스트 + 이미지) 둘 다 전송
```

AI가 이미지 보면서 레이아웃 이해 + OCR 텍스트로 정확한 글자 확인

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일:
  1. `flutter_application_1/lib/shared/services/claude_api_service.dart`
  2. `flutter_application_1/lib/shared/services/answer_parser_service.dart`

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 4열 레이아웃 정답지에서 A/B/C/D 섹션이 정확히 분리됨
- 각 섹션 내 정답 개수가 원본과 일치 (누락 없음)

### 테스트 시나리오
```
1. 갤러리에서 정답지 이미지 선택 (4열 레이아웃)
2. OCR+AI 분석 완료 대기
3. 인식 결과 확인:
   - Page 11 기준
   - A 섹션: 4개 (angry, an artist, X, fantastic)
   - B 섹션: 4개 (well, happy, sweet, dark)
   - C 섹션: 4개 (bad, perfect, nice, rich)
   - D 섹션: 4개
4. 모든 섹션이 제대로 분리되어 있으면 성공
```

---

## 스몰스텝

### 1. claude_api_service.dart - parseOcrTextToAnswers 수정

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 메서드: `parseOcrTextToAnswers`

**찾을 코드 (시그니처):**
```dart
Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
```

**변경할 코드 (시그니처 + 이미지 파라미터 추가):**
```dart
/// ML Kit OCR로 추출한 텍스트를 정답 데이터로 파싱
/// BIG_147: OCR 텍스트 + 이미지 동시 전송 (레이아웃 이해)
Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText, {File? imageFile}) async {
  debugPrint('[Claude] ========== parseOcrTextToAnswers 시작 ==========');
  debugPrint('[Claude] OCR 텍스트 길이: ${ocrText.length}자');
  debugPrint('[Claude] 이미지 포함: ${imageFile != null}');
```

**메서드 본문에서 API 호출 부분 수정:**

찾을 코드 (content 구성 부분):
```dart
      'content': [
        {
          'type': 'text',
          'text': '''
다음은 교육용 학습 관리 시스템(LMS)에서 ML Kit OCR로 추출한 텍스트입니다.
```

변경할 코드:
```dart
      // ★ BIG_147: 이미지가 있으면 이미지 + 텍스트 동시 전송
      final List<Map<String, dynamic>> contentParts = [];
      
      // 이미지 추가 (있으면)
      if (imageFile != null) {
        final imgBytes = await imageFile.readAsBytes();
        final imgBase64 = base64Encode(imgBytes);
        final ext = imageFile.path.split('.').last.toLowerCase();
        final mediaType = switch (ext) {
          'png' => 'image/png',
          'jpg' || 'jpeg' => 'image/jpeg',
          _ => 'image/jpeg',
        };
        
        contentParts.add({
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': mediaType,
            'data': imgBase64,
          },
        });
      }

      // 프롬프트 (이미지 + OCR 함께 분석 요청)
      final prompt = '''
이미지와 OCR 텍스트를 함께 분석하세요.

★★★ 핵심 ★★★
1. 이미지를 보고 실제 레이아웃(A/B/C/D 섹션 배치)을 파악
2. OCR 텍스트는 순서가 뒤죽박죽일 수 있음
3. 이미지 기준으로 올바른 순서 결정
4. 모든 정답을 빠짐없이 추출!

<ocr_text>
$ocrText
</ocr_text>

JSON만 반환:
{
  "pages": [
    {
      "pageNumber": 9,
      "unitName": "Unit 01",
      "sections": {
        "A": ["1번정답", "2번정답", "3번정답", "4번정답"],
        "B": ["1번정답", "2번정답", "3번정답", "4번정답"],
        "C": ["1번정답", "2번정답", "3번정답", "4번정답"],
        "D": ["1번정답", "2번정답", "3번정답", "4번정답"]
      }
    }
  ]
}
''';

      contentParts.add({
        'type': 'text',
        'text': prompt,
      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': imageFile != null ? _model : _modelHaiku,  // 이미지 있으면 Sonnet
          'max_tokens': 4096,
          'messages': [
            {
              'role': 'user',
              'content': contentParts,
            },
          ],
        }),
      );
```

### 2. answer_parser_service.dart - extractAnswers 수정

- [ ] 파일: `flutter_application_1/lib/shared/services/answer_parser_service.dart`
- [ ] 위치: 줄 49 근처

**찾을 코드:**
```dart
    // 4. Claude API로 텍스트 → JSON 구조화
    try {
      final apiResults = await _claudeService.parseOcrTextToAnswers(fullText);
```

**변경할 코드:**
```dart
    // 4. Claude API로 텍스트 → JSON 구조화 (BIG_147: 이미지도 함께 전송)
    try {
      final apiResults = await _claudeService.parseOcrTextToAnswers(
        fullText,
        imageFile: imageFile,  // ★ BIG_147: 이미지 전달
      );
```

### 3. flutter analyze

- [ ] flutter analyze 실행
- [ ] 에러 0개 확인

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

### 4. 테스트

- [ ] flutter run -d RFCY40MNBLL
- [ ] 갤러리에서 4열 레이아웃 정답지 이미지 선택
- [ ] 인식 결과에서 A/B/C/D 각각 분리 확인
- [ ] 정답 개수 맞는지 확인 (원본 대조)

---

## 완료 조건

1. [ ] A/B/C/D 섹션이 제대로 분리됨
2. [ ] 정답 누락 없음 (Page 11 기준 각 섹션 4개씩)
3. [ ] flutter analyze 에러 0개
4. [ ] CP가 "테스트 종료" 입력
5. [ ] 보고서 작성: ai_bridge/report/big_147_report.md

---

## 롤백 방법

문제 발생 시:
```dart
// parseOcrTextToAnswers 시그니처를 원래대로
Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {

// 호출부도 원래대로
final apiResults = await _claudeService.parseOcrTextToAnswers(fullText);
```

---

## 참고: 비용 변화

| 항목 | 변경 전 | 변경 후 |
|------|--------|--------|
| 모델 | Haiku (텍스트만) | Sonnet (이미지+텍스트) |
| 토큰 | ~500 | ~2000 (이미지 포함) |
| 비용 | 저렴 | 약 4배 |

→ 정확도 향상을 위해 비용 증가 감수
