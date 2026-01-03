# BIG_117 보고서

## 수정 내용
- TocEntry.fromJson null 처리: **O** (완료)
  - `unitName`이 null인 경우 빈 문자열('')로 처리
  - `startPage`가 null인 경우 0으로 처리
- API 응답 필터링 추가: **O** (완료)
  - `extractTableOfContents`에서 null 값이 있는 항목 필터링
  - 유효한 항목만 반환하도록 수정

## 테스트 결과
- Null 에러 발생 여부: **미확인**
- 인식된 항목 수: **테스트 불가**
- 인식된 항목 예시: **테스트 불가**

## 문제점
1. **목차 촬영 페이지 접근 불가**
   - 목차 촬영 버튼 클릭 시 아무 반응 없음
   - TocCameraPage로의 라우팅이 작동하지 않음
   - 여러 번 시도했으나 화면 전환 실패

## 코드 수정 내역

### 1. TocEntry.fromJson (toc_entry.dart)
```dart
// 변경 전
factory TocEntry.fromJson(Map<String, dynamic> json) {
  return TocEntry(
    unitName: json['unitName'] as String,
    startPage: json['startPage'] as int,
    endPage: json['endPage'] as int?,
  );
}

// 변경 후
factory TocEntry.fromJson(Map<String, dynamic> json) {
  return TocEntry(
    unitName: json['unitName'] as String? ?? '',
    startPage: json['startPage'] as int? ?? 0,  // null이면 0
    endPage: json['endPage'] as int?,
  );
}
```

### 2. extractTableOfContents (claude_api_service.dart)
```dart
// 변경 전
final entries = (parsed['entries'] as List<dynamic>)
    .map((e) => e as Map<String, dynamic>)
    .toList();

// 변경 후
final entries = (parsed['entries'] as List<dynamic>)
    .map((e) => e as Map<String, dynamic>)
    .where((e) => e['startPage'] != null && e['unitName'] != null)  // null 필터링
    .toList();

debugPrint('[ClaudeAPI] 유효한 목차 항목: ${entries.length}개');
```

## 추가 확인 사항
1. **라우팅 문제 확인 필요**
   - BookRegisterWizard의 Step 4에서 목차 촬영 페이지로 이동하는 로직 확인
   - GoRouter 경로 설정 확인 (`/toc-camera/:bookId`)

2. **버튼 이벤트 처리 확인**
   - _openTocCamera() 메서드 호출 여부
   - context.push() 또는 context.go() 호출 시 오류 발생 여부

## 결론
null 처리 코드는 정상적으로 수정되었으나, 목차 촬영 페이지 자체에 접근할 수 없어 실제 효과를 확인하지 못함. 라우팅 또는 네비게이션 관련 문제로 추정되며, 추가 디버깅이 필요함.