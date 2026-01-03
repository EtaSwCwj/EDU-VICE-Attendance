# BIG_131: 중복 페이지 방지 + 타입 안전 처리 테스트

> 생성일: 2026-01-03
> 목표: p.22 4번 중복 문제 해결 + JSON 파싱 에러 방지

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 로컬 코드 확인했나? → claude_api_service.dart 수정 완료
- [x] 수정할 파일/줄 번호 특정했나? → 이미 수정 완료, 테스트만 필요
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?** → 중복/타입오류 로그 추가됨

### 테스트 환경
- [x] 테스트 계정 리셋 필요한가? → 불필요
- [x] 빌드 필요한가? → 예 (코드 수정됨)
- [x] 듀얼 빌드 필요한가? → 불필요 (폰 단독)

### 플로우 확인
- [x] **진입 경로 전체 확인했나?** → 내 책 → Grammar Effect → 정답지 등록 → PDF 업로드
- [x] **영향 범위 확인했나?** → extractPdfWithTocValidation만 영향

---

## ⚠️ 사이드 이펙트 체크리스트 (필수!)

### 테스트 시 로그 분석
- [ ] 예상과 다른 값 나오면 즉시 원인 추적
- [ ] "왜 이 값이 나왔지?" 질문하고 답 찾기
- [ ] 이상한 로그는 보고서에 "문제점"으로 기록
- [ ] **중복 로그가 제대로 출력되는지 확인**
- [ ] **타입 오류 로그가 출력되는지 확인**

---

## ⚠️ 필수: 템플릿 먼저 읽기!

**작업 전에 반드시 ai_bridge/templates/BIGSTEP_TEMPLATE.md 읽고 체크리스트 확인할 것!**

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: claude_api_service.dart (이미 수정 완료)
- 테스트 계정: maknae12@gmail.com

---

## 🎯 기대 결과 & 테스트 시나리오

### BIG_130에서 발견된 문제점

**1. page 22가 4번 중복 (심각)**
```
청크 3에서:
p.22 → Unit 01
p.22 → Unit 03  (중복!)
p.22 → Unit 02  (중복!)
p.22 → Unit 04  (중복!)
```

**2. JSON 파싱 에러 (청크 4)**
```
type '_Map<String, dynamic>' is not a subtype of type 'List<dynamic>'
```

### BIG_131 수정 내용

**1. 중복 페이지 방지**
```dart
final Set<int> processedPages = {};

if (pageNum != null && processedPages.contains(pageNum)) {
  debugPrint('[PDF분석] ⚠️ 중복 페이지 건너뜀: p.$pageNum (이미 처리됨)');
  continue;
}

// 통과 후 등록
processedPages.add(pageNum);
```

**2. sections 타입 안전 처리**
```dart
if (rawSections is Map<String, dynamic>) {
  sections = rawSections;
} else if (rawSections is Map) {
  sections = Map<String, dynamic>.from(rawSections);
}

if (rawAnswers is! List) {
  debugPrint('[PDF분석] ⚠️ 섹션 정답이 List가 아님');
  continue;
}
```

### 기대 로그

**중복 방지 로그:**
```
[PDF분석] ✓ 교차 검증 통과: p.22 (목차: ...)
[PDF분석] ⚠️ 중복 페이지 건너뜀: p.22 (이미 처리됨)
[PDF분석] ⚠️ 중복 페이지 건너뜀: p.22 (이미 처리됨)
[PDF분석] ⚠️ 중복 페이지 건너뜀: p.22 (이미 처리됨)
```

**타입 오류 로그 (발생 시):**
```
[PDF분석] ⚠️ sections 타입 오류: Null
[PDF분석] ⚠️ A 섹션 정답이 List가 아님: String
```

### 테스트 시나리오
```
1. Grammar Effect 책 선택 → 정답지 등록 화면 진입
2. 기존 정답지 초기화 (있으면)
3. PDF 업로드 버튼 클릭 → 정답지 PDF 선택
4. 콘솔 로그에서 확인:
   - "⚠️ 중복 페이지 건너뜀" 로그 (p.22가 3번 건너뛰어야 함)
   - JSON 파싱 에러 없음 (타입 안전 처리로 방지)
5. "인식 결과 확인" 다이얼로그 → 중복 없이 유효한 페이지만 표시
```

---

## 스몰스텝 (진행 시 체크박스 업데이트!)

### 1. flutter analyze
- [ ] `cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1`
- [ ] `flutter analyze 2>&1 | tail -20`
- [ ] 에러 0개 확인

### 2. 폰 빌드 및 테스트
- [ ] `flutter run -d RFCY40MNBLL`
- [ ] 앱 실행 후 maknae12@gmail.com 로그인
- [ ] 내 책 → Grammar Effect 선택
- [ ] 정답지 등록 화면 진입
- [ ] (기존 정답지 있으면) 초기화 버튼 클릭

### 3. PDF 업로드 테스트
- [ ] PDF 업로드 버튼 클릭
- [ ] Grammar Effect 정답지 PDF 선택
- [ ] 콘솔 로그 관찰

### 4. 로그 확인 (핵심!)

**A. 중복 방지 로그 확인 (가장 중요!):**
```
[PDF분석] ⚠️ 중복 페이지 건너뜀: p.22 (이미 처리됨)
```
- [ ] p.22 중복 건너뜀 로그가 **3번** 나타남 (4번 중 첫 번째만 통과, 나머지 3번 건너뜀)
- [ ] 다른 페이지도 중복 건너뜀 로그 확인

**B. 타입 안전 처리 확인:**
```
[PDF분석] ⚠️ sections 타입 오류: ...
[PDF분석] ⚠️ 섹션 정답이 List가 아님: ...
```
- [ ] JSON 파싱 에러(`is not a subtype of type`) 발생 **안 함**
- [ ] 타입 오류 시 안전하게 건너뜀 (크래시 없음)

**C. 최종 결과:**
```
[PDF분석] ========== 분석 완료: N페이지 ==========
```
- [ ] 중복 제거 후 유효 페이지 수 확인
- [ ] BIG_130 결과(12페이지, 중복 포함)보다 중복 제거된 결과

### 5. UI 확인
- [ ] "인식 결과 확인 (N페이지)" 다이얼로그 표시됨
- [ ] **중복 없이** 각 페이지가 1번씩만 표시됨
- [ ] 각 페이지 내용 정상 표시

### 6. Before/After 비교

| 항목 | BIG_130 (Before) | BIG_131 (After) | 예상 |
|------|------------------|-----------------|------|
| p.22 출현 횟수 | 4번 | 1번 | ✓ |
| JSON 파싱 에러 | 발생 | 미발생 | ✓ |
| 유효 페이지 | 8개 (중복 제외) | 8개+ | ✓ |
| 크래시 | 없음 | 없음 | ✓ |

- [ ] 위 표 기준으로 개선 확인

### 7. 로그 저장 (필수!)
- [ ] 콘솔에서 `[PDF분석]` 관련 로그 복사
- [ ] `ai_bridge/logs/big_131_test.log` 파일에 저장
- [ ] **특히 "중복 페이지 건너뜀" 로그 반드시 포함**

### 8. 보고서 작성
- [ ] `ai_bridge/report/big_131_report.md` 작성
- [ ] 포함 내용:
  - 중복 건너뜀 로그 횟수
  - 타입 오류 발생 여부
  - Before/After 비교 표
  - 최종 유효 페이지 수
  - 성공/실패 판정

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정
- **"중복 페이지 건너뜀" 로그가 출력되면 수정 성공**
- **JSON 파싱 에러 없으면 타입 처리 성공**

---

## ⚠️ Opus 필수: 로그 직접 확인!

**보고서만 읽지 말고, 로그 파일도 직접 확인할 것!**

```
확인할 로그:
- ai_bridge/logs/big_131_test.log
- Flutter 콘솔의 [PDF분석] 로그
```

**로그에서 확인할 것:**
1. `⚠️ 중복 페이지 건너뜀` 로그가 있나?
2. `⚠️ sections 타입 오류` 또는 `⚠️ 섹션 정답이 List가 아님` 로그가 있나?
3. `is not a subtype of type` 에러가 **없어야** 함
4. 최종 분석 완료 페이지 수

---

## ⚠️ 컨텍스트 관리 (CLI 오버플로우 방지)

### 필수 규칙
1. **스몰스텝 1~2개 완료할 때마다 /compact 실행**
2. **로그는 필터링** - `grep "[PDF분석]"` 사용

---

## 완료 조건

1. flutter analyze 에러 0개
2. **"중복 페이지 건너뜀" 로그 출력 확인** (p.22가 3번 건너뛰어야 함)
3. **JSON 파싱 에러 발생 안 함** (타입 안전 처리 성공)
4. UI에서 중복 없는 페이지 목록 표시
5. CP가 "테스트 종료" 입력
6. **로그 저장 완료** (ai_bridge/logs/big_131_test.log)
7. 보고서 작성 완료 (ai_bridge/report/big_131_report.md)
8. /compact 실행
