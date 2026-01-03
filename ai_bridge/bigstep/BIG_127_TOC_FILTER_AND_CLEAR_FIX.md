# BIG_127: PDF 정답지 - 목차 매칭 실패 필터링 + 초기화 버그 수정

> 생성일: 2025-01-03
> 목표: tocMatched=false인 결과 필터링 + clearRegisteredPages에서 answerContents 초기화

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
  1. `flutter_application_1/lib/shared/services/claude_api_service.dart`
  2. `flutter_application_1/lib/features/my_books/data/local_book_repository.dart`

---

## 🔴 문제 원인

### 문제 1: tocMatched=false여도 결과에 포함됨

**파일:** `claude_api_service.dart`
**위치:** extractPdfWithTocValidation 메서드, 약 1760줄 근처

```dart
// 현재 코드 - 필터링 없음!
for (final page in pages) {
  ...
  results.add({
    'pageNumber': pageNum,  // Page 2 (PDF 순서 번호 오인식)
    'tocMatched': tocMatched,  // false여도 추가됨!
  });
}
```

**결과:**
- Claude가 PDF 하단 "2"를 페이지 번호로 오인식
- tocMatched: false (목차에 없음)
- 필터링 없이 결과 포함 → Page 2 표시

### 문제 2: clearRegisteredPages가 answerContents 안 지움

**파일:** `local_book_repository.dart`
**위치:** clearRegisteredPages 메서드, 약 140줄

```dart
// 현재 코드
final updatedBook = book.copyWith(
  registeredPages: [],  // 이것만 초기화
  updatedAt: DateTime.now(),
);
// answerContents는 그대로 남음!
```

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. tocMatched=false인 페이지는 결과에서 제외
2. 초기화 시 answerContents도 함께 삭제
3. Page 2 같은 잘못된 페이지 표시 안 됨

### 테스트 시나리오
```
[테스트 1: 필터링 확인]
1. Grammar Effect → 정답지 등록 → PDF 업로드
2. 콘솔 로그 확인:
   - "[PDF분석] Step 3: ... 목차 매칭 ✗ → 결과에서 제외"
3. "인식 결과 확인" 다이얼로그:
   - Page 2 없어야 함
   - Page 9, 11, 13, 15 등만 표시

[테스트 2: 초기화 확인]
1. 정답지 저장 후 메인 화면
2. "16개 내용 있음" 배지 확인
3. 정답지 섹션 → 초기화 버튼
4. 배지 사라짐 확인
```

---

## 스몰스텝

### 1. extractPdfWithTocValidation에서 tocMatched=false 필터링

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 위치: extractPdfWithTocValidation 메서드 내, results.add() 부분 (약 1756~1780줄)

**기존 코드 (약 1756줄부터):**
```dart
          for (final page in pages) {
            final unitName = page['unitName'] ?? '';
            final tocMatched = page['tocMatched'] ?? false;
            final pageNum = page['pageNumber'];
            final validation = page['pageValidation'] ?? '';
            final sections = page['sections'] as Map<String, dynamic>? ?? {};

            debugPrint('[PDF분석] Step 3: $unitName ${tocMatched ? "목차 매칭 ✓" : "목차 매칭 ✗"}');
            debugPrint('[PDF분석] Step 4: p.$pageNum - $validation');

            // 섹션별 문제 수 로그
            final sectionInfo = sections.entries
                .map((e) => '${e.key}섹션 ${(e.value as List).length}문제')
                .join(', ');
            debugPrint('[PDF분석] Step 5: $sectionInfo');

            // 정답 내용을 구조화된 문자열로 변환
            final contentBuffer = StringBuffer();
```

**수정 코드:**
```dart
          for (final page in pages) {
            final unitName = page['unitName'] ?? '';
            final tocMatched = page['tocMatched'] ?? false;
            final pageNum = page['pageNumber'];
            final validation = page['pageValidation'] ?? '';
            final sections = page['sections'] as Map<String, dynamic>? ?? {};

            debugPrint('[PDF분석] Step 3: $unitName ${tocMatched ? "목차 매칭 ✓" : "목차 매칭 ✗"}');
            debugPrint('[PDF분석] Step 4: p.$pageNum - $validation');

            // ★★★ 목차 매칭 실패 시 결과에서 제외 ★★★
            if (!tocMatched) {
              debugPrint('[PDF분석] ⚠️ 목차 매칭 실패 → 결과에서 제외: $unitName (p.$pageNum)');
              continue;  // 다음 페이지로 건너뜀
            }

            // 섹션별 문제 수 로그
            final sectionInfo = sections.entries
                .map((e) => '${e.key}섹션 ${(e.value as List).length}문제')
                .join(', ');
            debugPrint('[PDF분석] Step 5: $sectionInfo');

            // 정답 내용을 구조화된 문자열로 변환
            final contentBuffer = StringBuffer();
```

---

### 2. clearRegisteredPages에서 answerContents 초기화

- [ ] 파일: `flutter_application_1/lib/features/my_books/data/local_book_repository.dart`
- [ ] 위치: clearRegisteredPages 메서드 (약 133~152줄)

**기존 코드:**
```dart
  /// 등록된 페이지 전체 초기화
  Future<LocalBook> clearRegisteredPages(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 등록된 페이지 전체 초기화: $bookId');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      final updatedBook = book.copyWith(
        registeredPages: [],
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 등록된 페이지 초기화 완료');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 등록된 페이지 초기화 실패: $e');
      throw Exception('등록된 페이지 초기화 실패: $e');
    }
  }
```

**수정 코드:**
```dart
  /// 등록된 페이지 + 정답 내용 전체 초기화
  Future<LocalBook> clearRegisteredPages(String bookId) async {
    try {
      safePrint('[LocalBookRepo] 등록된 페이지 + 정답 내용 전체 초기화: $bookId');
      final book = await getBook(bookId);
      if (book == null) {
        throw Exception('책을 찾을 수 없습니다: $bookId');
      }

      final updatedBook = book.copyWith(
        registeredPages: [],
        answerContents: {},  // ★ 정답 내용도 함께 초기화
        updatedAt: DateTime.now(),
      );

      await saveBook(updatedBook);
      safePrint('[LocalBookRepo] 등록된 페이지 + 정답 내용 초기화 완료');
      return updatedBook;
    } catch (e) {
      safePrint('[LocalBookRepo] 등록된 페이지 초기화 실패: $e');
      throw Exception('등록된 페이지 초기화 실패: $e');
    }
  }
```

---

### 3. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -20
```

- [ ] 에러 0개 확인

---

### 4. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 1: 필터링 확인**
1. Grammar Effect 책 선택
2. 기존 정답지 있으면 먼저 초기화
3. "정답지 등록" → "PDF 업로드"
4. 콘솔 로그 확인:
   ```
   [PDF분석] Step 3: Unit 01 문장을 이루는 요소 목차 매칭 ✓
   [PDF분석] Step 3: (빈 이름) 목차 매칭 ✗
   [PDF분석] ⚠️ 목차 매칭 실패 → 결과에서 제외: (빈 이름) (p.2)
   ```
5. "인식 결과 확인" 다이얼로그:
   - **Page 2 없어야 함!**
   - Page 9, 11, 13, 15 등만 표시

**테스트 2: 초기화 확인**
1. 정답지 저장 후 책 상세 화면
2. "XX개 내용 있음" 배지 확인
3. 정답지 섹션 → 초기화 버튼
4. 배지 완전히 사라지는지 확인 (0개 내용)

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지
- `grep -i "PDF분석\|LocalBookRepo" [로그] | tail -50` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_127_report.md` 작성:

```markdown
# BIG_127 보고서

## 수정 내용
- tocMatched 필터링: O/X (파일명:줄번호)
- answerContents 초기화: O/X (파일명:줄번호)

## 테스트 결과
- 필터링 동작: O/X (Page 2 제외됨?)
- 초기화 동작: O/X (배지 사라짐?)

## 콘솔 로그 (핵심만)
```
[PDF분석] ⚠️ 목차 매칭 실패 → 결과에서 제외: ...
[LocalBookRepo] 등록된 페이지 + 정답 내용 초기화 완료
```

## 문제점 (있으면)
- [발견된 문제점]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] tocMatched 필터링 추가
2. [ ] answerContents 초기화 추가
3. [ ] flutter analyze 에러 0개
4. [ ] 테스트 - Page 2 제외 확인
5. [ ] 테스트 - 초기화 시 배지 사라짐
6. [ ] **보고서 작성 완료** (ai_bridge/report/big_127_report.md)
7. [ ] **/compact 실행**
8. [ ] **CP에게 결과 보고**
9. [ ] CP가 "테스트 종료" 입력
