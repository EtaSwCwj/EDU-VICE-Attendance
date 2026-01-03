# BIG_143: OCR 로그 줄바꿈 치환 (로그 출력 안 되는 문제 수정)

> 생성일: 2026-01-04
> 목표: debugPrint가 줄바꿈 포함 문자열을 출력 못하는 문제 해결

---

## ⚠️ 필수: 템플릿 먼저 읽기!

```
ai_bridge/templates/BIGSTEP_TEMPLATE.md 읽고 시작할 것!
```

---

## 배경

### BIG_142 로그 결과 (실패)
```
01-04 00:32:43.161 [AnswerParser] OCR 앞 500자:
01-04 00:32:43.164 [AnswerParser] ...(중략)...    ← 내용 없음!

01-04 00:32:48.181 [Claude] 응답 전체:
01-04 00:32:48.183 [Claude] ================================    ← 내용 없음!
```

### 원인
`debugPrint()`가 **줄바꿈(`\n`) 포함 문자열**을 제대로 출력 못함
- Android Logcat에서 각 줄이 분리되거나 누락됨
- OCR 텍스트는 줄바꿈이 많아서 전체가 누락

### 해결책
줄바꿈을 **시각적 표시**로 치환: `\n` → `↵`

```dart
// 잘못된 방식
debugPrint(fullText.substring(0, 500));

// 올바른 방식
debugPrint(fullText.substring(0, 500).replaceAll('\n', '↵'));
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 수정 파일:
  1. `lib/shared/services/answer_parser_service.dart`
  2. `lib/shared/services/claude_api_service.dart`

---

## 🎯 기대 결과

### 수정 후 로그 예시
```
[AnswerParser] OCR 앞 500자: CHAPTER↵01.↵UNIT 04 5↵Practice↵UNIT 01 RA↵p. 09↵A 1 목적어 2 동사...
[Claude] 응답 전체: {"pages":[{"pageNumber":9,"unitName":"Unit 01","sections":{"A":["목적어","동사"]}}]}
```

### 테스트 시나리오
```
1. 앱 실행 → "전체 PDF 업로드" → PDF 선택
2. 로그 확인:
   - [AnswerParser] OCR 앞 500자: 실제 텍스트 보이는가?
   - [Claude] 응답 전체: JSON이 보이는가?
3. OCR 텍스트에서 "p. 09" 또는 "p.9" 패턴 확인
```

---

## 스몰스텝

### 1. answer_parser_service.dart - 줄바꿈 치환

- [ ] 파일: `lib/shared/services/answer_parser_service.dart`
- [ ] 위치: 약 36~47줄 (BIG_142에서 추가한 로그 부분)

**기존 코드 (이 부분 찾기):**
```dart
    // ★ BIG_142: OCR 텍스트 원본 상세 로그
    debugPrint('[AnswerParser] ========== OCR 텍스트 원본 ==========');
    debugPrint('[AnswerParser] OCR 총 길이: ${fullText.length}자');
    if (fullText.length > 1000) {
      debugPrint('[AnswerParser] OCR 앞 500자:');
      debugPrint(fullText.substring(0, 500));
      debugPrint('[AnswerParser] ...(중략)...');
      debugPrint('[AnswerParser] OCR 뒤 500자:');
      debugPrint(fullText.substring(fullText.length - 500));
    } else {
      debugPrint('[AnswerParser] OCR 전체:');
      debugPrint(fullText);
    }
    debugPrint('[AnswerParser] ========================================');
```

**새 코드로 교체:**
```dart
    // ★ BIG_143: OCR 텍스트 원본 상세 로그 (줄바꿈 치환)
    debugPrint('[AnswerParser] ========== OCR 텍스트 원본 ==========');
    debugPrint('[AnswerParser] OCR 총 길이: ${fullText.length}자');
    // 줄바꿈을 ↵로 치환해서 한 줄로 출력 (debugPrint 줄바꿈 문제 해결)
    final ocrForLog = fullText.replaceAll('\n', '↵');
    if (ocrForLog.length > 1000) {
      debugPrint('[AnswerParser] OCR 앞 500자: ${ocrForLog.substring(0, 500)}');
      debugPrint('[AnswerParser] OCR 뒤 500자: ${ocrForLog.substring(ocrForLog.length - 500)}');
    } else {
      debugPrint('[AnswerParser] OCR 전체: $ocrForLog');
    }
    debugPrint('[AnswerParser] ========================================');
```

### 2. claude_api_service.dart - parseOcrTextToAnswers 입력 로그 수정

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 위치: parseOcrTextToAnswers 함수 시작 부분 (약 913~922줄)

**기존 코드 (이 부분 찾기):**
```dart
  Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
    debugPrint('[Claude] ========== parseOcrTextToAnswers 시작 ==========');
    debugPrint('[Claude] OCR 텍스트 길이: ${ocrText.length}자');

    // ★ BIG_142: AI 입력 텍스트 상세 로그
    debugPrint('[Claude] AI 입력 OCR 앞 300자:');
    debugPrint(ocrText.substring(0, ocrText.length > 300 ? 300 : ocrText.length));
    if (ocrText.length > 300) {
      debugPrint('[Claude] ...(중략)...');
    }
```

**새 코드로 교체:**
```dart
  Future<List<Map<String, dynamic>>> parseOcrTextToAnswers(String ocrText) async {
    debugPrint('[Claude] ========== parseOcrTextToAnswers 시작 ==========');
    debugPrint('[Claude] OCR 텍스트 길이: ${ocrText.length}자');

    // ★ BIG_143: AI 입력 텍스트 상세 로그 (줄바꿈 치환)
    final inputForLog = ocrText.replaceAll('\n', '↵');
    final inputPreview = inputForLog.length > 500 ? inputForLog.substring(0, 500) : inputForLog;
    debugPrint('[Claude] AI 입력 OCR 앞 500자: $inputPreview');
```

### 3. claude_api_service.dart - parseOcrTextToAnswers 출력 로그 수정

- [ ] 파일: `lib/shared/services/claude_api_service.dart`  
- [ ] 위치: parseOcrTextToAnswers 함수 내, API 응답 후 (약 960~970줄)

**기존 코드 (이 부분 찾기):**
```dart
        debugPrint('[Claude] ========== AI 응답 ==========');
        debugPrint('[Claude] 응답 길이: ${content.length}자');
        // ★ BIG_142: AI 응답 전체 로그 (JSON이므로 전체 필요)
        debugPrint('[Claude] 응답 전체:');
        debugPrint(content);
        debugPrint('[Claude] ================================');
```

**새 코드로 교체:**
```dart
        debugPrint('[Claude] ========== AI 응답 ==========');
        debugPrint('[Claude] 응답 길이: ${content.length}자');
        // ★ BIG_143: AI 응답 전체 로그 (줄바꿈 치환)
        final responseForLog = content.replaceAll('\n', '↵');
        debugPrint('[Claude] 응답 전체: $responseForLog');
        debugPrint('[Claude] ================================');
```

### 4. flutter analyze

- [ ] `flutter analyze` 실행
- [ ] 에러 0개 확인

### 5. 테스트

- [ ] `flutter run -d RFCY40MNBLL`
- [ ] "전체 PDF 업로드" → Grammar Effect PDF 선택
- [ ] 로그 확인:
  ```bash
  adb logcat -d | grep -E "\[AnswerParser\]|\[Claude\]" | tail -50
  ```
- [ ] **확인 사항:**
  - `[AnswerParser] OCR 앞 500자:` 뒤에 실제 텍스트 있는가?
  - `[Claude] 응답 전체:` 뒤에 JSON 있는가?
  - OCR 텍스트에서 `p. 09` 또는 `p.9` 패턴 보이는가?

---

## 로그 분석 포인트

### 핵심 질문
OCR 텍스트에서 **페이지 번호가 어떻게 읽혔는가?**

| 경우 | OCR 텍스트 | AI 응답 pageNumber | 원인 |
|------|-----------|-------------------|------|
| A | `p. 09` 포함 | 9 | 정상 ✅ |
| B | `p. 09` 포함 | 16 | AI 파싱 오류 |
| C | `p. 09` 없음 | 16 | OCR 인식 오류 |
| D | `p.16` 포함 | 16 | PDF 이미지에 16이 실제로 있음 |

### 다음 단계 결정
- **경우 B**: AI 프롬프트 수정 필요
- **경우 C**: PDF 이미지 품질/해상도 확인 필요
- **경우 D**: PDF 첫 페이지가 실제로 p.16인지 확인 (표지 vs 내용)

---

## 완료 조건

1. 2개 파일 수정 완료
2. flutter analyze 에러 0개
3. 테스트 로그에서 OCR 텍스트 내용 확인 가능
4. 테스트 로그에서 AI 응답 JSON 확인 가능
5. 로그 저장: `ai_bridge/logs/big_143_test.log`
6. 보고서 작성: `ai_bridge/report/big_143_report.md`

---

## 보고서 필수 포함 사항

```markdown
# BIG_143 보고서

## OCR 텍스트 확인
- OCR 앞 500자 내용: [실제 로그 복사]
- 페이지 번호 패턴 발견: [p.??, p.?? 등]

## AI 응답 확인
- AI 응답 JSON: [실제 로그 복사]
- pageNumber 값: [9, 11, ... 또는 16, 17, ...]

## 분석 결론
- OCR에서 페이지 번호가 제대로 읽혔는가? [예/아니오]
- AI가 페이지 번호를 제대로 파싱했는가? [예/아니오]
- 문제 원인: [OCR 문제 / AI 파싱 문제 / PDF 이미지 문제]

## 다음 단계
- [구체적인 수정 방향]
```

---

## ⚠️ 컨텍스트 관리

- 스몰스텝 2개 완료 시마다 `/compact`
- 로그는 `tail -50`으로 제한
