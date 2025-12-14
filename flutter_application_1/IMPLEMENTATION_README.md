# EDU-VICE Attendance - 선생님 기능 구현

## 🎉 구현 완료!

### ✅ 완성된 기능

#### 1. **수업 관리 시스템**
- ✅ 수업 생성/수정/삭제
- ✅ **N주 반복 수업 자동 생성** (매주/격주/4주 등)
- ✅ 수업 상태 관리 (예정/진행중/완료/미진행)
- ✅ 오늘의 수업 자동 분류 (진행중 > 경고 > 예정 순)

#### 2. **평가 시스템**
- ✅ **0-100점 슬라이더 평가**
- ✅ 출석 체크
- ✅ 수업별 메모
- ✅ 학생별 개별 평가

#### 3. **UI 컴포넌트**
- ✅ 상태별 색상 코딩 (파란색=진행중, 초록색=완료, 빨간색=경고)
- ✅ 평가 입력 다이얼로그
- ✅ N주 반복 설정 다이얼로그
- ✅ 미리보기 기능

---

## 📦 프로젝트 구조

```
lib/
├── core/
│   ├── di/
│   │   └── injection_container.dart       # ✅ LessonRepository 등록됨
│   ├── error/
│   └── network/
│
├── features/
│   ├── lessons/                           # 🆕 완전 새로 구현
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── lesson.dart            # Lesson, RecurrenceRule
│   │   │   ├── repositories/
│   │   │   │   └── lesson_repository.dart # 인터페이스
│   │   │   └── usecases/
│   │   │       ├── create_recurring_lessons.dart
│   │   │       ├── record_lesson_evaluation.dart
│   │   │       └── get_today_lessons.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── lesson_local_repository.dart # Sembast 구현
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── lesson_provider.dart
│   │       ├── pages/
│   │       │   └── teacher_home_page.dart
│   │       └── widgets/
│   │           ├── lesson_card.dart
│   │           ├── evaluation_dialog.dart
│   │           └── recurring_lesson_dialog.dart
│   │
│   ├── homework/                          # 🆕 확장됨
│   │   └── domain/entities/homework.dart  # 평가 기능 추가
│   │
│   ├── books/                             # 🆕 새로 추가
│   │   └── domain/entities/book.dart      # 교재 진도 추적
│   │
│   └── users/                             # 🆕 새로 추가
│       └── domain/entities/user.dart      # Student, Teacher, Academy
│
└── main.dart
```

---

## 🚀 실행 방법

### 1. 패키지 설치
```bash
flutter pub get
```

### 2. 실행
```bash
flutter run
```

### 3. DI 초기화 확인
`main.dart`에서 이미 설정됨:
```dart
await setupDependencies();
```

---

## 💡 사용 방법

### 선생님 홈 화면
```dart
import 'package:provider/provider.dart';
import 'features/lessons/presentation/providers/lesson_provider.dart';
import 'features/lessons/presentation/pages/teacher_home_page.dart';

// Provider 등록
ChangeNotifierProvider(
  create: (_) => LessonProvider(getIt<LessonRepository>()),
  child: TeacherHomePage(teacherId: 'teacher-001'),
)
```

### N주 반복 수업 생성
```dart
final rule = await showDialog<RecurrenceRule>(
  context: context,
  builder: (_) => const RecurringLessonDialog(),
);

if (rule != null) {
  await provider.createRecurring(
    template: Lesson(...),
    rule: rule,
  );
}
```

### 수업 평가
```dart
// 자동으로 다이얼로그 표시 (LessonCard에서)
onEvaluate: () => _showEvaluationDialog(lesson)
```

---

## 🎨 주요 기능 스크린샷 설명

### 1. 홈 화면
- **진행중** (파란색): 현재 수업 중
- **경고** (빨간색): 시간 지났는데 미진행
- **예정** (회색): 앞으로 할 수업
- **완료** (초록색): 평가 완료

### 2. 평가 다이얼로그
- 0-100점 슬라이더 (5점 단위)
- 출석 체크박스
- 메모 입력란

### 3. N주 반복 설정
- 매주/격주/4주마다 선택
- 요일 멀티 선택 (월/화/수/목/금/토/일)
- 총 회차 설정
- **미리보기** (최대 5개 표시)

---

## 🔧 다음 단계

### Phase 2: 학생 관리 (학생 탭)
- [ ] 학생 목록 조회
- [ ] 학생 상세 화면
- [ ] 교재별 진도 표시
- [ ] 수업 히스토리

### Phase 3: 숙제 관리
- [ ] 숙제 발급
- [ ] 숙제 평가
- [ ] 마감 임박 알림

### Phase 4: 교재 관리
- [ ] 교재 추가
- [ ] 진도 업데이트

---

## 📝 코드 스타일

### Clean Architecture
- **Domain**: 비즈니스 로직 (Entity, Repository, UseCase)
- **Data**: 데이터 처리 (Repository 구현, Local/Remote)
- **Presentation**: UI (Page, Widget, Provider)

### 네이밍
- Entity: `Lesson`, `Homework`, `Book`
- Repository: `LessonRepository` (인터페이스), `LessonLocalRepository` (구현)
- UseCase: `CreateRecurringLessons`, `RecordLessonEvaluation`
- Provider: `LessonProvider`

### 에러 처리
- `Either<Failure, T>` (dartz)
- `result.fold((error) => ..., (data) => ...)`

---

## 🐛 알려진 이슈

없음 - 첫 구현이므로 테스트 필요!

---

## 🙏 참고사항

- **기존 코드 유지**: 기존 features (assignments, homework 등)는 그대로 유지
- **점진적 마이그레이션**: 필요한 부분만 새 구조로 리팩토링
- **Sembast 사용**: 로컬 DB로 빠른 개발, 나중에 AWS 연동 가능

---

## 📞 문의

구현 중 문제 발생 시:
1. 에러 메시지 캡처
2. 어떤 동작을 했는지 설명
3. 질문!

화이팅! 🔥
