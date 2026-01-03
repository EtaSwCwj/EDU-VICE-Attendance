# BIG_121: 목차 인식 타입 캐스팅 수정

> 생성일: 2025-01-03
> 목표: 목차 인식 후 항목 추가 안 되는 문제 수정

---

## 현재 문제

- 목차 촬영은 됨
- AI 인식 호출은 됨
- **항목이 리스트에 추가 안 됨**

**원인 추정:** toc_camera_page.dart에서 타입 캐스팅 에러

```dart
// 현재 코드 (위험)
startPage: entry['startPage'] as int,  // String이면 에러!
```

---

## 스몰스텝 (디버깅은 후임 담당)

### 1. toc_camera_page.dart 수정

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/toc_camera_page.dart`
- [ ] `_processImage` 메서드 찾기
- [ ] 디버그 로그 + 안전한 타입 변환 추가:

**찾을 코드:**
```dart
Future<void> _processImage(String imagePath) async {
  try {
    final imageFile = File(imagePath);

    setState(() => _processingStatus = '목차 분석 중...');

    // Claude API로 목차 인식
    final extractedEntries = await _claudeService.extractTableOfContents(imageFile);

    setState(() {
      // 인식된 항목들을 리스트에 추가
      for (final entry in extractedEntries) {
        _tocEntries.add(TocEntry(
          unitName: entry['unitName'] as String,
          startPage: entry['startPage'] as int,
          endPage: entry['endPage'] as int?,
        ));
      }
    });
```

**변경할 코드:**
```dart
Future<void> _processImage(String imagePath) async {
  try {
    final imageFile = File(imagePath);

    setState(() => _processingStatus = '목차 분석 중...');

    // Claude API로 목차 인식
    debugPrint('[TocCamera] API 호출 시작');
    final extractedEntries = await _claudeService.extractTableOfContents(imageFile);
    debugPrint('[TocCamera] API 응답: ${extractedEntries.length}개 항목');
    
    for (final entry in extractedEntries) {
      debugPrint('[TocCamera] entry: $entry');
    }

    setState(() {
      // 인식된 항목들을 리스트에 추가
      for (final entry in extractedEntries) {
        // 안전한 타입 변환
        final unitName = entry['unitName']?.toString() ?? '';
        final startPageRaw = entry['startPage'];
        final startPage = startPageRaw is int 
            ? startPageRaw 
            : int.tryParse(startPageRaw?.toString() ?? '') ?? 0;
        final endPageRaw = entry['endPage'];
        final endPage = endPageRaw == null 
            ? null 
            : (endPageRaw is int ? endPageRaw : int.tryParse(endPageRaw.toString()));
        
        debugPrint('[TocCamera] 추가: $unitName, p.$startPage');
        
        if (unitName.isNotEmpty && startPage > 0) {
          _tocEntries.add(TocEntry(
            unitName: unitName,
            startPage: startPage,
            endPage: endPage,
          ));
        }
      }
    });
    
    debugPrint('[TocCamera] 최종 항목 수: ${_tocEntries.length}');
```

---

### 2. import 확인

- [ ] 파일 상단에 `import 'package:flutter/foundation.dart';` 있는지 확인
- [ ] 없으면 추가 (debugPrint 사용 위해)

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
1. Grammar Effect → 목차 펼치기 → "목차 페이지 촬영"
2. 목차 페이지 촬영
3. **콘솔 로그 확인:**
   ```
   [TocCamera] API 호출 시작
   [TocCamera] API 응답: X개 항목
   [TocCamera] entry: {unitName: ..., startPage: ...}
   [TocCamera] 추가: Unit 01..., p.8
   [TocCamera] 최종 항목 수: X
   ```
4. 화면에 항목 표시 확인

**성공 기준:**
- 촬영 후 목차 항목이 리스트에 표시됨
- Unit 01, Unit 02... 형태로 추가됨

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지
- `grep -i "TocCamera" [로그] | tail -30` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_121_report.md` 작성:

```markdown
# BIG_121 보고서

## 수정 내용
- 디버그 로그 추가: O/X
- 타입 캐스팅 안전하게 수정: O/X

## 콘솔 로그 (핵심만)
```
[TocCamera] API 응답: X개 항목
[TocCamera] entry: {...}
[TocCamera] 최종 항목 수: X
```

## 테스트 결과
- 목차 항목 추가됨: O/X
- 인식된 항목 수: [숫자]
- 인식된 항목 예시: [Unit명, 페이지]

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] toc_camera_page.dart 수정 (로그 + 안전한 타입 변환)
2. [ ] flutter analyze 에러 0개
3. [ ] 테스트 - 목차 항목 추가 확인
4. [ ] **보고서 작성 완료** (ai_bridge/report/big_121_report.md)
5. [ ] **/compact 실행**
6. [ ] **CP에게 결과 보고**
7. [ ] CP가 "테스트 종료" 입력
