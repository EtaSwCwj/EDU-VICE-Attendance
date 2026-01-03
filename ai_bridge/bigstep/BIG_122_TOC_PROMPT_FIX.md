# BIG_122: 목차 인식 프롬프트 수정 (플랫 구조)

> 생성일: 2025-01-03
> 목표: API가 플랫한 구조로 응답하도록 프롬프트 수정

---

## 현재 문제

**API 응답 (현재 - 중첩 구조):**
```json
{
  "entries": [
    {"unitName": "Chapter 01 문장의 형식", "entries": [
      {"unitName": "Unit 1...", "startPage": 10}
    ]}
  ]
}
```

**필요한 응답 (플랫 구조):**
```json
{
  "entries": [
    {"unitName": "Chapter 01 문장의 형식 - Unit 1...", "startPage": 10}
  ]
}
```

→ Chapter에 startPage 없어서 필터링됨

---

## 스몰스텝 (디버깅은 후임 담당)

### 1. claude_api_service.dart 프롬프트 수정

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] `extractTableOfContents` 메서드 찾기
- [ ] 프롬프트 수정:

**찾을 코드:**
```dart
'text': '''이 교재 목차 이미지를 분석해주세요.

각 단원/챕터의 이름과 페이지 번호를 추출해주세요.

JSON 형식으로만 반환:
{
  "entries": [
    {"unitName": "Unit 01 문장을 이루는 요소", "startPage": 8},
    {"unitName": "Unit 02 1형식, 2형식", "startPage": 10},
    {"unitName": "Unit 03 3형식, 4형식", "startPage": 12}
  ]
}

규칙:
- unitName: 목차에 보이는 단원/챕터 이름 그대로
- startPage: 페이지 번호 (숫자만)
- 페이지 범위(8-10)가 있으면 startPage만 추출
- 목차에 없는 내용은 추가하지 마세요''',
```

**변경할 코드:**
```dart
'text': '''이 교재 목차 이미지를 분석해주세요.

★★★ 중요 규칙 ★★★
1. 반드시 페이지 번호가 있는 항목만 추출하세요
2. Chapter/Unit 구분 없이 "페이지 번호가 있는 모든 항목"을 플랫하게 나열하세요
3. 중첩 구조(entries 안에 entries)는 절대 사용하지 마세요

JSON 형식으로만 반환:
{
  "entries": [
    {"unitName": "Unit 01 문장을 이루는 요소", "startPage": 8},
    {"unitName": "Unit 02 1형식, 2형식", "startPage": 10},
    {"unitName": "Unit 03 3형식, 4형식", "startPage": 12},
    {"unitName": "Grammar & Writing", "startPage": 16}
  ]
}

규칙:
- unitName: 목차에 보이는 이름 그대로 (Chapter, Unit, Lesson 등 포함)
- startPage: 반드시 숫자만! (페이지 번호가 없으면 해당 항목 제외)
- 페이지 범위(8-10)가 있으면 시작 페이지(8)만 추출
- 페이지 번호가 없는 항목은 절대 포함하지 마세요
- 중첩 구조 금지! entries 안에 또 entries 넣지 마세요''',
```

---

### 2. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -15
```

- [ ] 에러 0개 확인

---

### 3. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. Grammar Effect → 목차 펼치기 → "목차 페이지 촬영"
2. 목차 페이지 촬영
3. 콘솔 로그 확인:
   ```
   [TocCamera] API 응답: X개 항목 (0이 아니어야 함!)
   [TocCamera] entry: {unitName: Unit 01..., startPage: 8}
   [TocCamera] 최종 항목 수: X
   ```
4. 화면에 항목 표시 확인

**성공 기준:**
- API 응답 항목 수 > 0
- 화면에 Unit 01, Unit 02... 항목 표시됨

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지
- `grep -i "TocCamera\|ClaudeAPI" [로그] | tail -30` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_122_report.md` 작성:

```markdown
# BIG_122 보고서

## 수정 내용
- 프롬프트 수정: O/X

## 콘솔 로그 (핵심만)
```
[TocCamera] API 응답: X개 항목
[TocCamera] entry: {...}
[TocCamera] 최종 항목 수: X
```

## 테스트 결과
- API 응답 항목 수: [숫자]
- 목차 항목 화면 표시: O/X
- 인식된 항목 예시: [Unit명, 페이지]

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] 프롬프트 수정 (플랫 구조 강조)
2. [ ] flutter analyze 에러 0개
3. [ ] 테스트 - API 응답 항목 수 > 0
4. [ ] 테스트 - 화면에 목차 항목 표시
5. [ ] **보고서 작성 완료** (ai_bridge/report/big_122_report.md)
6. [ ] **/compact 실행**
7. [ ] **CP에게 결과 보고**
8. [ ] CP가 "테스트 종료" 입력
