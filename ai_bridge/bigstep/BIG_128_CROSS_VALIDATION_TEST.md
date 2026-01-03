# BIG_128: PDF 정답지 교차 검증 테스트

> 생성일: 2026-01-03
> 목표: 교차 검증 로직 동작 확인 (Page 2 제외, Page 9 통과)

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 로컬 코드 확인했나? → claude_api_service.dart:1631~1670 교차 검증 로직 확인 완료
- [x] 수정할 파일/줄 번호 특정했나? → 이미 수정 완료, 테스트만 필요
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나? → N/A (테스트만)
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?** → 이미 debugPrint 있음

### 테스트 환경
- [ ] 테스트 계정 리셋 필요한가? → 불필요
- [x] **테스트 계정 현재 상태 확인했나?** → Grammar Effect 책 있어야 함
- [x] 빌드 필요한가? → 예 (코드 수정됨)
- [ ] 듀얼 빌드 필요한가? → 불필요 (폰 단독)

### 플로우 확인
- [x] **진입 경로 전체 확인했나?** → 내 책 → Grammar Effect → 정답지 등록 → PDF 업로드
- [x] **영향 범위 확인했나?** → extractPdfWithTocValidation만 영향

### 의존성 확인
- [x] 새로 import 필요한 패키지 있나? → 없음
- [x] schema/모델 변경 필요한가? → 없음

### 에러 케이스
- [x] 실패 시 사용자에게 어떻게 알려주나? → 기존 로직 유지 (유효한 페이지만 표시)
- [x] 네트워크 오류 처리 있나? → 기존 로직 유지

### 작업 연결
- [x] 이전 BIG에서 미완료된 것 있나? → BIG_127 초기화 버그 수정 완료
- [ ] 이 작업이 다음 작업의 선행 조건인가? → 아니오

---

## ⚠️ 사이드 이펙트 체크리스트 (필수!)

### 새 함수 추가 시
- [x] 관련된 기존 함수 전부 나열 → extractPdfWithTocValidation 내부 수정만
- [x] 각 함수에서 새 필드/로직 반영 필요한지 확인 → 불필요
- [x] 특히: create → update/delete 쌍으로 확인 → N/A

### 새 필드 추가 시
- [x] 해당 필드 사용하는 모든 곳 확인 → 기존 필드 사용
- [x] true/false 분기 처리 확인 → 교차 검증 로직에서 처리
- [x] 초기값, 리셋값 확인 → N/A

### 테스트 시 로그 분석
- [ ] 예상과 다른 값 나오면 즉시 원인 추적
- [ ] "왜 이 값이 나왔지?" 질문하고 답 찾기
- [ ] 이상한 로그는 보고서에 "문제점"으로 기록

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: flutter_application_1\lib\shared\services\claude_api_service.dart (이미 수정 완료)
- 테스트 계정: maknae12@gmail.com

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. Page 2: 교차 검증 실패 → 결과에서 제외
   - API가 tocMatched=true 반환해도
   - 클라이언트에서 "2는 8~범위 밖" 판단 → false
   - API=true, 클라이언트=false → 불일치 → 제외
   
2. Page 9: 교차 검증 통과 → 결과에 포함
   - API: tocMatched=true
   - 클라이언트: 9는 8~10 범위 안 → true
   - API=true, 클라이언트=true → 일치 → 통과

3. "인식 결과 확인" 다이얼로그에 **Page 2 없어야 함**

### 테스트 시나리오
```
1. Grammar Effect 책 선택 → 정답지 등록 화면 진입
2. 기존 정답지 초기화 (있으면)
3. PDF 업로드 버튼 클릭 → 정답지 PDF 선택
4. 콘솔 로그에서 교차 검증 확인:
   - "[PDF분석] 교차검증: API=true, 클라이언트=false (p.2)" ← Page 2 실패
   - "[PDF분석] ⚠️ 교차 검증 실패 → 결과에서 제외"
   - "[PDF분석] 교차검증: API=true, 클라이언트=true (p.9)" ← Page 9 통과
   - "[PDF분석] ✓ 교차 검증 통과: p.9"
5. "인식 결과 확인" 다이얼로그 → Page 2 없고 Page 9만 있으면 성공
```

---

## 수정된 코드 (확인용)

파일: `claude_api_service.dart` (1631~1670줄)

```dart
// ★★★ 교차 검증: API + 클라이언트 둘 다 통과해야 진짜 통과 ★★★

// 1. API 판단
final bool apiSaysValid = tocMatched;

// 2. 클라이언트 판단 (실제 페이지 범위 확인)
bool clientSaysValid = false;
String matchedTocName = '';
if (pageNum != null) {
  for (final toc in tocEntries) {
    final start = toc['startPage'] as int? ?? 0;
    final end = toc['endPage'] as int? ?? start;
    if (pageNum >= start && pageNum <= end) {
      clientSaysValid = true;
      matchedTocName = toc['unitName'] as String? ?? '';
      break;
    }
  }
}

debugPrint('[PDF분석] 교차검증: API=$apiSaysValid, 클라이언트=$clientSaysValid (p.$pageNum)');

// 3. 교차 검증: 둘 다 true여야 통과
if (!apiSaysValid || !clientSaysValid) {
  debugPrint('[PDF분석] ⚠️ 교차 검증 실패 → 결과에서 제외: $unitName (p.$pageNum)');
  continue;  // 다음 페이지로 건너뜀
}
debugPrint('[PDF분석] ✓ 교차 검증 통과: p.$pageNum (목차: $matchedTocName)');
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
- [ ] 콘솔 로그 관찰 (아래 로그 확인)

### 4. 로그 확인 (핵심!)
콘솔에서 다음 로그 확인:
```
[PDF분석] 교차검증: API=???, 클라이언트=??? (p.2)
[PDF분석] 교차검증: API=???, 클라이언트=??? (p.9)
```

**확인할 것:**
- [ ] Page 2: 클라이언트=false → "교차 검증 실패" 로그 있음
- [ ] Page 9: 클라이언트=true → "교차 검증 통과" 로그 있음

### 5. UI 확인
- [ ] "인식 결과 확인" 다이얼로그 표시됨
- [ ] **Page 2 없음** (가장 중요!)
- [ ] Page 9 있고 내용 정상 (A섹션 4문제, B섹션 4문제...)

### 6. 로그 저장
- [ ] 콘솔에서 `[PDF분석]` 관련 로그 복사
- [ ] `ai_bridge/logs/big_128_test.log` 파일에 저장

### 7. 보고서 작성
- [ ] `ai_bridge/report/big_128_report.md` 작성
- [ ] 포함 내용:
  - 교차 검증 로그 (Page 2, Page 9 각각)
  - UI 결과 (Page 2 제외됨, Page 9 표시됨)
  - 성공/실패 판정

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정
- **로그에서 "교차검증" 키워드 반드시 확인**

---

## ⚠️ Opus 필수: 로그 직접 확인!

**보고서만 읽지 말고, 로그 파일도 직접 확인할 것!**

```
확인할 로그:
- ai_bridge/logs/big_128_test.log
- Flutter 콘솔의 [PDF분석] 로그
```

**로그에서 확인할 것:**
1. `[PDF분석] 교차검증:` 로그가 출력되나?
2. Page 2의 클라이언트 판단이 false인가?
3. Page 9의 클라이언트 판단이 true인가?
4. "교차 검증 실패"와 "교차 검증 통과" 로그가 각각 있나?

---

## ⚠️ 컨텍스트 관리 (CLI 오버플로우 방지)

### 필수 규칙
1. **스몰스텝 1~2개 완료할 때마다 /compact 실행**
2. **로그는 필터링** - `grep "[PDF분석]"` 사용

---

## 완료 조건

1. flutter analyze 에러 0개
2. 콘솔 로그에서 Page 2 "교차 검증 실패" 확인
3. 콘솔 로그에서 Page 9 "교차 검증 통과" 확인
4. UI에서 Page 2 제외됨 확인
5. UI에서 Page 9 정상 표시 확인
6. CP가 "테스트 종료" 입력
7. 보고서 작성 완료 (ai_bridge/report/big_128_report.md)
8. /compact 실행
