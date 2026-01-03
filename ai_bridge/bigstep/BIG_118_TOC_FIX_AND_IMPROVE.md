# BIG_118: 목차 기능 수정 및 개선

> 생성일: 2025-01-03
> 목표: 목차 촬영 라우팅 수정 + 책 수정에서 목차 편집 + 목차 초기화 기능

---

## 현재 문제

1. **목차 촬영 페이지 접근 불가** - 버튼 클릭해도 반응 없음 (라우팅 문제)
2. **책 수정에서 목차 편집 불가** - 기존 책에 목차 추가할 방법 없음
3. **목차 초기화 기능 없음** - 테스트 시 매번 새 책 만들어야 함

---

## 스몰스텝

### 1. 라우팅 문제 디버깅 및 수정

**디버깅은 후임(소넷)이 담당. 로그는 grep/tail로 필터링해서 읽기.**

- [ ] 파일: `flutter_application_1/lib/app/router.dart` (또는 라우터 설정 파일)
- [ ] `/toc-camera/:bookId` 경로가 등록되어 있는지 확인
- [ ] TocCameraPage import 되어 있는지 확인

- [ ] 파일: 목차 촬영 버튼이 있는 페이지 (BookRegisterWizard 또는 관련 파일)
- [ ] `_openTocCamera()` 메서드 확인
- [ ] `context.push('/toc-camera/$bookId')` 호출 확인
- [ ] 디버그 로그 추가해서 버튼 클릭 이벤트 확인:

```dart
void _openTocCamera() {
  debugPrint('[DEBUG] _openTocCamera 호출됨');
  debugPrint('[DEBUG] bookId: $bookId');
  // 라우팅 코드...
}
```

---

### 2. 책 상세/수정 페이지에 목차 편집 기능 추가

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/book_detail_page.dart`
- [ ] 목차 섹션 추가:

```dart
// 등록된 정답지 페이지 섹션 근처에 추가
_buildTableOfContentsSection(),

Widget _buildTableOfContentsSection() {
  return ExpansionTile(
    title: Row(
      children: [
        Icon(Icons.list_alt, color: Colors.teal),
        SizedBox(width: 8),
        Text('목차 (${book.tableOfContents.length}개)'),
      ],
    ),
    children: [
      // 목차 항목 리스트
      ...book.tableOfContents.map((entry) => ListTile(
        title: Text(entry.unitName),
        trailing: Text('p.${entry.startPage}'),
        onTap: () => _editTocEntry(entry),
      )),
      // 목차 촬영 버튼
      ListTile(
        leading: Icon(Icons.camera_alt),
        title: Text('목차 페이지 촬영'),
        onTap: () => _openTocCamera(),
      ),
      // 목차 초기화 버튼
      ListTile(
        leading: Icon(Icons.delete_outline, color: Colors.red),
        title: Text('목차 초기화', style: TextStyle(color: Colors.red)),
        onTap: () => _resetTableOfContents(),
      ),
    ],
  );
}
```

---

### 3. 목차 초기화 기능 구현

- [ ] 같은 파일에 메서드 추가:

```dart
Future<void> _resetTableOfContents() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('목차 초기화'),
      content: Text('등록된 목차를 모두 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('초기화', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final updatedBook = book.copyWith(tableOfContents: []);
    await _repository.saveBook(updatedBook);
    setState(() {
      // 상태 업데이트
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('목차가 초기화되었습니다')),
    );
  }
}
```

---

### 4. LocalBookRepository에 목차 관련 메서드 추가 (필요시)

- [ ] 파일: `flutter_application_1/lib/features/my_books/data/local_book_repository.dart`
- [ ] 필요하면 추가:

```dart
Future<LocalBook> updateTableOfContents(String bookId, List<TocEntry> entries) async {
  final book = await getBookById(bookId);
  if (book == null) throw Exception('책을 찾을 수 없습니다');
  
  final updatedBook = book.copyWith(
    tableOfContents: entries,
    updatedAt: DateTime.now(),
  );
  
  await saveBook(updatedBook);
  return updatedBook;
}

Future<LocalBook> clearTableOfContents(String bookId) async {
  return updateTableOfContents(bookId, []);
}
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

**A. 라우팅 수정 테스트:**
1. 새 책 등록 → 목차 촬영 단계
2. 목차 촬영 버튼 클릭 → 카메라 화면 진입 확인

**B. 기존 책에서 목차 편집 테스트:**
1. 내 책장 → 기존 책 선택 (Grammar Effect)
2. 책 상세 페이지에서 목차 섹션 확인
3. "목차 페이지 촬영" 버튼 클릭 → 카메라 진입

**C. 목차 초기화 테스트:**
1. 책 상세 → 목차 섹션
2. "목차 초기화" 클릭
3. 확인 다이얼로그 → "초기화" 클릭
4. 목차 항목이 0개가 되는지 확인

**성공 기준:**
- 목차 촬영 페이지 진입 가능
- 기존 책에서 목차 촬영 가능
- 목차 초기화 동작

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지 (토큰 초과됨)
- 항상 필터링해서 읽기:
  - `grep -i "error\|exception" [파일] | tail -30`
  - `tail -50 [파일]`

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_118_report.md` 작성:

```markdown
# BIG_118 보고서

## 수정 내용
- 라우팅 문제 수정: O/X (원인: [원인])
- 책 상세에 목차 섹션 추가: O/X
- 목차 초기화 기능: O/X

## 테스트 결과
- 목차 촬영 페이지 진입: O/X
- 기존 책에서 목차 편집: O/X
- 목차 초기화: O/X

## 문제점 (있으면)
- [발견된 문제점]

## 다음 단계
- [필요한 추가 작업]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] 라우팅 문제 수정
2. [ ] 책 상세에 목차 섹션 추가
3. [ ] 목차 초기화 기능 구현
4. [ ] flutter analyze 에러 0개
5. [ ] 테스트 완료
6. [ ] **보고서 작성 완료** (ai_bridge/report/big_118_report.md)
7. [ ] **/compact 실행**
8. [ ] **CP에게 결과 보고**
9. [ ] CP가 "테스트 종료" 입력
