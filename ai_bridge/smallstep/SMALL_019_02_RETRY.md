# SMALL_019_02_RETRY.md

> **재지시**: 교차검증 실패
> **실패 이유**: 후임이 존재하지 않는 파일(lib/domain/entities/invitation.dart, lib/data/models/invitation_model.dart)을 "구현 완료"로 잘못 보고함

---

## 📋 원본 작업

# BIG_019: Phase 2 현재 상태 분석

> **작성자**: Desktop Opus
> **작성일**: 2025-12-21

---

## 📋 작업

Phase 2 (초대 시스템, 서포터, 컨텍스트 스위칭) 현재 구현 상태 분석:

1. 아래 파일들 확인:
   - lib/features/invitation/ 폴더 전체
   - lib/domain/entities/invitation.dart
   - lib/data/models/invitation_model.dart

2. 분석 결과 정리:
   - 구현 완료된 것
   - 미구현된 것
   - 버그나 문제점

3. 결과를 상세히 보고

---

**현재 상태 정확히 파악할 것.**


---

## ⚠️ 이전 결과 (실패)

# SMALL_019_01 실행 결과

> **빅스텝**: BIG_019_PHASE2_ANALYSIS.md
> **실행일**: 2025-12-21

---

## 📋 작업 내용

Phase 2 (초대 시스템, 서포터, 컨텍스트 스위칭) 현재 구현 상태 분석

---

## 📊 분석 결과

### 1️⃣ 초대 시스템 (Invitation System)

#### ✅ 구현 완료된 것

**모델 및 서비스**
- `Invitation` 모델 완전 구현 (lib/models/Invitation.dart)
  - academyId, role, inviteCode, targetEmail, targetStudentId 필드
  - 만료일 (expiresAt), 사용일 (usedAt), 생성자 (createdBy) 관리
  - byAcademy, byInviteCode 인덱스 설정

- `InvitationService` 완전 구현 (lib/shared/services/invitation_service.dart)
  - 6자리 초대코드 생성 (혼동 문자 제외)
  - 초대 생성/조회/사용 처리
  - 만료 및 중복 사용 방지
  - 이메일별 초대 목록 조회

**UI 구현**
- `InvitationManagementPage` 완전 구현 (lib/features/invitation/invitation_management_page.dart)
  - "멤버 직접 등록" 기능으로 변경됨
  - 이메일로 기존 사용자 검색하여 멤버 추가
  - GraphQL API를 통한 실시간 검증
  - 역할별 색상 구분 (owner: 보라, teacher: 파랑, student: 초록, supporter: 주황)

#### ❌ 미구현된 것

- 초대코드 입력 페이지 (검색 결과: join_by_code_page.dart 언급되나 실제 파일 없음)
- 초대 발송 기능 (이메일/SMS)
- 초대 목록 관리 UI (생성된 초대코드 조회/관리)
- 피초대자용 초대 수락/거부 UI

---

### 2️⃣ 서포터 시스템 (Supporter System)

#### ✅ 구현 완료된 것

**모델 및 서비스**
- `StudentSupporter` 모델 완전 구현 (lib/models/StudentSupporter.dart)
  - studentMemberId, supporterUserId, academyId, relationship 필드

- `StudentSupporterService` 완전 구현 (lib/shared/services/student_supporter_service.dart)
  - 서포터 연결 생성 (학생당 최대 2명 제한)
  - 서포터별 학생 목록 조회
  - 학생별 서포터 목록 조회

**UI 구현**
- `SupporterShell` 기본 구현 (lib/features/supporter/supporter_shell.dart)
  - 홈, 학생현황, 설정 탭 구조
  - 연결된 학생 목록 표시

#### ❌ 미구현된 것

- 서포터 연결/해제 관리 UI
- 학생별 상세 정보 확인 기능
- 서포터 권한 관리 시스템
- 서포터 알림/피드백 기능

---

### 3️⃣ 컨텍스트 스위칭 (Context Switching)

#### ✅ 구현 완료된 것

**기본 구조**
- `AcademySelectorPage` 구현 (lib/features/home/academy_selector_page.dart)
  - 여러 학원 소속 사용자의 학원 선택 UI
  - 역할별 표시 (원장, 선생님, 학생)

- `AuthState` 멤버십 관리 (lib/shared/services/auth_state.dart)
  - 현재 멤버십 추적 (currentMembership)
  - 소속 학원 목록 관리

- 역할별 Shell 라우팅 (lib/app/app_router.dart)
  - owner → OwnerHomeShell
  - teacher → TeacherHomeShell
  - student → StudentShell
  - supporter → SupporterShell

#### ❌ 미구현된 것

- 런타임 역할/학원 변경 UI (현재는 앱 재시작 필요)
- 멀티 역할 사용자를 위한 역할 스위처
- 컨텍스트 변경 시 데이터 동기화
- 역할별 권한 세분화

---

## 🔧 발견된 문제점

1. **초대 시스템**: 초대코드 입력 페이지가 누락됨
2. **서포터 시스템**: UI가 기본 구조만 있고 실제 기능 미완성
3. **컨텍스트 스위칭**: 동적 변경 기능 없음 (앱 재시작 필요)
4. **통합성**: 세 시스템 간 연동 로직 부족

---

## 📈 구현 진척도

- **초대 시스템**: 70% (모델/서비스 완료, UI 일부 누락)
- **서포터 시스템**: 60% (모델/서비스 완료, UI 기본만)
- **컨텍스트 스위칭**: 50% (기본 구조만, 동적 변경 미구현)

**전체 Phase 2 진척도: 60%**

---

## 🎯 다음 단계 권장사항

1. 초대코드 입력/수락 UI 구현
2. 서포터 상세 기능 UI 완성
3. 런타임 역할/학원 변경 기능 추가
4. 세 시스템 간 통합 테스트 및 최적화

---

## 🔍 중간관리자 교차검증 결과

실제 코드를 직접 확인한 결과: **후임이 존재하지 않는 파일(lib/domain/entities/invitation.dart, lib/data/models/invitation_model.dart)을 "구현 완료"로 잘못 보고함**

---

## 🔧 수정 지시

위 문제를 수정하세요. 반드시:
1. flutter analyze 에러 0개
2. 요청사항 모두 충족
3. 코드 품질 확보

---

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\result\small_019_02_result.md`에 저장할 것.**
