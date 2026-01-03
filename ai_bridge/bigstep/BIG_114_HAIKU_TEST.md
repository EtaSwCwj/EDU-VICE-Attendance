# BIG_114: Haiku 모델 PDF 인식 재테스트

> 생성일: 2025-01-03
> 목표: Haiku 모델 PDF 정답지 인식 테스트 + 상세 로그 기록

---

## 현재 상황

- 크레딧 충전 완료 ($24.82)
- Haiku 모델 적용 완료
- 첫 테스트 결과: Page 2, 4, 6... (기대값: 9, 11, 13...)
- **이번 테스트 목표:** 상세 로그 확인하여 정확한 원인 파악

---

## 스몰스텝

### 1. 앱 빌드 및 실행

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL
```

- [ ] 빌드 성공 확인
- [ ] 앱 실행 확인

---

### 2. PDF 업로드 테스트

**테스트 순서:**
1. Grammar Effect 책 선택
2. 정답지 등록 버튼 클릭
3. **전체 PDF 업로드** 버튼 클릭
4. Grammar_Effect_2_Answer_Keys.pdf 선택
5. 처리 진행 상황 관찰

---

### 3. 콘솔 로그 확인 (중요!)

**반드시 기록할 로그:**

```
[ClaudeAPI] PDF 청크 텍스트 추출 시작
[ClaudeAPI] 청크 응답 길이: XXXX
[ClaudeAPI] 청크에서 X개 교재 페이지 추출
```

**특히 주목할 것:**
- Claude API 응답 원본 내용 (JSON)
- `textbookPage` 값이 뭘로 파싱되는지
- "p. 09" 같은 텍스트가 응답에 있는지

**로그 필터링 명령어 (PowerShell):**
```powershell
# 콘솔 출력에서 ClaudeAPI 관련만 보기
flutter run -d RFCY40MNBLL 2>&1 | Select-String "ClaudeAPI"
```

---

### 4. 인식 결과 다이얼로그 확인

**캡처/기록할 것:**
- 인식된 페이지 번호 전체 목록
- 각 페이지의 정답 내용 일부

**기대값:** Page 9, 11, 13, 15, 16, 17...
**실패 패턴:** Page 1, 2, 3... 또는 Page 2, 4, 6...

---

### 5. 로그에서 API 응답 원본 확인

Claude API 응답 JSON에서 실제로 어떤 값이 오는지 확인:

```
응답 예시 (기대):
{"answers": [{"textbookPage": 9, "content": "..."}, {"textbookPage": 11, ...}]}

응답 예시 (실패):
{"answers": [{"textbookPage": 1, "content": "..."}, {"textbookPage": 2, ...}]}
```

---

## ⚠️ 필수 규칙

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_114_report.md` 작성:

```markdown
# BIG_114 보고서 (재테스트)

## 테스트 환경
- 모델: claude-3-5-haiku-20241022
- PDF: Grammar_Effect_2_Answer_Keys.pdf (17페이지)
- 테스트 시간: YYYY-MM-DD HH:MM

## API 호출 결과
- API 호출 성공 여부: O/X
- 크레딧 에러 발생 여부: O/X

## 콘솔 로그 (핵심만)
```
[ClaudeAPI] 청크 응답 길이: XXX
[ClaudeAPI] 청크에서 X개 교재 페이지 추출
```

## Claude API 응답 원본 (일부)
```json
{"answers": [{"textbookPage": ??, "content": "..."}]}
```

## 인식 결과
- 인식된 페이지 번호: [숫자들 전체 나열]
- 기대값: 9, 11, 13, 15, 16, 17, 19, 21...
- 일치 여부: O/X

## 분석
- Haiku가 "p. 09" 텍스트를 제대로 읽었는가?
- textbookPage 값이 어떻게 파싱되었는가?
- 왜 2, 4, 6으로 인식되었는가? (원인 추정)

## 다음 단계 제안
- [필요한 추가 작업]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- 로그 전체 저장 금지 - 핵심만 보고서에 기록

---

## 완료 조건

1. [ ] 앱 빌드 및 실행 완료
2. [ ] PDF 업로드 테스트 실행
3. [ ] **콘솔 로그에서 API 응답 원본 확인** (핵심!)
4. [ ] 인식 결과 확인 (페이지 번호 전체 목록)
5. [ ] **보고서 작성 완료** (ai_bridge/report/big_114_report.md)
6. [ ] **CP에게 결과 보고**
7. [ ] CP가 "테스트 종료" 입력
