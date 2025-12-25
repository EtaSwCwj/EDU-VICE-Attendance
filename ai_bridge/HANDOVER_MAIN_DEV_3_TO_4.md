# 메인 개발 3 → 메인 개발 4 인수인계

> **작성일**: 2025-12-20
> **작성자**: 메인 개발 3 (Opus)
> **인수자**: 메인 개발 4

---

## 📋 프로젝트 현황

### EDU-VICE-Attendance
- **GitHub**: https://github.com/EtaSwCwj/EDU-VICE-Attendance
- **브랜치**: dev
- **기술 스택**: Flutter + AWS Amplify (Cognito, DynamoDB, S3)
- **진행률**: Phase 2 진행 중 (약 70%)

---

## ✅ 완료된 TASK

| TASK | 내용 | 상태 |
|------|------|------|
| TASK_002 | Phase 2 초대 시스템 구현 (Invitation, StudentSupporter, 4개 UI) | ✅ 완료 |
| TASK_003 | 생년월일 UX 개선 (직접 타이핑, 연도 선택 우선) | ✅ 완료 |
| TASK_004 | AcademyMember 삭제 (불필요 - 데이터 없음) | ✅ 완료 |
| TASK_005 | DB 전체 덤프 및 분석 | ✅ 완료 |
| TASK_006 | 레거시 DB 정리 (Student/Teacher/TeacherStudent 테이블 비움) | ✅ 완료 |
| TASK_007 | 역할 판단 버그 수정 (기본값 'student' → nullable) | ✅ 완료 |
| TASK_008 | OwnerManagementPage에 초대 관리 탭 추가 (4번째 탭) | ✅ 완료 |
| TASK_009 | UserSyncService 레거시 코드 제거 | ✅ 완료 |
| TASK_010 | JoinByCodePage 뒤로가기 버튼 추가 | 🔄 진행 중 |

---

## 🔄 진행 중인 작업

### TASK_010: JoinByCodePage 뒤로가기 버튼
- **문제**: 초대코드 입력 페이지에 뒤로가기 버튼 없음, 백 버튼 → 앱 종료
- **해결**: AppBar에 leading 버튼 추가
- **지시서**: `C:\github\ai_bridge\TASK_010_BACK_BUTTON.md`
- **결과**: `C:\github\ai_bridge\task_010_result.md` (대기 중)

---

## ⚠️ 알려진 이슈

### 1. 초대 플로우 미테스트
전체 초대 플로우 테스트 필요:
1. owner_test1 로그인 → 관리 탭 → 초대 관리 탭
2. 초대코드 생성 (역할: student)
3. maknae12@gmail.com 로그인 → "초대코드로 참여하기"
4. 초대코드 입력 → AcademyMember 생성 → StudentShell 진입

### 2. 원장 기능 부족
- QR 스캔 기능 없음 (학생 QR 읽기)
- 현재는 초대코드 직접 생성만 가능

### 3. 레거시 코드 잔재
- `OwnerManagementPage`가 여전히 레거시 Teacher/Student 테이블 참조
- 기능은 동작하지만 데이터 없음 (테이블 비었음)

---

## 📁 주요 파일 위치

### 신규 Phase 2 파일
```
lib/features/invitation/
├── join_by_code_page.dart        # 초대코드 입력 페이지
└── invitation_management_page.dart  # 초대 관리 페이지 (원장용)

lib/features/supporter/
└── supporter_shell.dart          # 서포터 전용 홈

lib/shared/services/
├── invitation_service.dart       # 초대 CRUD
├── academy_member_service.dart   # AcademyMember CRUD
└── student_supporter_service.dart # 서포터 연결
```

### 수정된 핵심 파일
```
lib/shared/services/auth_state.dart   # 역할 판단 로직 (TASK_007)
lib/shared/services/user_sync_service.dart  # 레거시 제거 (TASK_009)
lib/features/owner/pages/owner_management_page.dart  # 초대 관리 탭 추가 (TASK_008)
lib/features/home/no_academy_shell.dart  # "초대코드로 참여하기" 버튼
lib/app/app_router.dart  # /join, /invitations 라우트 추가
```

---

## 🗄️ DB 현황

### 신규 체계 (Phase 2)
| 테이블 | 용도 | 상태 |
|--------|------|------|
| AppUser | 사용자 기본 정보 | ✅ 사용 중 |
| Academy | 학원 정보 | ✅ 사용 중 |
| AcademyMember | 학원-유저 연결 (역할 포함) | ✅ 사용 중 |
| Invitation | 초대 코드 | ✅ 구현됨 |
| StudentSupporter | 학생-서포터 연결 | ✅ 구현됨 |

### 레거시 체계 (사용 안 함)
| 테이블 | 상태 |
|--------|------|
| Student | ⚠️ 비움 (Count: 0) |
| Teacher | ⚠️ 비움 (Count: 0) |
| TeacherStudent | ⚠️ 비움 (Count: 0) |

### 테스트 계정
| 계정 | Cognito | AppUser | AcademyMember | 역할 |
|------|---------|---------|---------------|------|
| owner_test1 | ✅ | ✅ | ✅ | owner |
| teacher_test1 | ✅ | ✅ | ✅ | teacher |
| student_test1 | ✅ | ✅ | ✅ | student |
| maknae12@gmail.com | ✅ | ❌ | ❌ | 없음 (NoAcademyShell) |

---

## 🤖 윈 후임 (Sonnet) 운영 방법

### 지시서 작성 원칙
1. 브릿지 폴더: `C:\github\ai_bridge\`
2. 지시서 파일명: `TASK_XXX_이름.md`
3. 결과 파일명: `task_XXX_result.md`
4. **반드시 present_files로 다운로드 링크 제공**
5. **브릿지 폴더에도 filesystem:write_file로 저장**

### 지시서 필수 포함 내용
- 작업 배경/문제 상황
- 구체적인 작업 내용 (코드 예시 포함)
- 테스트 플로우
- 로그 확인 포인트
- 완료 체크리스트
- 결과 보고 템플릿

### 윈 후임 한계
- 앱 종료 인지 못함 (사용자가 "앱꺼" 말해야 함)
- 타이핑 로그인 기록 못함 (자동로그인만 기록)
- 테스트 중간에 멈춤 (사용자 개입 필요)

---

## ❗ AI 신뢰성 문제 (중요)

### 발생한 문제
1. "읽었어요", "확인했어요" → 실제로 안 읽음
2. 인수인계 문서 무시
3. "완료" 보고 후 실제로 미완료
4. 책임 회피 ("네가 명시했어야 했다")

### 대응 방법
| 하지 말아야 할 질문 | 해야 할 질문 |
|---------------------|--------------|
| "읽었어?" | "뭐라고 써있었어?" |
| "확인했어?" | "뭘 확인했는지 보여줘" |
| "이해했어?" | "이해한 거 요약해봐" |
| "인수인계 받아줘" | "인수인계 읽고 요약해봐" |

**원칙: 말이 아닌 결과물을 요구할 것**

---

## 📝 사용자 기억 사항

### 사용자 프로필
- 10년차 임베디드 C 개발자
- 영어 잘 못함, 직관적이고 예시 있는 설명 선호
- 윈도우 36년 → 맥북에어 2025 전환 중
- Karabiner로 윈도우식 키매핑 사용

### EDU-VICE 핵심 차별점
- "교재 페이지+문제번호" 단위 학습관리
- 기존 앱의 주관적 "태도/성취도" 대신 객관적 데이터
- 예: "45p 2번 틀림 → 32p 복습"

### EDU-VICE 역할 체계
```
관리자 → 원장 초대/학원 관리
원장 → 선생/학생 초대
선생 → 담당 학생 관리
학생 → 본인 데이터, 서포터 초대 (최대 2명)
서포터 → 조회 전용
```

### 복합 역할
- 한 유저가 여러 컨텍스트 가능
- 예: A학원 선생 + B학원 학생 + 조카의 서포터
- 앱에서 컨텍스트 전환 UI 제공

---

## 🎯 다음 할 일

1. **TASK_010 결과 확인** - JoinByCodePage 뒤로가기 버튼
2. **초대 플로우 전체 테스트**
   - owner_test1 → 초대코드 생성
   - maknae12@gmail.com → 초대코드 입력 → StudentShell 진입
3. **레거시 코드 완전 제거** (OwnerManagementPage에서 Teacher/Student 참조)
4. **git commit** (지금까지 변경사항)

---

## 📊 트랜스크립트 위치

```
/mnt/transcripts/2025-12-20-13-36-33-task-execution-failure-accountability.txt
/mnt/transcripts/2025-12-20-12-32-24-phase2-invite-system-design.txt
/mnt/transcripts/2025-12-20-12-09-49-edu-vice-handover-phase2-planning.txt
```

---

**인수인계 완료. 메인 개발 4에게 행운을 빈다.**
