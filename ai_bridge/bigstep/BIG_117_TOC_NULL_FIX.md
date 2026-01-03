# BIG_117: 목차 인식 Null 에러 수정

> 생성일: 2025-01-03
> 목표: startPage가 null일 때 발생하는 타입 캐스팅 에러 수정

---

## 현재 문제

**에러 메시지:**
```
type 'Null' is not a subtype of type 'int' in type cast
```

**원인:**
- AI가 일부 항목에서 페이지 번호를 못 찾음
- API 응답: `{"unitName": "...", "startPage": null}`
- `TocEntry.fromJson`에서 `json['startPage'] as int` → 에러

---

## 스몰스텝

### 1. TocEntry.fromJson에서 null 처리

- [ ] 파일: `flutter_application_1/lib/features/my_books/models/toc_entry.dart`
- [ ] 찾을 코드:
```dart
factory TocEntry.fromJson(Map<String, dynamic> json) {
  return TocEntry(
    unitName: json['unitName'] as String,
    startPage: json['startPage'] as int,
    endPage: json['endPage'] as int?,
  );
}
```

- [ ] 변경할 코드:
```dart
factory TocEntry.fromJson(Map<String, dynamic> json) {
  return TocEntry(
    unitName: json['unitName'] as String? ?? '',
    startPage: json['startPage'] as int? ?? 0,  // null이면 0
    endPage: json['endPage'] as int?,
  );
}
```

---

### 2. API 응답 파싱에서 유효하지 않은 항목 필터링

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 함수: `extractTableOfContents`
- [ ] 파싱 부분 찾아서 필터링 추가:

**찾을 패턴 (대략):**
```dart
final entries = (parsed['entries'] as List<dynamic>)
    .map((e) => e as Map<String, dynamic>)
    .toList();
```

**변경할 코드:**
```dart
final entries = (parsed['entries'] as List<dynamic>)
    .map((e) => e as Map<String, dynamic>)
    .where((e) => e['startPage'] != null && e['unitName'] != null)  // null 필터링
    .toList();

debugPrint('[ClaudeAPI] 유효한 목차 항목: ${entries.length}개');
```

---

### 3. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -15
```

- [ ] 에러 0개 확인

---

### 4. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. 내 책장 → 새 책 등록 → 목차 촬영
2. Grammar Effect 목차 페이지 촬영
3. AI 인식 완료 확인 (에러 없이)
4. 인식된 항목 리스트 표시 확인

**성공 기준:**
- Null 에러 없이 인식 완료
- 페이지 번호 없는 항목은 제외되거나 0으로 표시

---

## ⚠️ 필수 규칙

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_117_report.md` 작성:

```markdown
# BIG_117 보고서

## 수정 내용
- TocEntry.fromJson null 처리: O/X
- API 응답 필터링 추가: O/X

## 테스트 결과
- Null 에러 발생 여부: O/X
- 인식된 항목 수: [숫자]
- 인식된 항목 예시: [Unit명, 페이지]

## 다음 단계
- [필요한 추가 작업]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] TocEntry.fromJson null 처리 추가
2. [ ] API 응답 필터링 추가
3. [ ] flutter analyze 에러 0개
4. [ ] 테스트 - Null 에러 없음
5. [ ] **보고서 작성 완료** (ai_bridge/report/big_117_report.md)
6. [ ] **/compact 실행**
7. [ ] **CP에게 결과 보고**
8. [ ] CP가 "테스트 종료" 입력
