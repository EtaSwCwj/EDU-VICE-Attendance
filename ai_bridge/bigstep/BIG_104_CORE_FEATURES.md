# BIG_104: 핵심 기능 보완 (초기화 버그 + 책 수정 + 촬영 이미지 저장)

> 생성일: 2024-12-28
> 목표: 실제로 동작하는 기능 구현 (껍데기 탈출)

---

## ⚠️ 필수: 테스트 없이 구현만 진행

- flutter analyze 통과 확인
- 빌드 성공 확인
- CP가 직접 테스트

---

## ⚠️ Opus CLI 실행 규칙

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

1. Sonnet한테 파일 1개씩 시키기
2. 스몰스텝 2~3개마다 /compact
3. **각 기능 시작 전 "진행 플로우 검토 중..." 출력 후 플로우 확인**

---

## 환경

- 프로젝트: `C:\gitproject\EDU-VICE-Attendance`
- Flutter 앱: `flutter_application_1/`
- 폰: `RFCY40MNBLL`

---

# 📋 기능 1: 초기화 버그 수정

## 1.1 현재 버그

**파일**: `lib/features/my_books/data/local_book_repository.dart`

```dart
// updateRegisteredPages() 메서드
final allPages = {...book.registeredPages, ...pages}.toList()..sort();
// 문제: 빈 배열 []을 전달해도 기존 페이지와 합쳐져서 초기화 안 됨
```

## 1.2 수정 플로우

```
[수정 전]
1. clearRegisteredPages() 호출
2. updateRegisteredPages(bookId, []) 호출
3. allPages = {...기존30개, ...[]} = 30개 그대로
4. 초기화 실패 ❌

[수정 후]
1. clearRegisteredPages() 호출
2. 새 메서드 clearRegisteredPages() 사용
3. registeredPages = [] 직접 설정
4. 초기화 성공 ✅
```

## 1.3 수정 내용

**local_book_repository.dart**에 추가:
```dart
/// 등록 페이지 전체 초기화
Future<LocalBook> clearRegisteredPages(String bookId) async {
  final book = await getBook(bookId);
  if (book == null) throw Exception('책을 찾을 수 없습니다');
  
  final updatedBook = book.copyWith(
    registeredPages: [],  // 빈 배열로 직접 설정
    updatedAt: DateTime.now(),
  );
  
  await saveBook(updatedBook);
  return updatedBook;
}
```

**book_detail_page.dart** 수정:
```dart
// 기존: await _repository.updateRegisteredPages(widget.bookId, []);
// 수정: await _repository.clearRegisteredPages(widget.bookId);
```

---

# 📋 기능 2: 책 수정 페이지 추가

## 2.1 진입 플로우

```
[책 상세 페이지]
    ↓ 우측 상단 메뉴 (⋮)
    ↓ "책 정보 수정" 선택
    ↓
[책 수정 페이지] ← 새로 만들 페이지
    - 책 제목 (수정 가능)
    - 출판사 (수정 가능)
    - 과목 (수정 가능)
    - 분권별 페이지 범위 설정 ★
    ↓ 저장 버튼
    ↓
[책 상세 페이지로 복귀]
```

## 2.2 화면 구성

```
┌─────────────────────────────────────┐
│ ←  책 정보 수정                      │
├─────────────────────────────────────┤
│                                     │
│  📖 기본 정보                        │
│  ┌─────────────────────────────┐   │
│  │ 제목: [GRAMMAR EFFECT     ] │   │
│  │ 출판사: [NE_Build & Grow   ] │   │
│  │ 과목: [ENGLISH ▼]           │   │
│  └─────────────────────────────┘   │
│                                     │
│  📚 분권별 페이지 범위               │
│  ┌─────────────────────────────┐   │
│  │ 본책                         │   │
│  │ 시작: [1  ]  끝: [19 ]      │   │
│  ├─────────────────────────────┤   │
│  │ Work Book                   │   │
│  │ 시작: [1  ]  끝: [12 ]      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ⚠️ 페이지 범위를 설정해야 정답지    │
│     검증이 정상 작동합니다           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │         💾 저장하기          │   │
│  └─────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

## 2.3 파일 구조

```
lib/features/my_books/pages/
├── book_detail_page.dart      ← 메뉴에 "책 정보 수정" 추가
├── book_edit_page.dart        ← 새로 생성 ★
└── ...

lib/router/
└── app_router.dart            ← 라우트 추가: /my-books/:id/edit
```

## 2.4 book_edit_page.dart 구현 요점

```dart
class BookEditPage extends StatefulWidget {
  final String bookId;
  // ...
}

class _BookEditPageState extends State<BookEditPage> {
  // 컨트롤러들
  final _titleController = TextEditingController();
  final _publisherController = TextEditingController();
  String _selectedSubject = 'ENGLISH';
  
  // 분권별 페이지 범위 컨트롤러 (동적)
  List<TextEditingController> _startPageControllers = [];
  List<TextEditingController> _endPageControllers = [];
  
  @override
  void initState() {
    _loadBook();
  }
  
  Future<void> _loadBook() async {
    final book = await _repository.getBook(widget.bookId);
    // 컨트롤러에 값 설정
    _titleController.text = book.title;
    // 각 Volume별 시작/끝 페이지 컨트롤러 생성
    for (final vol in book.volumes) {
      _startPageControllers.add(TextEditingController(text: '${vol.startPage ?? 1}'));
      _endPageControllers.add(TextEditingController(text: '${vol.totalPages ?? ""}'));
    }
  }
  
  Future<void> _save() async {
    // Volume 업데이트
    final updatedVolumes = book.volumes.asMap().entries.map((e) {
      final idx = e.key;
      final vol = e.value;
      return vol.copyWith(
        startPage: int.tryParse(_startPageControllers[idx].text) ?? 1,
        totalPages: int.tryParse(_endPageControllers[idx].text) ?? 0,
      );
    }).toList();
    
    final updatedBook = book.copyWith(
      title: _titleController.text,
      publisher: _publisherController.text,
      subject: _selectedSubject,
      volumes: updatedVolumes,
    );
    
    await _repository.updateBook(updatedBook);
    context.pop(true);
  }
}
```

## 2.5 라우트 추가

**app_router.dart**:
```dart
GoRoute(
  path: '/my-books/:id/edit',
  builder: (context, state) => BookEditPage(
    bookId: state.pathParameters['id']!,
  ),
),
```

---

# 📋 기능 3: 촬영 이미지 저장 + 표시

## 3.1 현재 문제

```
[현재]
촬영 → 페이지 번호만 저장 → 이미지 버려짐 → 확인 불가

[목표]
촬영 → 이미지 로컬 저장 → DB에 경로 저장 → 목록에서 확인 가능
```

## 3.2 데이터 모델 수정

**CaptureRecord 확장** (local_book.dart):
```dart
class CaptureRecord {
  final List<int> pages;
  final String volumeName;
  final DateTime timestamp;
  final String? imagePath;  // ★ 추가: 촬영 이미지 경로
  
  // ...
}
```

## 3.3 이미지 저장 플로우

```
[촬영 시작]
    ↓
[BookCameraPage에서 촬영]
    ↓ result = {image: File, pages: [11]}
    ↓
[ProblemCameraPage._processResult()]
    ↓
    ├─ 1. 이미지를 앱 저장소로 복사
    │     final appDir = await getApplicationDocumentsDirectory();
    │     final captureDir = Directory('${appDir.path}/captures/${bookId}');
    │     final savedPath = '${captureDir.path}/${timestamp}.jpg';
    │     await image.copy(savedPath);
    │
    ├─ 2. CaptureRecord에 imagePath 포함
    │     final record = CaptureRecord(
    │       pages: pages,
    │       volumeName: volume.name,
    │       timestamp: DateTime.now(),
    │       imagePath: savedPath,  // ★
    │     );
    │
    └─ 3. DB 저장
          await _repository.addCaptureRecord(bookId, record);
```

## 3.4 이미지 표시 플로우

```
[책 상세 페이지]
    ↓
[문제 촬영 기록 (2건)] 섹션 클릭
    ↓
┌─────────────────────────────────────┐
│  📸 11p  본책  오늘 19:44           │
│  ┌─────────────────────────────┐   │
│  │  [촬영된 이미지 썸네일]      │   │
│  │  (탭하면 전체화면)           │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  📸 9p   본책  오늘 19:44           │
│  ┌─────────────────────────────┐   │
│  │  [촬영된 이미지 썸네일]      │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 3.5 전체화면 이미지 뷰어

```
[썸네일 탭]
    ↓
[ImageViewerPage] 또는 Dialog
    - 확대/축소 가능
    - 닫기 버튼
```

## 3.6 파일 구조

```
lib/features/my_books/
├── models/
│   └── local_book.dart         ← CaptureRecord에 imagePath 추가
├── pages/
│   ├── book_detail_page.dart   ← 촬영 기록에 썸네일 표시
│   ├── problem_camera_page.dart ← 이미지 저장 로직 추가
│   └── image_viewer_page.dart  ← 새로 생성 ★
└── data/
    └── local_book_repository.dart
```

---

# 🔧 스몰스텝 (총 12개)

## Phase 1: 초기화 버그 수정 (2개)

### SMALL_01: local_book_repository.dart 수정
- clearRegisteredPages() 메서드 추가
- 기존 updateRegisteredPages()는 그대로 유지

### SMALL_02: book_detail_page.dart 수정
- 초기화 시 clearRegisteredPages() 호출로 변경

---

## Phase 2: 책 수정 페이지 (4개)

### SMALL_03: app_router.dart 수정
- `/my-books/:id/edit` 라우트 추가

### SMALL_04: book_edit_page.dart 생성
- 기본 구조 + 기본 정보 입력 폼
- 제목, 출판사, 과목

### SMALL_05: book_edit_page.dart 확장
- 분권별 페이지 범위 입력 UI
- 각 Volume마다 시작/끝 페이지 TextField

### SMALL_06: book_detail_page.dart 수정
- 메뉴에 "책 정보 수정" 항목 추가
- 수정 후 돌아오면 새로고침

---

## Phase 3: 촬영 이미지 저장 (6개)

### SMALL_07: local_book.dart 수정
- CaptureRecord에 imagePath 필드 추가
- toJson/fromJson 수정

### SMALL_08: problem_camera_page.dart 수정 (1)
- 이미지 저장 디렉토리 생성 로직
- path_provider 사용

### SMALL_09: problem_camera_page.dart 수정 (2)
- 촬영 결과에서 이미지 파일 받기
- 앱 저장소로 복사
- CaptureRecord에 imagePath 포함

### SMALL_10: image_viewer_page.dart 생성
- 전체화면 이미지 뷰어
- InteractiveViewer로 확대/축소
- 닫기 버튼

### SMALL_11: book_detail_page.dart 수정 (1)
- 촬영 기록 섹션에 썸네일 표시
- Image.file() 사용

### SMALL_12: book_detail_page.dart 수정 (2)
- 썸네일 탭 시 ImageViewerPage로 이동
- 라우트 또는 Navigator.push

---

# ✅ 완료 조건

1. `flutter analyze` 에러 0개
2. `flutter run -d RFCY40MNBLL` 빌드 성공
3. CP 테스트 대기

---

# 📝 주의사항

1. **각 기능 시작 전** "진행 플로우 검토 중..." 출력
2. 플로우 다이어그램 확인 후 구현 시작
3. 파일 1개씩 수정
4. 스몰스텝 2~3개마다 `/compact`
