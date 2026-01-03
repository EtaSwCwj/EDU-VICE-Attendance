# BIG_125: PDF 정답지 인식 개선 (페이지 번호 + 구조화)

> 생성일: 2025-01-03
> 목표: PDF 정답지에서 교재 페이지 번호 정확히 추출 + 정답을 구조화된 형식으로 저장

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 로컬 코드 확인했나? (view 도구로 실제 파일 열어봄)
- [x] 수정할 파일/줄 번호 특정했나?
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나?
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?**

### 의존성 확인
- [x] 새로 import 필요한 패키지 있나? → 없음
- [x] schema/모델 변경 필요한가? → answerContents 형식 변경 (Map<int, String> → Map<int, Map<String, dynamic>>)

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
  - `flutter_application_1/lib/shared/services/claude_api_service.dart` (프롬프트 수정)

---

## 🎯 현재 문제점 (스크린샷 기반)

### 문제 1: Page 2로 인식됨
```
현재 프롬프트: "p. XX" 형식만 찾음
실제 PDF: 페이지 하단에 "19"만 인쇄됨
결과: "p. XX" 못 찾음 → PDF 순서(1, 2, 3...)로 번호 매김
```

### 문제 2: 정답이 쭉 나열됨
```
현재: "A 1 목적어 2 주어 3 보어 4 수식어 5 동사 6 목적어..."

필요:
A)
1. 목적어
2. 주어
3. 보어
4. 수식어
```

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. PDF 정답지의 **인쇄된 페이지 번호** 정확히 추출 (하단 숫자 포함)
2. 정답을 **섹션별 + 문제번호별** 구조화
3. 범위 초과 경고 없이 정상 저장

### 테스트 시나리오
```
1. Grammar Effect PDF 정답지 업로드
2. "인식 결과 확인" 다이얼로그에서:
   - Page 2 → Page 9 (실제 교재 페이지)
   - 정답이 구조화되어 표시됨:
     A)
     1. 목적어
     2. 주어
     ...
3. 저장 → 범위 초과 경고 없음
```

---

## 스몰스텝

### 1. extractPdfChunkText 프롬프트 수정

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 위치: `extractPdfChunkText` 메서드 (약 1050번째 줄)

**기존 프롬프트 (삭제):**
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

**새 프롬프트 (추가):**
```dart
'text': '''이 PDF는 영어 교재 정답지입니다.

★★★ 페이지 번호 찾는 방법 ★★★
1. "p. XX", "pp. XX", "p.XX" 형식 (예: p. 09, pp. 16-17)
2. "Practice p. XX", "Actual Test p. XX" 형식
3. 페이지 상단/하단에 인쇄된 숫자 (예: 하단 중앙에 "19")
4. Unit 제목 옆의 페이지 번호

위 순서대로 찾고, 없으면 다음 방법 시도.
페이지 번호는 반드시 교재에 인쇄된 번호를 사용하세요.

★★★ 정답 구조화 형식 ★★★
섹션(A, B, C, D...)별로 구분하고, 각 문제 번호마다 줄바꿈하세요.

예시 입력:
"Unit 01 A 1 목적어 2 주어 3 보어 B 1 동사 2 목적어"

예시 출력:
A)
1. 목적어
2. 주어
3. 보어

B)
1. 동사
2. 목적어

JSON 형식:
{
  "answers": [
    {
      "textbookPage": 9,
      "content": "Unit 01 문장을 이루는 요소\\n\\nA)\\n1. 목적어\\n2. 주어\\n3. 보어\\n4. 수식어\\n\\nB)\\n1. 동사\\n2. 목적어"
    }
  ]
}

규칙:
- textbookPage: 교재에 인쇄된 페이지 번호 (PDF 순서 아님!)
- content: 섹션별로 구분, 문제번호마다 줄바꿈
- 한 PDF 페이지에 여러 교재 페이지가 있으면 분리
- 영어 문장 정답은 그대로 유지''',
```

---

### 2. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -20
```

- [ ] 에러 0개 확인

---

### 3. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. Grammar Effect 책 선택
2. "정답지 등록" → "PDF 업로드"
3. 기존에 사용하던 정답지 PDF 선택
4. "인식 결과 확인" 다이얼로그에서:
   - Page 번호가 실제 교재 페이지인지 확인 (Page 2 → Page 9?)
   - 정답이 구조화되었는지 확인:
     ```
     A)
     1. 목적어
     2. 주어
     ...
     ```
5. "정확함 - 저장" 클릭
6. **범위 초과 경고가 안 뜨면 성공**

**콘솔 로그 확인:**
```bash
grep -i "청크\|textbookPage\|answers" [로그] | tail -30
```

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지 (토큰 초과)

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_125_report.md` 작성:

```markdown
# BIG_125 보고서

## 수정 내용
- extractPdfChunkText 프롬프트: O/X

## 테스트 결과
- 교재 페이지 번호 정확: O/X (Page 2 → Page ?)
- 정답 구조화: O/X
- 범위 초과 경고: O/X (없어야 성공)

## 콘솔 로그 (핵심만)
```
[ClaudeAPI] 청크에서 X개 교재 페이지 추출
```

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] extractPdfChunkText 프롬프트 수정
2. [ ] flutter analyze 에러 0개
3. [ ] 테스트 - 교재 페이지 번호 정확히 추출
4. [ ] 테스트 - 정답 구조화 (섹션별 + 문제번호별)
5. [ ] 테스트 - 범위 초과 경고 없음
6. [ ] **보고서 작성 완료** (ai_bridge/report/big_125_report.md)
7. [ ] **/compact 실행**
8. [ ] **CP에게 결과 보고**
9. [ ] CP가 "테스트 종료" 입력

---

## 참고: 실제 PDF 정답지 예시 (3번 이미지)

```
10 ④ → I would buy 가정법 과거: If+주어+동사의 과거형...
11 ⑤ → I wish tomorrow were 현재의 사실과 반대되는 것이므로...
12 현재의 사실과 반대되는 일에 대한 가정이므로 가정법 과거를 쓴다.
...
[17~18]
그랜트 파크에서 있었던 세계 음식 축제에는...
17 과거의 사실과 반대되는 일에 대한 가정이므로...
18 (B) 가정법 과거완료: If+주어+had p.p....

                                          19
```

→ 페이지 하단에 "19" 인쇄됨 = 교재 19페이지
