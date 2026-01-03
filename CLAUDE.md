# EDU-VICE-Attendance

## 시스템 개요
- 학원 관리 앱 (Flutter + AWS Amplify)
- 핵심 차별점: "교재 페이지+문제번호" 단위 학습 관리
- 역할: 관리자 → 원장 → 선생 → 학생 → 서포터
- GitHub: EtaSwCwj/EDU-VICE-Attendance (dev 브랜치)

## 아키텍처
```
[Flutter App] ←→ [AWS Amplify]
                    ├─ Cognito (인증)
                    ├─ DynamoDB (GraphQL)
                    └─ S3 (이미지)

[로컬 저장소: Sembast] ←→ [문제 분할: Claude Vision + ML Kit OCR]
```

---

## 📁 핵심 파일 맵

### 1. 앱 설정 (lib/app/)
| 파일 | 설명 |
|------|------|
| app_router.dart | GoRouter 라우팅 설정 |
| app_providers.dart | Riverpod Provider 설정 |
| home_shell.dart | 역할별 홈 쉘 분기 |

### 2. 내 교재 기능 (lib/features/my_books/)
| 파일 | 설명 |
|------|------|
| **pages/** | |
| my_books_page.dart | 교재 목록 |
| book_detail_page.dart | 교재 상세 (페이지맵, 촬영기록, 분할문제) |
| book_register_wizard.dart | 교재 등록 마법사 |
| book_edit_page.dart | 교재 수정 (Volume 페이지 범위) |
| problem_camera_page.dart | 문제 촬영 → 분할 파이프라인 |
| answer_camera_page.dart | 정답지 촬영 |
| image_viewer_page.dart | 이미지 뷰어 |
| **data/** | |
| local_book_repository.dart | 교재 CRUD (Sembast) |
| problem_repository.dart | 분할된 문제 CRUD (Sembast) |
| **services/** | |
| problem_split_service.dart | ★ 문제 분할 (Claude Vision + OCR) |
| **models/** | |
| local_book.dart | LocalBook, CaptureRecord 모델 |
| book_volume.dart | BookVolume (본문/워크북 구분) |
| problem.dart | Problem 모델 |
| **widgets/** | |
| page_map_widget.dart | 페이지 맵 그리드 |
| volume_selector.dart | Volume 선택 UI |

### 3. 교재 분석 (lib/features/textbook/)
| 파일 | 설명 |
|------|------|
| book_camera_page.dart | 문서 스캐너 (CunningDocumentScanner) |
| ocr_test_page.dart | ★ OCR+Claude 테스트 (성공한 분할 로직 원본) |
| grammar_effect_2_db.dart | 테스트용 정답 DB |

### 4. 공유 서비스 (lib/shared/services/)
| 파일 | 설명 |
|------|------|
| claude_api_service.dart | ★ Claude Vision API (섹션 분석, 페이지 감지) |
| mlkit_ocr_service.dart | ML Kit OCR 래퍼 |
| auth_state.dart | 인증 상태 관리 |
| invitation_service.dart | 초대 처리 |

### 5. 수업/과제 (lib/features/lessons/, homework/)
| 파일 | 설명 |
|------|------|
| lessons/models.dart | Lesson 모델 |
| lessons/lessons_provider.dart | 수업 상태 관리 |
| homework/models.dart | Homework 모델 |

### 6. 역할별 쉘 (lib/features/)
| 파일 | 설명 |
|------|------|
| teacher/teacher_shell.dart | 선생 네비게이션 |
| student/student_shell.dart | 학생 네비게이션 |
| owner/owner_home_shell.dart | 원장 네비게이션 |

### 7. 로컬 DB (lib/data/local/)
| 파일 | 설명 |
|------|------|
| sembast_database.dart | Sembast 싱글톤 |

### 8. AWS 모델 (lib/models/)
| 파일 | 설명 |
|------|------|
| AppUser.dart | 사용자 |
| Academy.dart | 학원 |
| Student.dart | 학생 |
| Teacher.dart | 선생 |
| Assignment.dart | 과제 |
| Lesson.dart | 수업 |

---

## 🔧 핵심 데이터 구조

### LocalBook (Sembast)
```dart
class LocalBook {
  String id, title, publisher, subject;
  List<BookVolume> volumes;      // 본문, 워크북 등
  List<int> registeredPages;     // 정답지 등록된 페이지
  List<CaptureRecord> captureRecords;  // 촬영 기록
}
```

### BookVolume
```dart
class BookVolume {
  int index;           // 0=본문, 1=워크북...
  String name;         // "본문", "워크북"
  int? startPage, endPage;  // 페이지 범위
}
```

### Problem (분할된 문제)
```dart
class Problem {
  String id;           // {bookId}_p{page}_{section}_{number}
  int page, problemNumber;
  String volumeName, imagePath;
  Map<String, int> boundingBox;
}
```

### CaptureRecord
```dart
class CaptureRecord {
  List<int> pages;
  String volumeName;
  DateTime timestamp;
  String? imagePath;
}
```

---

## ⚡ 문제 분할 파이프라인

```
1. BookCameraPage (문서 스캔)
   ↓ 임시파일
2. ProblemCameraPage (Volume 선택 + 영구 저장)
   ↓ 영구 저장된 이미지
3. ProblemSplitService.splitProblems()
   ├─ Claude Vision → 섹션 bounds(%) 감지
   ├─ 섹션별 crop
   ├─ ML Kit OCR → 문제 번호 실측 좌표(px)
   ├─ 미감지 재검사 (평균 간격 보간)
   └─ 각 문제별 crop + 저장
   ↓
4. ProblemRepository.saveProblems()
```

### Claude API 메서드
```dart
// 섹션 영역(%) 감지 - 핵심!
analyzePageComplete(File) → {pageNumber, sectionBounds: {A: {xStart, xEnd, yStart, yEnd}}}

// 회전 감지
detectRotation(File) → 0/90/180/270

// 페이지 번호만
detectPageNumber(File) → int
```

---

## 📂 저장 경로
```
{app_documents}/
├─ captures/{bookId}/
│   ├─ pages/capture_{timestamp}.jpg    # 원본 촬영
│   └─ problems/p{page}_{section}_{num}.jpg  # 분할된 문제
└─ edu_vice_attendance.db               # Sembast DB
```

---

## 🎯 현재 Phase
- **P1 (60%)**: 기본 기능 (수업, 과제, 교재 관리)
- **P2 (예정)**: 초대 시스템, 서포터, 컨텍스트 전환
- **P3 (예정)**: 교재 DB, 로컬 서버, AI 분석

---

## 🔧 개발 환경
```bash
# 안드로드 실행
flutter run -d RFCY40MNBLL

# Sembast DB 확인
adb shell "run-as com.example.flutter_application_1 cat /data/data/com.example.flutter_application_1/app_flutter/edu_vice_attendance.db"

# 로그 필터
adb logcat | grep -E "\[ProblemSplit\]|\[OCR\]|\[BookDetail\]"
```

---

## ⚠️ 주의사항
1. **임시 파일 문제**: CunningDocumentScanner는 임시 파일 반환 → Navigator.pop 후 삭제될 수 있음 → 즉시 영구 저장 필수
2. **Claude Vision 한계**: 픽셀 좌표 직접 요청 X → 섹션 bounds(%)만 받고 OCR로 실측
3. **Java 버전**: Flutter 빌드에 Java 21 필요 (25는 Gradle 실패)

---

## 📜 작업 규칙
1. 질문 있으면 바로 물어보기
2. 옵션만 나열하지 말고 방향 제시
3. "이거 안 해도 되는 거 아냐?" 먼저 생각
4. 코드 수정 전 현재 코드 먼저 확인
