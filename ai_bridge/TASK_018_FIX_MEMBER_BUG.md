# TASK_018_FIX: 멤버 등록 버그 수정 + 테스트 데이터 정리

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_018_fix_result.md`

---

## 📋 배경

선임이 작성한 코드에 버그 있음. AcademyMember.userId에 저장하는 값이 잘못됨.

**AuthState에서 기대하는 값:** `AppUser.id` (UUID)
**선임이 저장한 값:** `AppUser.cognitoUsername` (이메일)

→ 로그인 시 역할 판단 실패

---

## 🔧 Step 1: 코드 버그 수정

### 파일: `lib/features/invitation/invitation_management_page.dart`

---

### 수정 1: _addMember() - userId 저장값 수정

**위치**: 약 95번째 줄

**기존 (잘못됨):**
```dart
final member = AcademyMember(
  academyId: widget.academyId,
  userId: targetUser.cognitoUsername,  // ← 잘못됨
  role: role,
);
```

**수정:**
```dart
final member = AcademyMember(
  academyId: widget.academyId,
  userId: targetUser.id,  // ← AppUser.id로 수정
  role: role,
);
```

---

### 수정 2: _loadMembers() - AppUser 조회 방식 수정

**위치**: 약 43번째 줄

**기존 (잘못됨):**
```dart
final users = await Amplify.DataStore.query(
  AppUser.classType,
  where: AppUser.COGNITOUSERNAME.eq(member.userId),
);
```

**수정:**
```dart
final users = await Amplify.DataStore.query(
  AppUser.classType,
  where: AppUser.ID.eq(member.userId),
);
```

---

## 🧹 Step 2: 테스트 데이터 정리

### maknae12@gmail.com 관련 데이터 전부 삭제

AWS 콘솔 또는 CLI로 아래 테이블에서 maknae12@gmail.com 관련 레코드 삭제:

```bash
# 1. AppUser 테이블 확인 및 삭제
# DynamoDB 콘솔 → AppUser-xxx 테이블 → email = "maknae12@gmail.com" 검색 → 삭제

# 2. AcademyMember 테이블 확인 및 삭제
# DynamoDB 콘솔 → AcademyMember-xxx 테이블 → 해당 userId 검색 → 삭제

# 3. Invitation 테이블 확인 및 삭제 (있다면)
# DynamoDB 콘솔 → Invitation-xxx 테이블 → targetEmail = "maknae12@gmail.com" 검색 → 삭제
```

**확인할 테이블 목록:**
- AppUser
- AcademyMember
- Invitation
- StudentSupporter (혹시나)

**삭제할 데이터:**
- email 또는 targetEmail = `maknae12@gmail.com`
- userId = `24e80dbc-b091-7097-6825-b6bf1e5331ca` (스크린샷에서 확인된 값)

---

## 🔧 Step 3: Cognito 사용자 삭제 (선택)

maknae12@gmail.com Cognito 계정도 삭제하려면:

```bash
aws cognito-idp admin-delete-user \
  --user-pool-id <USER_POOL_ID> \
  --username maknae12@gmail.com
```

또는 AWS 콘솔 → Cognito → User pools → 사용자 관리 → maknae12@gmail.com 삭제

---

## 🧪 Step 4: flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

0 에러 확인

---

## 🧪 Step 5: 테스트

### 5-1. 새 테스트 계정 생성

maknae12@gmail.com으로 회원가입 (앱에서 직접)

**확인:** AppUser 테이블에 레코드 생성됨

---

### 5-2. 원장 멤버 추가

```
1. owner_test1 로그인
2. 관리 탭 → 초대 관리 탭
3. "멤버 추가" FAB 클릭
4. 이메일: maknae12@gmail.com
5. 역할: 학생
6. "추가" 클릭
7. 확인: "OOO님을 학생(으)로 등록했습니다" SnackBar
8. 멤버 목록에 이름과 이메일 정상 표시
```

---

### 5-3. 피초대자 확인

```
1. owner_test1 로그아웃
2. maknae12@gmail.com 로그인
3. 확인: StudentShell로 바로 이동
```

---

## ✅ 완료 체크리스트

### 코드 수정
- [ ] _addMember(): `targetUser.cognitoUsername` → `targetUser.id`
- [ ] _loadMembers(): `AppUser.COGNITOUSERNAME` → `AppUser.ID`

### 데이터 정리
- [ ] AppUser 테이블: maknae12@gmail.com 삭제
- [ ] AcademyMember 테이블: 관련 레코드 삭제
- [ ] Invitation 테이블: 관련 레코드 삭제
- [ ] Cognito: maknae12@gmail.com 삭제 (선택)

### 테스트
- [ ] flutter analyze 0 에러
- [ ] maknae12@gmail.com 회원가입
- [ ] 원장 멤버 추가 성공
- [ ] 멤버 목록에 이름 정상 표시 (not "알 수 없음")
- [ ] 피초대자 로그인 시 StudentShell 이동

---

## 📝 결과 보고 템플릿

```markdown
# TASK_018_FIX 결과

## 코드 수정
- _addMember() 수정: O/X
- _loadMembers() 수정: O/X

## 데이터 정리
- AppUser 삭제: O/X
- AcademyMember 삭제: O/X
- Invitation 삭제: O/X (또는 해당없음)
- Cognito 삭제: O/X (또는 스킵)

## flutter analyze
- 에러: 0개 / X개

## 테스트
- 회원가입: O/X
- 멤버 추가: O/X
- 이름 표시: O/X (이전: "알 수 없음")
- 피초대자 Shell 이동: O/X

## 발견된 문제
- (있으면)

## 주요 로그
- (중요한 것만)
```

---

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_018_fix_result.md`에 저장할 것.**
