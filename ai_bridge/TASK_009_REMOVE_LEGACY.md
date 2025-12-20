# TASK_009: 레거시 코드 제거 및 초대 플로우 테스트

> **작성자**: 윈 선임 (Opus)  
> **작성일**: 2025-12-20  
> **담당**: 윈 후임 (Sonnet)  
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수. 앱 종료 = 테스트 끝.

---

## 📋 문제 상황

UserSyncService가 역할 없는 유저를 **레거시 Student 테이블에 자동 생성**하고 있음.

```
[UserSyncService] !  WARNING: User has no role
[UserSyncService] !  Will create as Student by default...
[UserSyncService] → Syncing to Student table...
```

이 때문에 초대 없이도 학생으로 등록됨.

---

## 📋 작업 내용

### 1단계: 레거시 코드 위치 찾기

```bash
cd /c/gitproject/EDU-VICE-Attendance/flutter_application_1

# UserSyncService 파일 찾기
find lib -name "*sync*" -type f

# Student 테이블 쓰는 코드 찾기
grep -rn "Student\." lib/ --include="*.dart" | grep -v "StudentSupporter" | head -30

# _syncToStudentTable 함수 찾기
grep -rn "_syncToStudentTable" lib/ --include="*.dart"
```

---

### 2단계: UserSyncService 수정

**파일**: `lib/shared/services/user_sync_service.dart` (추정)

**제거할 로직:**
- "Will create as Student by default" 부분
- `_syncToStudentTable()` 호출 부분
- Student/Teacher 테이블 자동 생성 전체

**변경 후 동작:**
- 역할 없는 유저 → 아무것도 안 함 (초대 받을 때까지 대기)
- 로그: `[UserSyncService] 역할 없음 - 초대 대기 상태`

---

### 3단계: Student 테이블 다시 비우기

```bash
# Student 테이블 스캔
aws dynamodb scan --table-name Student-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --output json

# maknae12@gmail.com 삭제 (id 확인 후)
aws dynamodb delete-item \
  --table-name Student-3ozlrdq2pvesbe2mcnxgs5e6nu-dev \
  --key '{"id":{"S":"[조회된_id]"}}'

# 삭제 확인
aws dynamodb scan --table-name Student-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --select "COUNT"
```

---

### 4단계: 테스트 플로우

1. **maknae12@gmail.com 로그인** → NoAcademyShell (Student 자동 생성 안 됨 확인)
2. **로그아웃**
3. **owner_test1 로그인** → OwnerHomeShell
4. **관리 탭 → 초대 관리 탭**
5. **초대코드 생성** (역할: student)
6. **생성된 코드 메모**
7. **로그아웃**
8. **maknae12@gmail.com 로그인** → NoAcademyShell
9. **"초대코드로 참여하기" 클릭**
10. **초대코드 입력**
11. **AcademyMember 생성 → StudentShell 진입**

---

### 5단계: 로그 확인 포인트

**수정 후 maknae12@gmail.com 로그인:**
```
[UserSyncService] 역할 없음 - 초대 대기 상태
[DEBUG] hasMembership: false
[DEBUG] 소속 없음 → memberships: []
[DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
```

**초대코드 입력 시:**
```
[JoinByCodePage] 초대코드 입력: XXXXXX
[InvitationService] Looking up invitation...
[InvitationService] Valid invitation found
[AcademyMemberService] Creating member...
[AcademyMemberService] Member created
[JoinByCodePage] 성공적으로 참여
```

---

## ✅ 완료 체크리스트

- [ ] UserSyncService 레거시 코드 위치 찾기
- [ ] Student/Teacher 자동 생성 로직 제거
- [ ] 로그 추가: `[UserSyncService] 역할 없음 - 초대 대기 상태`
- [ ] Student 테이블 비우기 (maknae12@gmail.com)
- [ ] flutter analyze 0 에러
- [ ] maknae12@gmail.com 로그인 → Student 자동 생성 안 됨 확인
- [ ] owner_test1 → 초대코드 생성
- [ ] maknae12@gmail.com → 초대코드 입력
- [ ] AcademyMember 생성 확인
- [ ] StudentShell 진입 확인

---

## 📝 완료 보고

`C:\github\ai_bridge\task_009_result.md`에 결과 작성:

```markdown
# TASK_009 완료 보고

**상태**: ✅ 완료 / ❌ 실패

## 1. 제거한 레거시 코드
- 파일: ???
- 제거한 함수/로직: ???

## 2. Student 테이블
- 삭제 전 Count: ???
- 삭제 후 Count: 0

## 3. flutter analyze
(결과)

## 4. 테스트 로그 (전체)
```
(터미널 로그 전체 붙여넣기)
```

## 5. 테스트 결과
- maknae12@gmail.com Student 자동 생성 안 됨: ✅/❌
- owner_test1 초대코드 생성: ✅/❌
- 생성된 코드: XXXXXX
- maknae12@gmail.com 초대코드 입력: ✅/❌
- AcademyMember 생성: ✅/❌
- StudentShell 진입: ✅/❌

## 6. 이슈
(있으면 작성)
```
