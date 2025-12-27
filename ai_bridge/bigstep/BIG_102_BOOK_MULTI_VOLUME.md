# BIG_102: 책 Multi-Volume 구조 설계 및 구현

> 생성일: 2024-12-28
> 목표: 본책+워크북처럼 페이지가 리셋되는 복합 구성 책 지원

---

## ⚠️ 작성 전 체크리스트 (Desktop Opus 필수 확인!)

> 이 체크리스트 완료 전에 스몰스텝 작성 금지!

### 기본 확인
- [x] 템플릿 읽음 (ai_bridge/templates/BIGSTEP_TEMPLATE.md)
- [ ] 로컬 코드 확인했나? (view 도구로 실제 파일 열어봄)
- [ ] 수정할 파일/줄 번호 특정했나?
- [ ] 삭제할 코드 vs 추가할 코드 구체적으로 작성했나?
- [ ] **새 함수/로직에 safePrint 로그 추가 지시했나?**

### 테스트 환경
- [ ] 테스트 계정 리셋 필요한가?
- [ ] 빌드 필요한가? (코드 수정만이면 analyze만)

### 플로우 확인
- [ ] **진입 경로 전체 확인했나?**
- [ ] **영향 범위 확인했나?**

### 의존성 확인
- [ ] 새로 import 필요한 패키지 있나?
- [ ] schema/모델 변경 필요한가?

---

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 📋 배경 및 문제 정의

### 실제 사례: Grammar Effect 2

```
📚 Grammar Effect 2 (물리적 1권, 합본)
├── 본책: p.1 ~ p.144
└── 워크북: p.1 ~ p.32  ← 페이지 번호 리셋!

📄 정답지 (별도 PDF)
├── p.1~20: 본책 해답
└── p.21~32: "Workbook Answer Keys" 섹션
```

### 문제점

1. **페이지 충돌**: 본책 12p와 워크북 12p가 다른 내용
2. **검증 불가**: 유저가 찍은 "12p 3번"이 어느 책인지 모름
3. **정답지 매핑**: 정답지 내에서도 본책/워크북 구분 필요

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- 수정 파일:
  - lib/features/student/models/local_book.dart
  - lib/features/student/models/book_volume.dart (신규)
  - lib/features/student/repositories/local_book_repository.dart
  - lib/features/student/pages/book_registration_wizard_page.dart
  - lib/features/student/widgets/volume_selector.dart (신규)
  - lib/core/services/answer_validation_service.dart (신규)
- 테스트 계정: maknae12@gmail.com

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 책 등록 시 "몇 권 구성인지" 선택 가능
- Volume별 이름, 정답지 페이지 범위 설정 가능
- 문제 촬영 시 Volume 선택 체크박스 표시
- 정답지 범위 기반 검증 동작

### 테스트 시나리오
```
1. 책 등록 → "2권 구성" 선택 → 본책/워크북 이름 입력 → 성공
2. 정답지 범위 설정 → 본책 1~20p, 워크북 21~32p → 저장
3. 촬영 화면 → Volume 선택 체크박스 표시 → 전환 가능
4. 본책 12p 촬영 → 정답지 1~20p 범위에서 검증 → 성공
5. 워크북 12p 촬영 → 정답지 21~32p 범위에서 검증 → 성공
```

---

## 📐 데이터 구조 설계

### LocalBook (책 컨테이너)

```dart
class LocalBook {
  String id;
  String title;           // "Grammar Effect 2"
  String? publisher;      // "NE능률"
  String? subject;        // "영어"
  String? setId;          // 세트 연결용 (선택)
  List<BookVolume> volumes;  // 본책, 워크북 등
  DateTime createdAt;
  DateTime updatedAt;
}
```

### BookVolume (볼륨 = 페이지 번호 체계 단위)

```dart
class BookVolume {
  int index;              // 0, 1, 2... (순서)
  String name;            // "본책", "워크북", "정답지"
  int? answerStartPage;   // 정답지에서 이 볼륨의 시작 페이지
  int? answerEndPage;     // 정답지에서 이 볼륨의 끝 페이지
  int? totalPages;        // 이 볼륨의 총 페이지 (선택)
}
```

---

## 스몰스텝

### 1. BookVolume 모델 생성

- [ ] 파일: lib/features/student/models/book_volume.dart (신규)
- [ ] 새 코드:
```dart
class BookVolume {
  final int index;
  final String name;
  final int? answerStartPage;
  final int? answerEndPage;
  final int? totalPages;

  BookVolume({
    required this.index,
    required this.name,
    this.answerStartPage,
    this.answerEndPage,
    this.totalPages,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'answerStartPage': answerStartPage,
    'answerEndPage': answerEndPage,
    'totalPages': totalPages,
  };

  factory BookVolume.fromJson(Map<String, dynamic> json) => BookVolume(
    index: json['index'] as int,
    name: json['name'] as String,
    answerStartPage: json['answerStartPage'] as int?,
    answerEndPage: json['answerEndPage'] as int?,
    totalPages: json['totalPages'] as int?,
  );
}
```

### 2. LocalBook 모델 수정

- [ ] 파일: lib/features/student/models/local_book.dart
- [ ] 변경 내용:
  - totalPages 필드 제거 (optional이었음)
  - List<BookVolume> volumes 필드 추가
  - toJson/fromJson 수정

### 3. LocalBookRepository 수정

- [ ] 파일: lib/features/student/repositories/local_book_repository.dart
- [ ] 변경 내용:
  - volumes 저장/로드 로직 추가
  - 기존 단일 책 → volumes 마이그레이션 로직 (선택)

### 4. 책 등록 위자드 UI 수정

- [ ] 파일: lib/features/student/pages/book_registration_wizard_page.dart
- [ ] 변경 내용:
  - "몇 권 구성?" 라디오 버튼 추가
  - Volume별 이름 입력 필드 동적 생성
  - 정답지 페이지 범위 입력 필드

### 5. VolumeSelector 위젯 생성 (촬영 시 선택)

- [ ] 파일: lib/features/student/widgets/volume_selector.dart (신규)
- [ ] 기능:
  - 체크박스로 현재 Volume 선택
  - 세션 유지 (앱 포그라운드 동안)
  - 선택 상태 시각적 표시

### 6. 정답지 검증 서비스 생성

- [ ] 파일: lib/core/services/answer_validation_service.dart (신규)
- [ ] 기능:
  - Volume의 answerStartPage~answerEndPage 범위에서 검색
  - 페이지+문제번호 매칭
  - 실패 시 경고 반환

### 7. flutter analyze

- [ ] flutter analyze 실행
- [ ] 에러/경고 0개 확인

### 8. 테스트

- [ ] flutter run -d RFCY40MNBLL
- [ ] 책 등록 → 2권 구성 선택 → Volume 이름 입력
- [ ] 정답지 범위 설정
- [ ] 촬영 화면 → Volume 선택 체크박스 동작
- [ ] 검증 로직 동작 확인

---

## ⚠️ 제약사항 및 결정사항

### 1. 정답지 필수
- 정답지 없는 책은 검증 불가
- 검증 없이 진행 가능하나, 공유 불가 (개인용만)

### 2. 헤더 자동 감지 안 함
- "Workbook Answer Keys" 같은 헤더로 자동 분리 안 함
- 이유: 책 DB를 일부씩 만드는 게 목적인데, 전체 정답지 필요해지면 주객전도

### 3. 유저 책임 원칙
- Volume 잘못 선택하고 찍으면 → 검증 단계에서 걸림
- 그래도 통과하면 → 유저 책임 (특히 B2C 개인용)

---

## 로그 저장

각 스몰스텝 완료 시:
- ai_bridge/logs/big_102_step_XX.log

---

## 완료 조건

1. BookVolume 모델 생성됨
2. LocalBook에 volumes 필드 추가됨
3. 책 등록 위자드에서 Volume 설정 가능
4. 촬영 시 Volume 선택 체크박스 동작
5. 검증 서비스 동작
6. flutter analyze 에러 0개
7. CP가 "테스트 종료" 입력
8. 보고서 작성 완료 (ai_bridge/report/big_102_report.md)
