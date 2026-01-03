# BIG_111: 정답지 다중 페이지 인식 프롬프트 수정

> 생성일: 2025-01-01
> 목표: PDF 1페이지 안의 여러 교재 페이지 정답을 분리 인식

---

## 현재 문제

PDF 1페이지에 여러 교재 페이지 정답이 있음:
- p.09 정답, p.11 정답, p.13 정답...
- 현재: 전부 합쳐서 하나로 인식
- 필요: 각 교재 페이지별로 분리

---

## 스몰스텝

### 1. extractPdfChunkText 프롬프트 수정

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 함수: `extractPdfChunkText` (파일 끝부분)
- [ ] `'text':` 부분의 프롬프트를 아래로 **전체 교체**:

```dart
'text': '''이 PDF는 영어 교재 정답지입니다.

★★★ 핵심 규칙 ★★★
"p. XX" 또는 "pp. XX-XX" 형식은 "교재 XX페이지의 정답"을 의미합니다.
한 PDF 페이지 안에 여러 개의 "p. XX"가 있을 수 있습니다.
각 "p. XX" 아래의 정답들을 해당 교재 페이지에 매칭해서 분리하세요.

예시:
PDF에 이렇게 보이면:
  Practice p. 09
  A 1 목적어 2 동사
  Practice p. 11
  A 1 angry 2 an artist

이렇게 분리:
{
  "answers": [
    {"textbookPage": 9, "content": "Practice\\nA 1 목적어 2 동사"},
    {"textbookPage": 11, "content": "Practice\\nA 1 angry 2 an artist"}
  ]
}

JSON 형식:
{
  "answers": [
    {"textbookPage": 숫자, "content": "해당 페이지 정답 내용"}
  ]
}

- textbookPage: "p. XX"에서 추출한 교재 페이지 번호
- content: 해당 페이지의 정답 (다음 "p. XX" 나오기 전까지)
- pp. 16-17 같은 범위는 16으로 저장''',
```

### 2. 응답 파싱 로직 수정

- [ ] 같은 함수에서 JSON 파싱 부분 찾기
- [ ] 기존: `parsed['pages']` 사용
- [ ] 변경: `parsed['answers']` 사용하고 필드명 매핑

```dart
// 기존 파싱 부분을 찾아서 교체:
final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
final answers = (parsed['answers'] as List<dynamic>)
    .map((e) => {
      'pageNumber': e['textbookPage'],
      'content': e['content'],
    })
    .toList();

debugPrint('[ClaudeAPI] 청크에서 ${answers.length}개 교재 페이지 추출');
return answers.cast<Map<String, dynamic>>();
```

### 3. flutter analyze

```bash
flutter analyze 2>&1 | tail -10
```

### 4. 테스트

```bash
flutter run -d RFCY40MNBLL
```

- Grammar Effect → 정답지 등록 → PDF 업로드
- 인식 결과 확인 다이얼로그:
  - Page 9, Page 11, Page 13, Page 15, Page 16... 으로 분리되어야 함

### 5. 보고서

`ai_bridge/report/big_111_report.md`에:
```
인식된 페이지: [숫자들]
기대값: 9, 11, 13, 15, 16 (교재 페이지 번호, 분리됨)
결과: 성공/실패
```

---

## 컨텍스트 관리

- 스몰스텝 1~2개 완료 후 /compact
- 파일 전체 읽기 금지
