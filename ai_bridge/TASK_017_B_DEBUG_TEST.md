# TASK_017_B: 초대 플로우 디버깅 테스트

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_017_b_result.md`
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수. 앱 종료 = 테스트 끝.

---

## 📋 목적

TASK_017에서 수정한 초대 플로우 전체 테스트.
원장이 이메일로 초대 → 피초대자가 초대 목록에서 수락 → 역할 전환

---

## 🧪 테스트 1: 원장 초대 생성

### 실행

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run
```

### 시나리오

**계정**: owner_test1

```
1. owner_test1 로그인
2. 하단 네비게이션 → "관리" 탭
3. 상단 탭바 → "초대 관리" 탭
4. 우하단 FAB "초대 생성" 버튼 클릭
5. 다이얼로그 확인:
   - [ ] 이메일 입력 필드 있음
   - [ ] 역할 선택 (선생님/학생) SegmentedButton 있음
6. 이메일: maknae12@gmail.com 입력
7. 역할: 학생 선택
8. "초대하기" 버튼 클릭
9. 확인:
   - [ ] SnackBar: "maknae12@gmail.com에게 초대를 보냈습니다"
   - [ ] 초대 목록에 새 항목 표시
   - [ ] 이메일 표시: maknae12@gmail.com
   - [ ] 역할: 학생
   - [ ] 상태: 유효
```

### 로그 확인

```
[InvitationManagementPage] Creating invitation: role=student, email=maknae12@gmail.com
[InvitationService] Creating invitation: academyId=xxx, role=student
[InvitationService] Invitation created: code=XXXXXX, id=xxx
```

### 에러 케이스 테스트

1. **빈 이메일**: 아무것도 입력 안 하고 "초대하기" → "이메일을 입력해주세요"
2. **잘못된 형식**: "test" 입력 (@ 없음) → "올바른 이메일 형식이 아닙니다"

---

## 🧪 테스트 2: 피초대자 초대 확인 및 수락

### 시나리오

**중요**: 테스트 1 완료 후 진행

**계정**: maknae12@gmail.com 계정 (없으면 회원가입 필요)

```
1. owner_test1 로그아웃
2. maknae12@gmail.com 로그인 (또는 회원가입)
3. NoAcademyShell 진입 확인
4. 확인:
   - [ ] "받은 초대 (1)" 섹션 표시됨
   - [ ] 초대 카드에 학원명 표시
   - [ ] 역할: 학생
   - [ ] 만료: X일 후
   - [ ] "수락" / "거절" 버튼 있음
5. "수락" 버튼 클릭
6. 확인:
   - [ ] SnackBar: "학생(으)로 등록되었습니다!"
   - [ ] 화면 전환: StudentShell로 이동
```

### 로그 확인

```
[NoAcademyShell] 초대 목록 로딩 시작
[NoAcademyShell] 유저 이메일: maknae12@gmail.com
[InvitationService] Fetching invitations for email: maknae12@gmail.com
[InvitationService] Found 1 valid invitations for maknae12@gmail.com
[NoAcademyShell] 초대 1개 로딩 완료
```

수락 시:
```
[NoAcademyShell] 초대 수락: xxx-xxx-xxx
[AcademyMemberService] Creating member from invitation...
[InvitationService] Using invitation: id=xxx, userId=xxx
[NoAcademyShell] 초대 수락 완료
```

---

## 🧪 테스트 3: 원장에서 초대 상태 확인

### 시나리오

```
1. owner_test1 다시 로그인
2. 관리 탭 → 초대 관리
3. 확인:
   - [ ] 아까 생성한 초대가 "사용됨" 상태로 변경됨
   - [ ] 체크 아이콘 (초록색) 표시
```

---

## 📝 문제 발생 시 체크리스트

### 초대 목록이 안 보일 때

1. 로그 확인: `[NoAcademyShell] 유저 이메일: ???`
   - 이메일이 null이면 Cognito 속성 문제
2. 로그 확인: `[InvitationService] Found 0 valid invitations`
   - targetEmail이 일치하는지 확인 (대소문자)
3. DataStore 동기화 문제일 수 있음
   - 앱 재시작 후 다시 시도

### 수락 버튼이 안 될 때

1. 로그 확인: `[AcademyMemberService] Error creating member: xxx`
2. 이미 해당 학원 멤버인지 확인

### 화면 전환 안 될 때

1. 로그 확인: AuthState 역할 판단 로그
2. AcademyMember가 제대로 생성됐는지 DynamoDB 확인

---

## ✅ 완료 체크리스트

### 테스트 1: 원장 초대 생성
- [ ] 이메일 입력 폼 표시됨
- [ ] 역할 선택 동작함
- [ ] 초대 생성 성공 SnackBar
- [ ] 초대 목록에 이메일 표시됨
- [ ] 빈 이메일 에러 처리
- [ ] 잘못된 형식 에러 처리

### 테스트 2: 피초대자 수락
- [ ] NoAcademyShell에 초대 목록 표시됨
- [ ] 학원명, 역할, 만료일 표시됨
- [ ] 수락 버튼 동작함
- [ ] 수락 후 StudentShell로 이동

### 테스트 3: 상태 확인
- [ ] 원장에서 초대 "사용됨" 표시

---

## 📝 결과 보고 템플릿

```markdown
# TASK_017_B 결과: 초대 플로우 디버깅

## 테스트 1: 원장 초대 생성
- 이메일 입력 폼: O/X
- 역할 선택: O/X
- 초대 생성: O/X
- 로그 정상: O/X

## 테스트 2: 피초대자 수락
- 초대 목록 표시: O/X
- 수락 버튼 동작: O/X
- Shell 전환: O/X
- 로그 정상: O/X

## 테스트 3: 상태 확인
- "사용됨" 표시: O/X

## 발견된 문제
- (있으면 기록)

## 로그 (중요한 것만)
- 
```

---

**완료 후 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_017_b_result.md`에 결과 저장할 것.**
