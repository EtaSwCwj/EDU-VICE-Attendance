# BIG_124: Problem-목차-정답 유기적 연결

> 생성일: 2025-01-03
> 목표: Problem 모델에 unitName, answer 필드 추가 + 문제 촬영 시 자동 매칭

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 로컬 코드 확인했나? (view 도구로 실제 파일 열어봄)
- [x] 수정할 파일/줄 번호 특정했나?
- [x] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나?
- [x] **새 함수/로직에 safePrint 로그 추가 지시했나?**

### 의존성 확인
- [x] 새로 import 필요한 패키지 있나? → 없음
- [x] schema/모델 변경 필요한가? → Problem 모델에 필드 추가

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### 템플릿 먼저 읽기!
```
ai_bridge/templates/BIGSTEP_TEMPLATE.md 읽은 후 작업 시작!
```

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일:
  - `flutter_application_1/lib/features/my_books/models/problem.dart`
  - `flutter_application_1/lib/features/my_books/services/problem_split_service.dart`
  - `flutter_application_1/lib/features/my_books/data/local_book_repository.dart` (헬퍼 함수 추가)

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 문제 촬영 시 해당 페이지의 단원명(unitName) 자동 매칭
- 정답지에서 해당 문제의 정답(answer) 자동 추출
- Problem 객체에 unitName, answer 필드 저장됨

### 테스트 시나리오
```
1. Grammar Effect에 목차 등록 (Unit 01 = p.8~10)
2. Grammar Effect에 정답지 등록 (p.9의 정답 내용)
3. 문제 촬영 (9페이지 → Unit 01 자동 매칭)
4. 디버그 정보에서 Problem의 unitName, answer 확인
```

---

## 현재 데이터 구조

### LocalBook
```dart
tableOfContents: [
  TocEntry(unitName: "Unit 01 문장을 이루는 요소", startPage: 8, endPage: 10),
  TocEntry(unitName: "Unit 02 1형식, 2형식", startPage: 10, endPage: 12),
]

answerContents: {
  9: "Unit 01\nA 1 목적어 2 동사 3 수식어\nB 1 wrote 2 teacher...",
  11: "Unit 02\nA 1 angry 2 an artist..."
}
```

### Problem (현재)
```dart
page: 9
problemNumber: 3
volumeName: "본책"
// unitName 없음, answer 없음
```

---

## 스몰스텝

### 1. Problem 모델에 unitName, answer 필드 추가

- [ ] 파일: `flutter_application_1/lib/features/my_books/models/problem.dart`

**추가할 필드 (기존 필드 뒤에):**
```dart
class Problem {
  // ... 기존 필드들 ...
  final bool? isCorrect;
  final String? answerImagePath;
  
  // ★ 추가 필드
  final String? unitName;     // 소속 단원명 (목차에서 매칭)
  final String? answer;       // 정답 (정답지에서 추출)
```

**생성자 수정:**
```dart
Problem({
  // ... 기존 파라미터들 ...
  this.isCorrect,
  this.answerImagePath,
  this.unitName,      // 추가
  this.answer,        // 추가
}) : createdAt = createdAt ?? DateTime.now();
```

**toJson 수정:**
```dart
Map<String, dynamic> toJson() => {
  // ... 기존 필드들 ...
  'isCorrect': isCorrect,
  'answerImagePath': answerImagePath,
  'unitName': unitName,       // 추가
  'answer': answer,           // 추가
};
```

**fromJson 수정:**
```dart
factory Problem.fromJson(Map<String, dynamic> json) {
  return Problem(
    // ... 기존 필드들 ...
    isCorrect: json['isCorrect'] as bool?,
    answerImagePath: json['answerImagePath'] as String?,
    unitName: json['unitName'] as String?,     // 추가
    answer: json['answer'] as String?,         // 추가
  );
}
```

**copyWith 수정:**
```dart
Problem copyWith({
  // ... 기존 파라미터들 ...
  bool? isCorrect,
  String? answerImagePath,
  String? unitName,      // 추가
  String? answer,        // 추가
}) {
  return Problem(
    // ... 기존 필드들 ...
    isCorrect: isCorrect ?? this.isCorrect,
    answerImagePath: answerImagePath ?? this.answerImagePath,
    unitName: unitName ?? this.unitName,       // 추가
    answer: answer ?? this.answer,             // 추가
  );
}
```

---

### 2. LocalBookRepository에 헬퍼 함수 추가

- [ ] 파일: `flutter_application_1/lib/features/my_books/data/local_book_repository.dart`

**파일 끝에 추가:**
```dart
/// 페이지 번호로 해당 단원 찾기
TocEntry? findUnitForPage(LocalBook book, int page) {
  for (final entry in book.tableOfContents) {
    final start = entry.startPage;
    final end = entry.endPage ?? entry.startPage;
    if (page >= start && page <= end) {
      safePrint('[BookRepo] 페이지 $page → 단원: ${entry.unitName}');
      return entry;
    }
  }
  safePrint('[BookRepo] 페이지 $page → 단원 못 찾음');
  return null;
}

/// 정답지에서 특정 문제의 정답 추출
/// answerContents[page]에서 "번호" 패턴으로 해당 문제 정답 찾기
String? extractAnswerForProblem(LocalBook book, int page, int problemNumber) {
  final content = book.answerContents[page];
  if (content == null || content.isEmpty) {
    safePrint('[BookRepo] 페이지 $page 정답 없음');
    return null;
  }
  
  // 패턴: "3 정답내용" 또는 "3. 정답내용" 또는 "3) 정답내용"
  // 다음 문제 번호나 줄바꿈까지 추출
  final pattern = RegExp(
    r'(?:^|\s)' + problemNumber.toString() + r'[\.\)\s]+([^\n]+?)(?=\s*(?:\d+[\.\)\s]|$))',
    multiLine: true,
  );
  
  final match = pattern.firstMatch(content);
  if (match != null && match.group(1) != null) {
    final answer = match.group(1)!.trim();
    safePrint('[BookRepo] p$page-$problemNumber 정답: $answer');
    return answer;
  }
  
  safePrint('[BookRepo] p$page-$problemNumber 정답 추출 실패');
  return null;
}
```

**import 추가 (파일 상단):**
```dart
import '../models/toc_entry.dart';
```

---

### 3. ProblemSplitService에서 매칭 로직 추가

- [ ] 파일: `flutter_application_1/lib/features/my_books/services/problem_split_service.dart`

**import 추가 (파일 상단):**
```dart
import '../data/local_book_repository.dart';
import '../models/local_book.dart';
```

**splitProblems 메서드 시그니처 변경:**
```dart
// 기존
Future<List<Problem>> splitProblems({
  required File imageFile,
  required String bookId,
  required int page,
  required String volumeName,
}) async {

// 변경 (book 파라미터 추가)
Future<List<Problem>> splitProblems({
  required File imageFile,
  required String bookId,
  required int page,
  required String volumeName,
  LocalBook? book,  // 추가: 목차/정답 매칭용
}) async {
```

**Problem 생성 부분 수정 (약 150번째 줄 근처):**

기존:
```dart
final problem = Problem(
  id: '${bookId}_p${page}_${sectionName}_$number',
  page: page,
  problemNumber: number,
  volumeName: volumeName,
  imagePath: problemPath,
  boundingBox: {
    'x': 0,
    'y': cropY,
    'width': sectionImg.width,
    'height': cropHeight,
  },
);
```

변경:
```dart
// 단원명 + 정답 매칭
String? unitName;
String? answer;
if (book != null) {
  final bookRepo = LocalBookRepository();
  final tocEntry = bookRepo.findUnitForPage(book, page);
  unitName = tocEntry?.unitName;
  answer = bookRepo.extractAnswerForProblem(book, page, number);
}

final problem = Problem(
  id: '${bookId}_p${page}_${sectionName}_$number',
  page: page,
  problemNumber: number,
  volumeName: volumeName,
  imagePath: problemPath,
  boundingBox: {
    'x': 0,
    'y': cropY,
    'width': sectionImg.width,
    'height': cropHeight,
  },
  unitName: unitName,    // 추가
  answer: answer,        // 추가
);

safePrint('[ProblemSplit] ✓ $sectionName.$number 저장 (단원: $unitName, 정답: ${answer ?? "없음"})');
```

**_defaultSplit 메서드도 동일하게 수정** (약 250번째 줄):
- 시그니처에 `LocalBook? book` 추가
- Problem 생성 시 unitName, answer 매칭 추가

---

### 4. problem_camera_page.dart에서 book 전달

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/problem_camera_page.dart`

**_processResult 메서드에서 splitProblems 호출 부분 수정 (약 100번째 줄):**

기존:
```dart
final problems = await _problemSplitService.splitProblems(
  imageFile: imageFile,
  bookId: widget.bookId,
  page: page,
  volumeName: volume.name,
);
```

변경:
```dart
final problems = await _problemSplitService.splitProblems(
  imageFile: imageFile,
  bookId: widget.bookId,
  page: page,
  volumeName: volume.name,
  book: _book,  // 추가: 목차/정답 매칭용
);
```

---

### 5. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -20
```

- [ ] 에러 0개 확인

---

### 6. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. Grammar Effect 책 선택
2. 목차가 등록되어 있는지 확인 (Unit 01, 02... 있어야 함)
3. 정답지가 등록되어 있는지 확인 (등록된 정답지 페이지 > 0)
4. "문제 촬영" → 목차에 있는 페이지 촬영 (예: 9페이지)
5. 촬영 완료 후 콘솔 로그 확인:
   ```
   [BookRepo] 페이지 9 → 단원: Unit 01...
   [BookRepo] p9-3 정답: 목적어
   [ProblemSplit] ✓ A.3 저장 (단원: Unit 01..., 정답: 목적어)
   ```

**성공 기준:**
- 콘솔에 단원명 매칭 로그 출력
- 콘솔에 정답 추출 로그 출력 (정답지 있으면)

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지 (토큰 초과)
- `grep -i "BookRepo\|ProblemSplit" [로그] | tail -30` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_124_report.md` 작성:

```markdown
# BIG_124 보고서

## 수정 내용
- Problem 모델 필드 추가: O/X
- LocalBookRepository 헬퍼 함수: O/X
- ProblemSplitService 매칭 로직: O/X
- problem_camera_page book 전달: O/X

## 테스트 결과
- 단원명 자동 매칭: O/X (로그에서 확인)
- 정답 자동 추출: O/X (로그에서 확인)

## 콘솔 로그 (핵심만)
```
[BookRepo] 페이지 X → 단원: ...
[BookRepo] pX-Y 정답: ...
```

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] Problem 모델에 unitName, answer 필드 추가
2. [ ] LocalBookRepository에 헬퍼 함수 추가
3. [ ] ProblemSplitService 매칭 로직 추가
4. [ ] problem_camera_page에서 book 전달
5. [ ] flutter analyze 에러 0개
6. [ ] 테스트 - 단원명 자동 매칭 확인
7. [ ] 테스트 - 정답 자동 추출 확인
8. [ ] **보고서 작성 완료** (ai_bridge/report/big_124_report.md)
9. [ ] **/compact 실행**
10. [ ] **CP에게 결과 보고**
11. [ ] CP가 "테스트 종료" 입력
