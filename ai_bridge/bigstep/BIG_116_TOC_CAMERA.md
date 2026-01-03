# BIG_116: 목차 촬영 및 인식 기능 구현

> 생성일: 2025-01-03
> 목표: 책 등록 시 목차를 촬영하여 단원별 페이지 정보 추출

---

## 배경

정답지 인식 시 "p. 09" 같은 페이지 번호를 AI가 제대로 못 읽음.
→ 목차를 먼저 인식해서 단원-페이지 매핑 데이터를 확보
→ 이후 정답지 인식 시 힌트로 활용

---

## 설계

### UI 흐름
```
[책 등록 화면]
    ↓
[목차 촬영 필수]
    ↓
카메라 → 촬영 → AI 인식 → 항목 리스트에 추가
    ↓
[+ 다음 페이지 촬영] ← 반복 가능
    ↓
[촬영 완료]
    ↓
┌─────────────────────────────────────┐
│ 인식된 목차 (수정 가능)                  │
├─────────────────────────────────────┤
│ Unit 01 문장을 이루는 요소  p.8  [수정][삭제] │
│ Unit 02 1형식, 2형식       p.10 [수정][삭제] │
│ [+ 항목 추가]                            │
├─────────────────────────────────────┤
│            [저장하고 완료]                 │
└─────────────────────────────────────┘
```

### 기본 규칙
- 한 장씩만 촬영 (1페이지 = 1사진, 2페이지 분리 안 함)
- 여러 장 촬영 가능 (목차 끝날 때까지)
- 인식 결과 수정/삭제/추가 가능

### 데이터 구조
```dart
// 목차 항목
class TocEntry {
  String unitName;    // "Unit 01 문장을 이루는 요소"
  int startPage;      // 8
  int? endPage;       // 10 (선택적, 범위가 있는 경우)
}

// LocalBook에 추가
class LocalBook {
  // ... 기존 필드
  List<TocEntry> tableOfContents;  // 목차 항목들
}
```

---

## 스몰스텝

### 1. TocEntry 모델 생성

- [ ] 파일: `flutter_application_1/lib/features/my_books/models/toc_entry.dart` (새로 생성)

```dart
import 'package:equatable/equatable.dart';

class TocEntry extends Equatable {
  final String unitName;
  final int startPage;
  final int? endPage;

  const TocEntry({
    required this.unitName,
    required this.startPage,
    this.endPage,
  });

  factory TocEntry.fromJson(Map<String, dynamic> json) {
    return TocEntry(
      unitName: json['unitName'] as String,
      startPage: json['startPage'] as int,
      endPage: json['endPage'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitName': unitName,
      'startPage': startPage,
      'endPage': endPage,
    };
  }

  TocEntry copyWith({
    String? unitName,
    int? startPage,
    int? endPage,
  }) {
    return TocEntry(
      unitName: unitName ?? this.unitName,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
    );
  }

  @override
  List<Object?> get props => [unitName, startPage, endPage];
}
```

---

### 2. LocalBook 모델에 목차 필드 추가

- [ ] 파일: `flutter_application_1/lib/features/my_books/models/local_book.dart`
- [ ] import 추가: `import 'toc_entry.dart';`
- [ ] 필드 추가: `final List<TocEntry> tableOfContents;`
- [ ] 생성자, fromJson, toJson, copyWith, props에 모두 추가

---

### 3. 목차 촬영 페이지 생성

- [ ] 파일: `flutter_application_1/lib/features/my_books/pages/toc_camera_page.dart` (새로 생성)

**핵심 기능:**
- 카메라로 목차 촬영
- 촬영 후 AI 인식 호출
- 인식 결과를 리스트에 누적
- "다음 페이지 촬영" / "촬영 완료" 버튼

**UI 구조:**
```dart
Scaffold(
  appBar: AppBar(title: Text('목차 촬영')),
  body: Column(
    children: [
      // 상단: 촬영된 목차 항목 리스트 (스크롤)
      Expanded(
        child: ListView.builder(
          // TocEntry 리스트 표시
          // 각 항목: 단원명, 페이지, [수정][삭제] 버튼
        ),
      ),
      // 하단: 촬영 버튼들
      Row(
        children: [
          ElevatedButton('목차 페이지 촬영'),
          ElevatedButton('촬영 완료'),
        ],
      ),
    ],
  ),
)
```

---

### 4. Claude API에 목차 인식 메서드 추가

- [ ] 파일: `flutter_application_1/lib/shared/services/claude_api_service.dart`
- [ ] 새 메서드 추가: `extractTableOfContents(File imageFile)`

```dart
/// 목차 이미지에서 단원명 + 페이지 번호 추출
Future<List<Map<String, dynamic>>> extractTableOfContents(File imageFile) async {
  // ... API 호출 설정 ...
  
  final prompt = '''
이 교재 목차 이미지를 분석해주세요.

각 단원/챕터의 이름과 페이지 번호를 추출해주세요.

JSON 형식으로만 반환:
{
  "entries": [
    {"unitName": "Unit 01 문장을 이루는 요소", "startPage": 8},
    {"unitName": "Unit 02 1형식, 2형식", "startPage": 10},
    {"unitName": "Unit 03 3형식, 4형식", "startPage": 12}
  ]
}

규칙:
- unitName: 목차에 보이는 단원/챕터 이름 그대로
- startPage: 페이지 번호 (숫자만)
- 페이지 범위(8-10)가 있으면 startPage만 추출
- 목차에 없는 내용은 추가하지 마세요
''';

  // ... API 호출 및 파싱 ...
}
```

**모델:** Haiku 사용 (단순 작업이므로)

---

### 5. 목차 항목 수정 다이얼로그

- [ ] 같은 파일 또는 별도 위젯
- [ ] 터치하면 수정 다이얼로그 표시

```dart
void _showEditDialog(TocEntry entry, int index) {
  showDialog(
    // TextField: 단원명
    // TextField: 시작 페이지
    // 저장/취소 버튼
  );
}
```

---

### 6. 항목 수동 추가 기능

- [ ] 리스트 하단에 "+ 항목 추가" 버튼
- [ ] 터치하면 빈 항목 추가 다이얼로그

---

### 7. 책 등록 플로우에 목차 촬영 연결

- [ ] 기존 책 등록 화면 확인
- [ ] 목차 촬영 필수로 만들기
- [ ] 목차 촬영 완료 → 책 등록 완료

---

### 8. flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze 2>&1 | tail -20
```

- [ ] 에러 0개 확인

---

### 9. 테스트

```bash
flutter run -d RFCY40MNBLL
```

**테스트 순서:**
1. 내 책장 → 새 책 등록
2. 목차 촬영 화면 진입
3. Grammar Effect 목차 1페이지 촬영
4. AI 인식 결과 확인 (Unit 01, 02... 항목들)
5. "다음 페이지 촬영"으로 추가 촬영
6. 항목 수정/삭제 테스트
7. 수동 항목 추가 테스트
8. "촬영 완료" → 책 등록 완료

**성공 기준:**
- 목차 촬영 → AI 인식 → 항목 리스트 표시
- 항목 수정/삭제/추가 가능
- 저장 후 책 정보에 목차 데이터 포함

---

## ⚠️ 필수 규칙

### 테스트 종료 조건
- **CP가 "테스트 종료" 입력할 때까지 테스트 계속**
- 에러 발생해도 임의로 종료 금지
- 성공해도 CP 확인 전까지 종료 금지

### 보고서 작성 (필수)
테스트 완료 후 반드시 `ai_bridge/report/big_116_report.md` 작성:

```markdown
# BIG_116 보고서

## 구현 내용
- TocEntry 모델: O/X
- LocalBook 목차 필드: O/X
- 목차 촬영 페이지: O/X
- Claude API 메서드: O/X
- 수정/삭제/추가 기능: O/X

## 테스트 결과
- 목차 촬영: O/X
- AI 인식 정확도: [인식된 항목 수 / 실제 항목 수]
- 수정 기능: O/X
- 저장 기능: O/X

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

1. [ ] TocEntry 모델 생성
2. [ ] LocalBook에 목차 필드 추가
3. [ ] 목차 촬영 페이지 구현
4. [ ] Claude API 목차 인식 메서드 추가
5. [ ] 항목 수정/삭제/추가 기능
6. [ ] 책 등록 플로우 연결
7. [ ] flutter analyze 에러 0개
8. [ ] 테스트 완료
9. [ ] **보고서 작성 완료** (ai_bridge/report/big_116_report.md)
10. [ ] **/compact 실행**
11. [ ] **CP에게 결과 보고**
12. [ ] CP가 "테스트 종료" 입력
