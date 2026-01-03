# BIG_110: 정답지 교재 페이지 번호 인식 수정

> 생성일: 2025-01-01
> 목표: PDF 정답지에서 "교재 페이지 번호"를 정확히 인식

---

## 현재 문제

- PDF 1페이지 → "Practice p. 09" 인쇄됨 → `pageNumber: 1`로 저장 (틀림)
- 실제 필요한 것: `pageNumber: 9` (교재 페이지 번호)

## 해결책

프롬프트 수정: "교재 페이지 번호" 명확히 지시

---

## 스몰스텝

### 1. extractPdfChunkText 프롬프트 수정

- [ ] 파일: `lib/shared/services/claude_api_service.dart`
- [ ] 함수: `extractPdfChunkText`
- [ ] 찾기: `'type': 'text',` 다음의 `'text':` 부분
- [ ] 기존 프롬프트를 아래로 교체:

```dart
'text': '''이 PDF는 영어 교재 정답지입니다.

★★★ 중요 ★★★
각 페이지에서 "교재 페이지 번호"를 찾아주세요.
- "p. 09", "p. 11", "Practice p. 13" 같은 형식으로 인쇄되어 있습니다
- 이 번호가 교재의 몇 페이지 정답인지를 나타냅니다
- PDF 파일의 순서(1페이지, 2페이지)가 아닙니다!

JSON 형식:
{
  "pages": [
    {
      "pageNumber": 9,
      "content": "Unit 01 문장을 이루는 요소\\nA 1 목적어 2 동사..."
    },
    {
      "pageNumber": 11,
      "content": "Unit 02 1형식, 2형식\\nA 1 angry 2 an artist..."
    }
  ]
}

pageNumber: 정답지에 인쇄된 교재 페이지 번호 (p. XX에서 XX 숫자)
content: 해당 페이지의 정답 내용''',
```

### 2. flutter analyze

```bash
flutter analyze
```

### 3. 테스트

```bash
flutter run -d RFCY40MNBLL
```

- Grammar Effect → 정답지 등록 → PDF 업로드
- 인식 결과 확인:
  - Page 9, Page 11, Page 13... 으로 표시되어야 함 (Page 1, 2, 3이 아님)

### 4. 보고서

`ai_bridge/report/big_110_report.md`에:
```
인식된 페이지: [숫자들]
기대값: 9, 11, 13, 15... (교재 페이지 번호)
결과: 성공/실패
```

---

## 컨텍스트 관리

- 스몰스텝 1~2개 완료 후 /compact
- 파일 전체 읽기 금지
