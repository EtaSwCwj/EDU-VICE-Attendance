# TASK_019: maknae12 데이터 정리 + 코드 버그 수정

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_019_result.md`

---

## 📋 배경

TASK_017_B 테스트 결과:
1. maknae12@gmail.com → Cognito에는 있지만 **AppUser 테이블에 없음**
2. 기존 AcademyMember → **레거시 데이터** (userId가 Cognito userId로 저장됨)
3. 선임 코드 버그 → `targetUser.cognitoUsername` 대신 `targetUser.id` 사용해야 함

---

## 🧹 Step 1: maknae12@gmail.com 데이터 전부 삭제

### 1-1. DynamoDB 테이블 정리

AWS 콘솔 접속 → DynamoDB → 각 테이블에서 검색 후 삭제

**삭제할 데이터:**

| 테이블 | 검색 조건 | 삭제 |
|--------|----------|------|
| AppUser-xxx | email = "maknae12@gmail.com" | 있으면 삭제 |
| AcademyMember-xxx | userId = "24e80dbc-b091-7097-6825-b6bf1e5331ca" | 삭제 |
| Invitation-xxx | targetEmail = "maknae12@gmail.com" | 있으면 삭제 |
| StudentSupporter-xxx | 관련 레코드 | 있으면 삭제 |

**확인 방법:**
```
DynamoDB 콘솔 → 테이블 선택 → "항목 탐색" → 필터 추가 → 검색 → 삭제
```

### 1-2. Cognito 사용자 삭제

AWS 콘솔 → Cognito → User pools → 사용자 검색 → maknae12@gmail.com 삭제

또는 CLI:
```bash
aws cognito-idp admin-delete-user \
  --user-pool-id <USER_POOL_ID> \
  --username maknae12@gmail.com
```

**User Pool ID 확인:**
`amplifyconfiguration.dart` 또는 AWS 콘솔에서 확인

---

## 🔧 Step 2: 코드 버그 수정

### 파일: `lib/features/invitation/invitation_management_page.dart`

---

### 수정 1: _addMember() - userId 저장값

**위치**: 약 95줄 부근

**찾을 코드:**
```dart
final member = AcademyMember(
  academyId: widget.academyId,
  userId: targetUser.cognitoUsername,
  role: role,
);
```

**수정:**
```dart
final member = AcademyMember(
  academyId: widget.academyId,
  userId: targetUser.id,  // cognitoUsername → id
  role: role,
);
```

---

### 수정 2: _loadMembers() - AppUser 조회

**위치**: 약 43줄 부근

**찾을 코드:**
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

## 🧪 Step 3: flutter analyze

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

0 에러 확인

---

## 🧪 Step 4: 앱 재시작 + 회원가입

```bash
flutter run
```

### 4-1. maknae12@gmail.com 회원가입

1. 앱 실행 → 로그인 화면
2. "회원가입" 버튼
3. 이메일: maknae12@gmail.com
4. 비밀번호: (원하는 거)
5. 이름: 막내
6. 가입 완료

**확인할 로그:**
```
[UserSyncService] syncCurrentUser 시작
[UserSyncService] AppUser 생성 완료: id=xxx
```

**DynamoDB 확인:**
AppUser 테이블에 maknae12@gmail.com 레코드 생성됨

---

## 🧪 Step 5: 원장 멤버 추가 테스트

### 5-1. owner_test1 로그인

```
1. maknae12 로그아웃
2. owner_test1 로그인
3. 관리 탭 → 초대 관리 탭
```

### 5-2. 멤버 추가

```
1. FAB "멤버 추가" 클릭
2. 이메일: maknae12@gmail.com
3. 역할: 학생
4. "추가" 클릭
```

**성공 시:**
- SnackBar: "막내님을 학생(으)로 등록했습니다"
- 멤버 목록에 "막내" 표시 (not "알 수 없음")

**실패 시:**
- SnackBar에 에러 메시지 확인
- 로그 확인

---

## 🧪 Step 6: 피초대자 확인

```
1. owner_test1 로그아웃
2. maknae12@gmail.com 로그인
3. 확인: StudentShell로 바로 이동
```

**확인할 로그:**
```
[DEBUG] AcademyMember 조회 결과: 있음 (role=student)
[DEBUG] ========== 역할 판단 끝 (role=student) ==========
```

---

## ✅ 완료 체크리스트

### Step 1: 데이터 정리
- [ ] AppUser 테이블: maknae12 삭제 (있으면)
- [ ] AcademyMember 테이블: userId=24e80dbc... 삭제
- [ ] Invitation 테이블: targetEmail=maknae12 삭제 (있으면)
- [ ] Cognito: maknae12@gmail.com 삭제

### Step 2: 코드 수정
- [ ] _addMember(): cognitoUsername → id
- [ ] _loadMembers(): COGNITOUSERNAME → ID

### Step 3: 빌드
- [ ] flutter analyze 0 에러

### Step 4: 회원가입
- [ ] maknae12@gmail.com 회원가입 성공
- [ ] AppUser 테이블에 레코드 생성됨

### Step 5: 멤버 추가
- [ ] owner_test1 멤버 추가 성공
- [ ] 멤버 목록에 이름 정상 표시

### Step 6: 피초대자
- [ ] maknae12 로그인 → StudentShell 이동

---

## 📝 결과 보고 템플릿

```markdown
# TASK_019 결과

## Step 1: 데이터 정리
- AppUser 삭제: O/X/해당없음
- AcademyMember 삭제: O/X
- Invitation 삭제: O/X/해당없음
- Cognito 삭제: O/X

## Step 2: 코드 수정
- _addMember() 수정: O/X
- _loadMembers() 수정: O/X

## Step 3: flutter analyze
- 에러: 0개 / X개

## Step 4: 회원가입
- maknae12 회원가입: O/X
- AppUser 생성 확인: O/X

## Step 5: 멤버 추가
- 멤버 추가 성공: O/X
- 이름 표시: O/X (이전: "알 수 없음")

## Step 6: 피초대자
- StudentShell 이동: O/X

## 발견된 문제
- (있으면)

## 주요 로그
- (중요한 것만)
```

---

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\task_019_result.md`에 저장할 것.**
