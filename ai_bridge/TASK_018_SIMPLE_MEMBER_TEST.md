# TASK_018: 단순화된 멤버 등록 테스트

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_018_result.md`

---

## 📋 배경

기존 초대 플로우 (Invitation → 수락) 가 복잡해서 단순화함.

**변경된 플로우:**
```
원장이 이메일 입력 → AppUser 조회 → 바로 AcademyMember 생성 → 끝
```

피초대자는 로그인하면 **이미 등록되어 있음**. 수락 절차 없음.

---

## 📋 수정된 파일 (선임이 이미 수정함)

1. `lib/features/invitation/invitation_management_page.dart` - 멤버 직접 등록
2. `lib/features/home/no_academy_shell.dart` - 단순화 (초대 목록 삭제)
3. `lib/shared/services/auth_state.dart` - refreshAuth() 추가
4. `lib/shared/models/account.dart` - email 필드 추가

---

## 🔧 Step 1: flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

**0 에러 확인 후 다음 단계로.**

에러 있으면 수정하고 결과 보고.

---

## 🧪 Step 2: 원장 멤버 추가 테스트

### 실행

```bash
flutter run
```

### 시나리오

**계정**: owner_test1

```
1. owner_test1 로그인
2. 하단 네비게이션 → "관리" 탭
3. 상단 탭바 → "초대 관리" 탭 (이름은 그대로일 수 있음)
4. 화면 확인:
   - [ ] AppBar 제목: "멤버 관리"
   - [ ] FAB 라벨: "멤버 추가"
   - [ ] 기존 멤버 목록 표시 (있으면)
5. FAB "멤버 추가" 클릭
6. 다이얼로그 확인:
   - [ ] "이미 앱에 가입한 사용자만 추가할 수 있습니다" 안내문
   - [ ] 이메일 입력 필드
   - [ ] 역할 선택 (선생님/학생)
7. 이메일: maknae12@gmail.com 입력
8. 역할: 학생 선택
9. "추가" 버튼 클릭
10. 결과 확인:
    - [ ] 성공 시: "OOO님을 학생(으)로 등록했습니다" SnackBar
    - [ ] 미가입 시: "xxx은(는) 가입되지 않은 사용자입니다" SnackBar
    - [ ] 이미 멤버: "xxx은(는) 이미 등록된 멤버입니다" SnackBar
```

### 로그 확인

```
[InvitationManagementPage] Adding member: role=student, email=maknae12@gmail.com
[InvitationManagementPage] Found user: xxx-xxx-xxx
[InvitationManagementPage] Member created: xxx-xxx-xxx
```

---

## 🧪 Step 3: 피초대자 확인 테스트

### 시나리오

**계정**: maknae12@gmail.com (Step 2에서 등록한 계정)

```
1. owner_test1 로그아웃
2. maknae12@gmail.com 로그인
3. 확인:
   - [ ] 바로 StudentShell로 이동 (홈 화면, 수업 탭 등 표시)
   - [ ] 또는 NoAcademyShell 표시 시 "등록 확인" 버튼 클릭
4. NoAcademyShell인 경우 확인:
   - [ ] "내 이메일" 박스에 이메일 표시
   - [ ] QR 코드 표시
   - [ ] "등록 확인" 버튼 있음
```

### 로그 확인

```
[AuthState] 인증 상태 새로고침
[DEBUG] AcademyMember 조회 결과: 있음 (role=student)
```

---

## 📝 문제 발생 시

### AppUser 조회 실패

```
"xxx은(는) 가입되지 않은 사용자입니다"
```

→ 해당 이메일로 회원가입 안 된 상태. 먼저 회원가입 필요.

### 멤버 등록 후에도 NoAcademyShell

1. "등록 확인" 버튼 클릭
2. 안 되면 앱 재시작
3. 로그 확인: AcademyMember 조회 결과

### DataStore 동기화 문제

AWS 콘솔에서 AcademyMember 테이블 직접 확인.

---

## ✅ 완료 체크리스트

### Step 1
- [ ] flutter analyze 0 에러

### Step 2: 원장 멤버 추가
- [ ] "멤버 관리" 화면 표시
- [ ] "멤버 추가" 다이얼로그 정상
- [ ] 이메일 입력 + 역할 선택 동작
- [ ] 멤버 추가 성공 SnackBar
- [ ] 멤버 목록에 새 멤버 표시

### Step 3: 피초대자 확인
- [ ] 로그인 시 StudentShell로 이동
- [ ] 또는 "등록 확인" 후 이동

---

## 📝 결과 보고 템플릿

```markdown
# TASK_018 결과

## flutter analyze
- 에러: 0개 / X개
- 수정 사항: (있으면)

## 원장 멤버 추가 테스트
- 화면 표시: O/X
- 다이얼로그: O/X
- 멤버 추가 성공: O/X
- 로그 정상: O/X

## 피초대자 테스트
- StudentShell 이동: O/X
- 새로고침 필요 여부: O/X

## 발견된 문제
- (있으면 기록)

## 주요 로그
- (중요한 것만)
```

---

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_018_result.md`에 저장할 것.**
