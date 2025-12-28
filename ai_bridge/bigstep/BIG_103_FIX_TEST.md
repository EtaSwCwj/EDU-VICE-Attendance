# BIG_103_FIX: 정답지/문제지 촬영 수정 테스트

> 생성일: 2024-12-28
> 목표: BIG_103 수정 사항 테스트 (전체 PDF 업로드, API 재시도, 검증 로직 완화)

---

## ⚠️ 작성 전 체크리스트

### 기본 확인
- [x] 로컬 코드 수정 완료 (Desktop Opus가 직접 수정함)
- [x] 수정 파일: answer_camera_page.dart, problem_camera_page.dart

### 테스트 환경
- [ ] 빌드 필요: ✅ (UI 확인 필요)
- [ ] 듀얼 빌드: ❌ (1개 계정으로 충분)

### 플로우 확인
- [x] 진입 경로: 내 책 → 책 상세 → 정답지 등록 / 문제 촬영

---

## ⚠️ 필수: Opus는 직접 작업 금지!

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## ⚠️ 컨텍스트 관리 (필수!)

```
1. 스몰스텝 2~3개 완료할 때마다 로그 저장
2. 로그 저장 후 /compact 실행 → 확인 묻지 말고 바로 다음 작업
3. 파일 생성은 Sonnet한테 1개씩 시키기 (한 번에 여러 파일 X)
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 폰 디바이스: RFCY40MNBLL
- 테스트 계정: maknae12@gmail.com

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 정답지 등록 시 "전체 PDF 업로드" 버튼 표시 (여러 Volume일 때)
- PDF 업로드 시 429 에러 나면 자동 재시도
- 문제 촬영 시 정답지 범위 검증으로 차단되지 않음

### CP 테스트 시나리오

**사전 조건:**
- 2권 이상 구성된 책이 등록되어 있어야 함 (본책+워크북 등)
- 정답지 PDF 파일 준비 (본책+워크북 합본)

---

**테스트 1: 전체 PDF 업로드 UI 확인**
```
1. 내 책 목록 → 2권 이상 구성된 책 선택
2. "정답지 등록" 클릭
3. 상단에 "전체 정답지 한번에 등록" 섹션 확인
   → 주황색 박스, "전체 PDF 업로드" 버튼 있어야 함
4. 아래에 "개별 Volume 등록" 섹션 있는지 확인
```

**테스트 2: 전체 PDF 업로드 동작**
```
1. "전체 PDF 업로드" 버튼 클릭
2. 본책+워크북 합본 PDF 선택
3. "전체 정답지 PDF 분석 중..." 메시지 표시
4. 분석 완료 → "X페이지 등록 완료" 스낵바
5. 상세 페이지로 돌아옴
```

**테스트 3: API 429 재시도 (옵션)**
```
1. PDF 업로드 연속 빠르게 시도
2. 429 에러 발생 시 "잠시 대기 중... (X초)" 메시지
3. 자동 재시도 후 성공
   (429 안 나면 패스 - 정상 동작)
```

**테스트 4: 문제 촬영 검증 완화**
```
1. "문제 촬영" 클릭
2. Volume 선택 (본책 선택)
3. "촬영 시작" → 아무 페이지 촬영
4. 페이지 인식됨
5. "Xp 촬영 완료" 녹색 스낵바
   → 이전처럼 "정답지 범위에 포함" 오류로 차단 안 됨
```

**테스트 5: 1권 구성 책**
```
1. 1권 구성 책 선택 → "정답지 등록"
2. "전체 PDF 업로드" 섹션 없어야 함 (1권이라 필요 없음)
3. 바로 개별 Volume 등록 UI만 표시
```

---

## 스몰스텝

### 1. flutter analyze

- [ ] Sonnet 지시:
```
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 실행하고 결과 알려줘
```
- [ ] 에러 0개 확인
- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_fix_step_01.log`

### 2. 폰 빌드

- [ ] Sonnet 지시:
```
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL 실행해줘
빌드 완료되면 "빌드 완료" 알려줘
```
- [ ] 빌드 성공 확인
- [ ] 완료 후 로그 저장: `ai_bridge/logs/big_103_fix_step_02.log`
- [ ] `/compact` 실행 후 바로 다음 진행

### 3. CP 테스트 대기

- [ ] CP에게 테스트 시나리오 안내
- [ ] 로그 모니터링하면서 대기
- [ ] CP 피드백 수집

### 4. CP "테스트 종료" 대기

- [ ] CP가 "테스트 종료" 입력 시 보고서 작성
- [ ] 보고서 파일: `ai_bridge/report/big_103_fix_report.md`

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_103_fix_step_XX.log

---

## 완료 조건

1. flutter analyze 에러 0개
2. 테스트 1~5 통과 (CP 확인)
3. CP가 "테스트 종료" 입력
4. 보고서 작성 완료 (ai_bridge/report/big_103_fix_report.md)
