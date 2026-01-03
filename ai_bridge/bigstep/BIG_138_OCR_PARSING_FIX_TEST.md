# BIG_138: OCR+AI 파싱 데이터 구조 수정 테스트

> 생성일: 2026-01-03
> 목표: parseOcrTextToAnswers() 반환값 구조 수정 후 정답 저장 테스트

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 로컬 코드 확인했나? (view 도구로 실제 파일 열어봄)
- [x] 수정할 파일/줄 번호 특정했나?
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나?
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?** (이미 debugPrint 있음)

### 테스트 환경
- [ ] 테스트 계정 리셋 필요한가? → 아니오 (정답지 테스트라 계정 무관)
- [ ] **테스트 계정 현재 상태 확인했나?** → 해당없음
- [x] 빌드 필요한가? → 예, 폰 빌드
- [ ] 듀얼 빌드 필요한가? → 아니오, 폰 단독

### 플로우 확인
- [x] **진입 경로 전체 확인했나?**
  - 나의 책 → 교재 선택 → 정답지 촬영 → 갤러리에서 선택
- [x] **영향 범위 확인했나?**
  - `claude_api_service.dart` → `answer_parser_service.dart` → `answer_camera_page.dart`

### 의존성 확인
- [x] 새로 import 필요한 패키지 있나? → 없음
- [x] schema/모델 변경 필요한가? → 없음

### 에러 케이스
- [x] 실패 시 사용자에게 어떻게 알려주나? → 스낵바 (기존 로직)
- [x] 네트워크 오류 처리 있나? → try-catch (기존 로직)

### 작업 연결
- [x] 이전 BIG에서 미완료된 것 있나? → BIG_137에서 데이터 구조 불일치 발견
- [x] 이 작업이 다음 작업의 선행 조건인가? → 예, 정답 DB 완성의 핵심

---

## ⚠️ 필수: 템플릿 읽고 작업할 것!

**Opus가 작업 전 반드시 읽어야 할 파일:**
```
C:\gitproject\EDU-VICE-Attendance\ai_bridge\templates\BIGSTEP_TEMPLATE.md
```

---

## 배경 (BIG_137 결과)

### 문제 발견
갤러리에서 이미지 선택 후 OCR+AI 파싱 결과:
- OCR 성공: ✅ (59블록, 800자)
- AI API 성공: ✅ (200 OK, 2869자 응답)
- **정답 저장 실패**: ❌ (`sections: {}`, `content: ""` 빈 값)

### 원인 분석
**데이터 구조 불일치!**

`parseOcrTextToAnswers()` 기존 반환:
```dart
{'pageNumber': 9, 'sectionName': 'A', 'answers': [...]}  // 섹션별 분리
```

`answer_parser_service.dart`가 기대:
```dart
{'pageNumber': 9, 'sections': {'A': [...], 'B': [...]}, 'content': '...'}  // 페이지별 통합
```

### 수정 내용 (완료됨)
- 파일: `lib/shared/services/claude_api_service.dart`
- 메서드: `parseOcrTextToAnswers()`
- 변경점:
  1. 모델: `_model` → `_modelHaiku` (비용 절감)
  2. 프롬프트: `{"answers": [{"number":1, "answer":"..."}]}` → `["답1", "답2"]` 단순 배열
  3. 반환값: `{sectionName, answers}` → `{sections: {A:[...], B:[...]}, content}` 통합

---

## 환경

- 프로젝트: `C:\gitproject\EDU-VICE-Attendance\flutter_application_1`
- 수정 파일: `lib/shared/services/claude_api_service.dart` (수정 완료)
- 테스트 기기: 폰 (RFCY40MNBLL)
- 테스트 이미지: 갤러리에 저장된 정답지 이미지 (309.png 등)

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. 갤러리에서 정답지 이미지 선택
2. ML Kit OCR로 텍스트 추출
3. Claude AI (Haiku)로 JSON 구조화
4. **정답 내용이 정상 저장됨** (빈 값 아님!)
5. 저장 확인 다이얼로그에 실제 정답 내용 표시

### 성공 기준
```
로그에서 확인:
[Claude] p.9 섹션 A: 4개 정답    ← 0개가 아님!
[Claude] p.9 추가: [A, B, C, D] 섹션
[AnswerParser] AI 파싱 완료: 3개 페이지  ← 빈 배열 아님!

다이얼로그에서 확인:
- "p.9: A) 1. 목적어 2. 동사..." 실제 내용 표시
```

### 테스트 시나리오
```
1. 앱 실행 → 나의 책 탭
2. 테스트용 교재 선택 (또는 새 교재 생성)
3. 정답지 촬영 버튼 탭
4. "갤러리에서 선택" 버튼 탭  ← 핵심!
5. 정답지 이미지 선택 (p.9, p.11, p.13 있는 이미지)
6. AI 분석 진행 확인
7. 저장 확인 다이얼로그 → 정답 내용 확인!
8. "저장" 탭 → 정상 저장 확인
```

---

## 스몰스텝

### 1. flutter analyze
- [ ] 에러/경고 확인:
```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```
- [ ] 에러 0개 확인

### 2. 폰 빌드 & 실행
- [ ] 빌드 명령:
```bash
flutter run -d RFCY40MNBLL
```
- [ ] 빌드 성공 확인

### 3. 테스트 실행

#### 3-1. 갤러리 선택 테스트
- [ ] 앱에서 나의 책 탭 이동
- [ ] 테스트용 교재 선택 (없으면 생성)
- [ ] 정답지 촬영 버튼 탭
- [ ] **"갤러리에서 선택" (indigo 버튼)** 탭
- [ ] 정답지 이미지 선택

#### 3-2. 로그 확인 (핵심!)
- [ ] OCR 성공 확인:
```
[MlKitOcr] 분석 완료: XX개 블록
[AnswerParser] OCR 텍스트 길이: XXX
```

- [ ] AI 파싱 성공 확인:
```
[Claude] parseOcrTextToAnswers 시작
[Claude] 응답 길이: XXXX
[Claude] 응답 앞 300자: {"pages":[...   ← JSON 구조 확인
```

- [ ] **섹션 데이터 확인 (핵심!)**:
```
[Claude] p.9 섹션 A: 4개 정답    ← 0이 아니어야 함!
[Claude] p.9 섹션 B: 4개 정답
[Claude] p.9 추가: [A, B, C, D] 섹션
```

- [ ] **페이지 파싱 완료 확인**:
```
[Claude] 총 3개 페이지 파싱 완료  ← 0이 아니어야 함!
[AnswerParser] AI 파싱 완료: 3개 페이지
```

#### 3-3. UI 확인
- [ ] 저장 확인 다이얼로그 표시됨
- [ ] **다이얼로그에 실제 정답 내용 표시됨** (빈 값 아님!)
  - 예: "p.9: A) 1. 목적어 2. 동사 3. 수식어 4. 보어"
- [ ] "저장" 버튼 탭
- [ ] 저장 성공 메시지 확인

---

## 로그 저장

테스트 완료 후:
```
ai_bridge/logs/big_138_test.log
```

**저장할 내용 (핵심 로그만!):**
1. `[Claude]` 태그 로그 전체
2. `[AnswerParser]` 태그 로그 전체
3. `[DEBUG]` 태그 로그 (있으면)

---

## 완료 조건

1. flutter analyze 에러 0개
2. 갤러리 선택 → OCR → AI 파싱 → 정답 저장 성공
3. **로그에서 `섹션 X: N개 정답`에서 N > 0**
4. **다이얼로그에 실제 정답 내용 표시 (빈 값 아님)**
5. CP가 "테스트 종료" 입력
6. 보고서 작성: `ai_bridge/report/big_138_report.md`

---

## ⚠️ 실패 시 체크포인트

### Case 1: `섹션 X: 0개 정답` 로그
→ AI 응답 JSON 구조 확인 필요
→ `[Claude] 응답 앞 300자` 로그에서 실제 JSON 형태 확인

### Case 2: `JSON 파싱 실패` 에러
→ AI 응답이 JSON이 아닌 텍스트 반환
→ 프롬프트 수정 필요

### Case 3: `API 에러: 400/429`
→ 400: 요청 형식 오류 (토큰 초과 등)
→ 429: Rate limit (잠시 후 재시도)

---

## ⚠️ Opus 필수 확인사항

1. **템플릿 먼저 읽기**: `ai_bridge/templates/BIGSTEP_TEMPLATE.md`
2. **로그 직접 확인**: 보고서만 읽지 말고 실제 로그 파일 확인
3. **컨텍스트 관리**: 스몰스텝 1~2개 완료 시 `/compact`
