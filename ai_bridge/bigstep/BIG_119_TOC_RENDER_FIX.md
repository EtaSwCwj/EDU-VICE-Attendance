# BIG_119: 목차 섹션 렌더링 문제 수정

> 생성일: 2025-01-03
> 목표: 목차 섹션이 화면에 표시되도록 수정

---

## 현재 문제

- 코드는 추가됐는데 화면에 목차 섹션이 안 보임
- `_buildTableOfContentsSection()` 메서드는 있지만 `build()`에서 호출 안 했을 가능성

---

## 스몰스텝

### 1. 앱 완전 재빌드

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter clean
flutter pub get
flutter run -d RFCY40MNBLL
```

---

### 2. build() 메서드에서 목차 섹션 호출 확인

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/book_detail_page.dart`
- [ ] `build()` 메서드 또는 메인 `Column`/`ListView` 찾기
- [ ] `_buildTableOfContentsSection()` 호출이 있는지 확인

**없으면 추가:**
```dart
// 기존 섹션들 사이에 추가 (예: 정답지 섹션 위나 아래)
_buildTableOfContentsSection(),
```

---

### 3. 디버그 로그 추가

- [ ] `_buildTableOfContentsSection()` 시작 부분에:

```dart
Widget _buildTableOfContentsSection() {
  debugPrint('[DEBUG] _buildTableOfContentsSection 호출됨');
  debugPrint('[DEBUG] tableOfContents.length: ${book.tableOfContents.length}');
  // ... 기존 코드
}
```

- [ ] `build()` 메서드에:

```dart
@override
Widget build(BuildContext context) {
  debugPrint('[DEBUG] BookDetailPage build 호출됨');
  // ...
}
```

---

### 4. _showTableOfContents 기본값 true로 변경

- [ ] 변수 찾기: `bool _showTableOfContents = false;`
- [ ] 변경: `bool _showTableOfContents = true;`

또는 ExpansionTile 대신 항상 보이는 Card로 변경:

```dart
Widget _buildTableOfContentsSection() {
  return Card(
    margin: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.list_alt, color: Colors.teal),
              SizedBox(width: 8),
              Text('목차 (${book.tableOfContents.length}개)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Divider(height: 1),
        // 목차 항목들
        if (book.tableOfContents.isEmpty)
          Padding(
            padding: EdgeInsets.all(16),
            child: Text('등록된 목차가 없습니다', style: TextStyle(color: Colors.grey)),
          )
        else
          ...book.tableOfContents.map((entry) => ListTile(
            title: Text(entry.unitName),
            trailing: Text('p.${entry.startPage}'),
          )),
        Divider(height: 1),
        // 버튼들
        ListTile(
          leading: Icon(Icons.camera_alt, color: Colors.blue),
          title: Text('목차 페이지 촬영'),
          onTap: () => _openTocCamera(),
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: Colors.red),
          title: Text('목차 초기화', style: TextStyle(color: Colors.red)),
          onTap: () => _resetTableOfContents(),
        ),
      ],
    ),
  );
}
```

---

### 5. flutter analyze

```bash
flutter analyze 2>&1 | tail -20
```

- [ ] 에러 0개 확인

---

### 6. 테스트

**테스트 순서:**
1. Grammar Effect 책 선택
2. 책 상세 페이지에서 목차 섹션 보이는지 확인
3. "목차 페이지 촬영" 클릭 → 카메라 진입 확인
4. "목차 초기화" 클릭 → 확인 다이얼로그 표시 확인

**콘솔에서 디버그 로그 확인:**
```
[DEBUG] BookDetailPage build 호출됨
[DEBUG] _buildTableOfContentsSection 호출됨
[DEBUG] tableOfContents.length: X
```

---

## ⚠️ 필수 규칙

### 디버깅 및 로그 관리
- **디버깅과 로그 분석은 후임(소넷)이 담당**
- 로그 파일 전체 읽기 금지 (토큰 초과됨)
- `grep -i "DEBUG\|error" [파일] | tail -30` 사용

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_119_report.md` 작성:

```markdown
# BIG_119 보고서

## 발견한 문제
- build()에서 호출 여부: O/X
- 호출 안 했으면 어디에 추가했는지: [위치]

## 수정 내용
- [수정한 내용]

## 테스트 결과
- 목차 섹션 표시: O/X
- 목차 촬영 버튼 동작: O/X
- 목차 초기화 동작: O/X

## 디버그 로그
- [핵심 로그만 기록]
```

### 컨텍스트 관리
- 스몰스텝 2개 완료할 때마다 /compact 실행
- **보고서 작성 완료 직후 반드시 /compact 실행**

---

## 완료 조건

1. [ ] flutter clean && flutter run 실행
2. [ ] build()에서 목차 섹션 호출 확인/추가
3. [ ] 디버그 로그 추가
4. [ ] flutter analyze 에러 0개
5. [ ] 테스트 - 목차 섹션 표시 확인
6. [ ] **보고서 작성 완료** (ai_bridge/report/big_119_report.md)
7. [ ] **/compact 실행**
8. [ ] **CP에게 결과 보고**
9. [ ] CP가 "테스트 종료" 입력
