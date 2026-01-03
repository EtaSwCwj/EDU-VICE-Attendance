# BIG_115: 페이지 번호 변환 버그 수정

> 생성일: 2025-01-03
> 목표: API 응답 pageNumber가 UI에 잘못 표시되는 버그 수정

---

## 현재 상황

**BIG_114 테스트 결과:**
- API 응답: `{pageNumber: 9, content: ...}` ✅ 정확
- UI 표시: `Page 2, 4, 6, 8...` ❌ 잘못됨

**문제:** API는 올바른 페이지 번호(9)를 반환하는데, 어딘가에서 변환되어 2로 표시됨

---

## 스몰스텝

### 1. 페이지 번호 처리 로직 추적

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/answer_camera_page.dart`
- [ ] `_showExtractedTextDialog` 함수 찾기
- [ ] 이 함수에서 `pageNumber`를 어떻게 사용하는지 확인

**확인할 것:**
- `allExtractedPages` 리스트의 각 항목에서 `pageNumber` 값이 뭔지
- UI에 표시할 때 `pageNumber`를 그대로 사용하는지, 아니면 인덱스를 사용하는지

---

### 2. 의심되는 코드 패턴 찾기

**Case 1: 인덱스를 페이지 번호로 사용**
```dart
// 잘못된 코드 예시
for (int i = 0; i < pages.length; i++) {
  Text('Page ${i + 1}')  // ❌ 인덱스 사용
}

// 올바른 코드
for (var page in pages) {
  Text('Page ${page['pageNumber']}')  // ✅ 실제 페이지 번호 사용
}
```

**Case 2: 페이지 번호 추출 시 잘못된 필드 사용**
```dart
// 잘못된 코드 예시
final pageNum = pages.indexOf(page) * 2;  // ❌

// 올바른 코드
final pageNum = page['pageNumber'];  // ✅
```

---

### 3. 디버그 로그 추가

- [ ] `_showExtractedTextDialog` 함수 시작 부분에 로그 추가:

```dart
void _showExtractedTextDialog(List<Map<String, dynamic>> pages) {
  debugPrint('[DEBUG] _showExtractedTextDialog 호출');
  debugPrint('[DEBUG] pages.length: ${pages.length}');
  for (int i = 0; i < pages.length && i < 3; i++) {
    debugPrint('[DEBUG] pages[$i]: ${pages[i]}');
  }
  // ... 기존 코드
}
```

---

### 4. 버그 수정

**찾은 문제에 따라 수정:**

만약 인덱스를 사용하고 있다면 → `page['pageNumber']`로 변경
만약 잘못된 필드를 사용하고 있다면 → 올바른 필드로 변경

---

### 5. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -15
```

- [ ] 에러 0개 확인

---

### 6. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트:**
1. Grammar Effect → 정답지 등록 → 전체 PDF 업로드
2. 인식 결과 다이얼로그 확인

**성공 기준:**
- Page 9, 11, 13, 15, 16, 17... 형태로 표시됨 (2, 4, 6이 아님)

---

## ⚠️ 필수 규칙

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_115_report.md` 작성:

```markdown
# BIG_115 보고서

## 발견한 버그
- 위치: [파일명, 함수명, 라인 번호]
- 원인: [인덱스 사용 / 잘못된 필드 / 기타]
- 잘못된 코드: [코드 일부]

## 수정 내용
- 수정한 코드: [코드 일부]

## 테스트 결과
- 수정 전: Page 2, 4, 6, 8...
- 수정 후: Page ??, ??, ??...
- 성공 여부: O/X

## 다음 단계
- [필요한 추가 작업]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] 페이지 번호 변환 로직 찾기
2. [ ] 버그 원인 파악
3. [ ] 버그 수정
4. [ ] flutter analyze 에러 0개
5. [ ] 테스트 실행 및 결과 확인
6. [ ] **보고서 작성 완료** (ai_bridge/report/big_115_report.md)
7. [ ] **/compact 실행**
8. [ ] **CP에게 결과 보고**
9. [ ] CP가 "테스트 종료" 입력
