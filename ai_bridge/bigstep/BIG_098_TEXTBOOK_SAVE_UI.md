# BIG_098: 교재 분석 결과 DB 저장 + 선생님 UI 연결

> 생성일: 2025-12-26
> 작업자: Claude Code (Sonnet)
> 목표: 분석된 교재 정보 DB 저장 + 선생님 홈에서 접근 가능하게

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 플랫폼: Windows (flutter run -d windows)

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
1. 교재 분석 결과 → DB 저장 성공
2. 선생님 홈 화면에서 교재 분석 버튼 접근 가능
3. 저장 후 교재 목록에서 확인 가능

### 테스트 시나리오
```
1. 선생님 로그인
2. 홈 화면에서 [교재 분석] 버튼/탭 클릭
3. 교재 이미지 선택 → 분석
4. [DB 저장] 버튼 클릭
5. "저장 완료" 메시지 확인
6. 교재 목록에서 저장된 교재 확인
```

---

## 스몰스텝

### 1. textbook_analyzer_page.dart 수정 - DB 저장 구현

**파일:** lib/features/textbook/textbook_analyzer_page.dart

**수정 내용:**

1) import 추가 (파일 상단):
```dart
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_api/amplify_api.dart';
import '../../models/ModelProvider.dart';
```

2) _saveToDatabase() 메서드 전체 교체:
```dart
Future<void> _saveToDatabase() async {
  if (_analysisResult == null) return;

  setState(() => _isLoading = true);

  try {
    // 분석 결과에서 pageInfo 추출
    final pageInfo = _analysisResult!['pageInfo'] as Map<String, dynamic>?;
    
    if (pageInfo == null) {
      throw Exception('분석 결과에 pageInfo가 없습니다');
    }

    // Textbook 모델 생성
    final textbook = Textbook(
      title: pageInfo['chapterTitle']?.toString() ?? '제목 없음',
      subject: Subject.MATH,  // 기본값: 수학 (추후 선택 가능하게)
      grade: '중2',  // 기본값 (추후 선택 가능하게)
      semester: '1',
      publisher: '비상교육',  // 기본값 (추후 입력 가능하게)
      edition: '2024',
      publishYear: 2024,
      totalPages: pageInfo['pageNumber'] as int? ?? 1,
      isVerified: false,
    );

    // Amplify API로 저장
    final request = ModelMutations.create(textbook);
    final response = await Amplify.API.mutate(request: request).response;

    if (response.hasErrors) {
      throw Exception('저장 실패: ${response.errors}');
    }

    debugPrint('[TextbookAnalyzer] 저장 성공: ${response.data?.id}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('교재가 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('[TextbookAnalyzer] 저장 실패: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

---

### 2. teacher_home_shell.dart 수정 - 교재 탭 추가

**파일:** lib/features/home/teacher_home_shell.dart

**수정 내용:**

1) import 추가 (파일 상단):
```dart
import '../textbook/textbook_analyzer_page.dart';
```

2) pages 리스트 수정 (build 메서드 내):
```dart
final pages = <Widget>[
  const TeacherDashboardPage(),
  const TeacherHomeworkPageAws(),
  const TextbookAnalyzerPage(),  // 추가
];

final titles = <String>["교사 대시보드", "과제", "교재 분석"];  // 수정
```

3) bottomNavigationBar destinations 수정:
```dart
bottomNavigationBar: NavigationBar(
  selectedIndex: _index,
  destinations: const [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '대시보드'),
    NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: '과제'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: '교재'),  // 추가
  ],
  onDestinationSelected: (i) => setState(() => _index = i),
),
```

---

### 3. flutter analyze 실행

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

에러 0개 확인

---

### 4. 앱 실행 테스트

```bash
flutter run -d windows
```

**테스트 항목:**
- [ ] 선생님 로그인 후 하단에 [교재] 탭 보임
- [ ] [교재] 탭 클릭 → 교재 분석 페이지 이동
- [ ] 이미지 선택 → 분석 → JSON 결과 표시
- [ ] [DB 저장] 클릭 → "교재가 저장되었습니다" 메시지
- [ ] 에러 시 빨간색 에러 메시지

---

## 완료 조건

1. ✅ textbook_analyzer_page.dart에 DB 저장 기능 구현
2. ✅ teacher_home_shell.dart에 교재 탭 추가
3. ✅ flutter analyze 에러 0개
4. ✅ 실제 저장 테스트 성공 (로그에서 저장 성공 확인)

---

## 보고서

ai_bridge/report/big_098_report.md

---

## 참고 - Textbook 모델 필드

```dart
Textbook(
  title: String,           // 필수
  subject: Subject,        // 필수 (MATH, ENGLISH, SCIENCE, KOREAN)
  grade: String,           // 필수 (예: "중1", "중2", "고1")
  semester: String?,       // 선택 (예: "1", "2")
  publisher: String,       // 필수 (예: "비상교육", "천재교육")
  edition: String?,        // 선택 (예: "2024", "개정판")
  publishYear: int,        // 필수 (예: 2024)
  totalPages: int?,        // 선택
  coverImageUrl: String?,  // 선택
  registeredBy: String?,   // 선택 (등록자 ID)
  isVerified: bool?,       // 선택 (검증 여부)
)
```

---

## 주의사항

1. `import '../../models/ModelProvider.dart';` 경로 확인
2. Subject enum은 MATH, ENGLISH, SCIENCE, KOREAN 중 하나
3. mounted 체크 후 setState/ScaffoldMessenger 호출
4. 저장 중 로딩 상태 표시
