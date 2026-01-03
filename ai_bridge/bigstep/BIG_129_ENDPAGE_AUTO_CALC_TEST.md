# BIG_129: endPage 자동 계산 및 교차 검증 테스트

> 생성일: 2026-01-03
> 목표: endPage 자동 계산 로직 검증 + 여러 페이지 정상 인식 확인

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

### 기본 확인
- [x] 로컬 코드 확인했나? → answer_camera_page.dart:323~355 endPage 자동 계산 로직 확인
- [x] 수정할 파일/줄 번호 특정했나? → 이미 수정 완료, 테스트만 필요
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?** → 이미 추가됨

### 테스트 환경
- [x] 테스트 계정 리셋 필요한가? → 불필요
- [x] 빌드 필요한가? → 예 (코드 수정됨)
- [x] 듀얼 빌드 필요한가? → 불필요 (폰 단독)

### 플로우 확인
- [x] **진입 경로 전체 확인했나?** → 내 책 → Grammar Effect → 정답지 등록 → PDF 업로드
- [x] **영향 범위 확인했나?** → _processChunkWithRetry만 영향

---

## ⚠️ 사이드 이펙트 체크리스트 (필수!)

### 새 필드 추가 시
- [x] 해당 필드 사용하는 모든 곳 확인 → endPage는 tocEntries에서만 사용
- [x] true/false 분기 처리 확인 → N/A
- [x] 초기값, 리셋값 확인 → 자동 계산으로 처리

### 테스트 시 로그 분석
- [ ] 예상과 다른 값 나오면 즉시 원인 추적
- [ ] "왜 이 값이 나왔지?" 질문하고 답 찾기
- [ ] 이상한 로그는 보고서에 "문제점"으로 기록

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일: flutter_application_1\lib\features\my_books\pages\answer_camera_page.dart (이미 수정 완료)
- 테스트 계정: maknae12@gmail.com

---

## 🎯 기대 결과 & 테스트 시나리오

### 문제 원인 (수정 전)
```dart
// 기존: endPage 없으면 startPage와 같음
'endPage': e.endPage ?? e.startPage  // Unit 01: 8~8 (오직 8페이지만)
```
→ Page 9는 어느 범위에도 못 들어감 → 교차 검증 실패 → 대부분 페이지 제외됨

### 해결책 (수정 후)
```dart
// 수정: 다음 Unit의 startPage - 1로 자동 계산
if (i + 1 < rawToc.length) {
  end = rawToc[i + 1].startPage - 1;  // Unit 01: 8~9 (다음이 10이니까)
}
```

### 기대 결과
1. 콘솔 로그에서 endPage 자동 계산 확인:
   ```
   [AnswerCamera] 목차[0]: Unit 01 문장을 이루는 요소 → p.8~9
   [AnswerCamera] 목차[1]: Unit 02 1형식, 2형식 → p.10~11
   ```

2. 교차 검증 통과 로그:
   ```
   [PDF분석] 교차검증: API=true, 클라이언트=true (p.9)
   [PDF분석] ✓ 교차 검증 통과: p.9
   ```

3. **여러 페이지 인식** (1페이지만 아님!)
   - "인식 결과 확인 (N페이지)" - N이 10개 이상이어야 정상

### 테스트 시나리오
```
1. Grammar Effect 책 선택 → 정답지 등록 화면 진입
2. 기존 정답지 초기화 (있으면)
3. PDF 업로드 버튼 클릭 → 정답지 PDF 선택
4. 콘솔 로그에서 확인:
   - "[AnswerCamera] 목차[N]: ... → p.X~Y" 형식으로 endPage 자동 계산됨
   - "[PDF분석] 교차검증: API=true, 클라이언트=true" 로그 다수
   - "[PDF분석] ✓ 교차 검증 통과" 로그 다수
5. "인식 결과 확인" 다이얼로그 → 여러 페이지 표시되면 성공
```

---

## 수정된 코드 (확인용)

파일: `answer_camera_page.dart` (323~355줄)

```dart
/// 청크 처리 with 재시도
Future<List<Map<String, dynamic>>> _processChunkWithRetry(File chunk, {int maxRetries = 3}) async {
  // 목차 데이터 준비 (endPage 자동 계산)
  final rawToc = _book?.tableOfContents ?? [];
  final tocEntries = <Map<String, dynamic>>[];
  
  for (int i = 0; i < rawToc.length; i++) {
    final current = rawToc[i];
    final start = current.startPage;
    
    // endPage 계산: 명시적으로 있으면 사용, 없으면 다음 Unit의 startPage - 1
    int end;
    if (current.endPage != null && current.endPage! > 0) {
      end = current.endPage!;
    } else if (i + 1 < rawToc.length) {
      // 다음 Unit의 startPage - 1
      end = rawToc[i + 1].startPage - 1;
    } else {
      // 마지막 Unit이면 책의 totalPages 사용, 없으면 startPage + 50 (여유있게)
      end = _book?.totalPages ?? (start + 50);
    }
    
    tocEntries.add({
      'unitName': current.unitName,
      'startPage': start,
      'endPage': end,
    });
    
    safePrint('[AnswerCamera] 목차[$i]: ${current.unitName} → p.$start~$end');
  }

  safePrint('[AnswerCamera] 목차 ${tocEntries.length}개 항목으로 교차 검증 시작');
  // ...
}
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

**A. endPage 자동 계산 확인:**
```
[AnswerCamera] 목차[0]: Unit 01 ... → p.8~9
[AnswerCamera] 목차[1]: Unit 02 ... → p.10~11
```
- [ ] 각 Unit의 endPage가 다음 Unit의 startPage - 1로 계산됨

**B. 교차 검증 통과 확인:**
```
[PDF분석] 교차검증: API=true, 클라이언트=true (p.9)
[PDF분석] ✓ 교차 검증 통과: p.9
```
- [ ] 여러 페이지에서 "교차 검증 통과" 로그 있음
- [ ] "교차 검증 실패"가 대부분이 아님

### 5. UI 확인
- [ ] "인식 결과 확인 (N페이지)" 다이얼로그 표시됨
- [ ] **N이 10개 이상** (1페이지만 아님!)
- [ ] 각 페이지 내용 정상 표시

### 6. 로그 저장
- [ ] 콘솔에서 `[AnswerCamera] 목차` 관련 로그 복사
- [ ] 콘솔에서 `[PDF분석] 교차검증` 관련 로그 복사
- [ ] `ai_bridge/logs/big_129_test.log` 파일에 저장

### 7. 보고서 작성
- [ ] `ai_bridge/report/big_129_report.md` 작성
- [ ] 포함 내용:
  - endPage 자동 계산 로그 (목차 항목별)
  - 교차 검증 결과 (통과/실패 개수)
  - UI 결과 (인식된 페이지 수)
  - 성공/실패 판정

---

## 검증 규칙 (v7.3)

- 에러 메시지만 보고 실패 판정 금지
- 실제 화면/동작 확인 후 판정
- **로그에서 "목차[N]" 및 "교차검증" 키워드 반드시 확인**

---

## ⚠️ Opus 필수: 로그 직접 확인!

**보고서만 읽지 말고, 로그 파일도 직접 확인할 것!**

```
확인할 로그:
- ai_bridge/logs/big_129_test.log
- Flutter 콘솔의 [AnswerCamera] 및 [PDF분석] 로그
```

**로그에서 확인할 것:**
1. `[AnswerCamera] 목차[N]:` 로그에서 endPage가 올바르게 계산됐나?
2. `[PDF분석] 교차검증:` 로그에서 클라이언트=true가 많나?
3. "교차 검증 통과" 로그가 여러 개 있나?

---

## ⚠️ 컨텍스트 관리 (CLI 오버플로우 방지)

### 필수 규칙
1. **스몰스텝 1~2개 완료할 때마다 /compact 실행**
2. **로그는 필터링** - `grep "[AnswerCamera]\|[PDF분석]"` 사용

---

## 완료 조건

1. flutter analyze 에러 0개
2. 콘솔 로그에서 endPage 자동 계산 확인 (p.X~Y 형식)
3. 콘솔 로그에서 "교차 검증 통과" 다수 확인
4. UI에서 **10개 이상 페이지** 인식 확인
5. CP가 "테스트 종료" 입력
6. 보고서 작성 완료 (ai_bridge/report/big_129_report.md)
7. /compact 실행
