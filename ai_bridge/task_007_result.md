# TASK_007 완료 보고

**작성자**: 윈 후임 (Sonnet)
**작성일**: 2025-12-20
**상태**: ✅ 완료

---

## 1. 역할 판단 코드 위치

### 파일
- `lib/shared/services/auth_state.dart`

### 함수
- `_loadUserInfo()` (라인 142~245)

### 핵심 로직 (라인 161~186)
```dart
String role = 'student';  // ← 문제의 원인!
String academyId = 'default-academy';

if (appUserId != null) {
  final membership = await _getAcademyMemberByUserId(appUserId);
  if (membership != null) {
    role = membership['role'] ?? 'student';
    academyId = membership['academyId'] ?? 'default-academy';
    safePrint('[AuthState]   role=$role, academyId=$academyId');
  } else {
    final groups = await _getGroups();
    if (groups.contains('owners')) {
      role = 'owner';
    } else if (groups.contains('teachers')) {
      role = 'teacher';
    }
    // ← else 없음: 기본값 'student' 그대로 사용
  }
} else {
  final groups = await _getGroups();
  if (groups.contains('owners')) {
    role = 'owner';
  } else if (groups.contains('teachers')) {
    role = 'teacher';
  }
  // ← else 없음: 기본값 'student' 그대로 사용
}
```

---

## 2. 문제 원인

### 근본 원인
**`String role = 'student';` 기본값 문제**

#### 문제 시나리오 (maknae12@gmail.com)
1. Cognito 로그인 성공 ✅
2. AppUser 테이블 조회 → **없음** ❌
3. appUserId = null
4. AcademyMember 조회 **스킵** (appUserId가 null이므로)
5. Cognito 그룹 조회 → [] (그룹 없음)
6. `role = 'student'` **그대로 유지** ← 문제!
7. `memberships = [Membership(academyId: 'default-academy', role: 'student')]` 생성
8. app_router.dart에서 `memberships.isEmpty` 체크 → **false** (1개 있음)
9. `role = 'student'` → **StudentShell로 이동** ❌

### 기대 동작
- AppUser 없음 → AcademyMember 없음 → Cognito 그룹 없음
- → `memberships = []` (빈 리스트)
- → app_router.dart에서 `memberships.isEmpty` → **true**
- → **NoAcademyShell로 이동** ✅

---

## 3. 수정 내용

### 수정 파일
`lib/shared/services/auth_state.dart`

### 변경 사항

#### 3-1. role 기본값 제거
```dart
// 수정 전
String role = 'student';
String academyId = 'default-academy';

// 수정 후
String? role;  // nullable로 변경, 기본값 없음
String academyId = 'default-academy';
bool hasMembership = false;  // 추가
```

#### 3-2. 소속 판단 로직 추가
```dart
if (appUserId != null) {
  final membership = await _getAcademyMemberByUserId(appUserId);
  if (membership != null) {
    role = membership['role'] ?? 'student';
    academyId = membership['academyId'] ?? 'default-academy';
    hasMembership = true;  // ← 추가
    // ...
  } else {
    final groups = await _getGroups();
    if (groups.contains('owners')) {
      role = 'owner';
      hasMembership = true;  // ← 추가
    } else if (groups.contains('teachers')) {
      role = 'teacher';
      hasMembership = true;  // ← 추가
    }
  }
} else {
  final groups = await _getGroups();
  if (groups.contains('owners')) {
    role = 'owner';
    hasMembership = true;  // ← 추가
  } else if (groups.contains('teachers')) {
    role = 'teacher';
    hasMembership = true;  // ← 추가
  }
}
```

#### 3-3. 소속 없을 때 early return
```dart
// 소속이 없으면 memberships를 빈 리스트로
if (!hasMembership || role == null) {
  safePrint('[DEBUG] 소속 없음 → memberships: []');
  _user = Account(
    id: appUserId ?? cognitoUserId,
    name: userName,
    username: cognitoUsername,
    password: '',
    memberships: [],  // ← 빈 리스트
  );
  _academies = const [];
  _current = null;
  safePrint('[DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========');
  return;  // ← early return
}
```

#### 3-4. 디버그 로그 추가
```dart
safePrint('[DEBUG] ========== 역할 판단 시작 ==========');
safePrint('[DEBUG] Cognito userId: $cognitoUserId');
safePrint('[DEBUG] Cognito username: $cognitoUsername');
safePrint('[DEBUG] AppUser 조회 결과: ${appUser != null ? "있음" : "없음"}');
safePrint('[DEBUG] AcademyMember 조회 결과: ${membership != null ? "있음" : "없음"}');
safePrint('[DEBUG] Cognito 그룹: $groups');
safePrint('[DEBUG] hasMembership: $hasMembership');
safePrint('[DEBUG] 최종 role: $role');
safePrint('[DEBUG] ========== 역할 판단 끝 ==========');
```

---

## 4. 코드 변경 요약

### Before (잘못된 코드)
```dart
String role = 'student';  // ← 기본값이 문제
String academyId = 'default-academy';

if (appUserId != null) {
  final membership = await _getAcademyMemberByUserId(appUserId);
  if (membership != null) {
    role = membership['role'] ?? 'student';
    // ...
  } else {
    final groups = await _getGroups();
    if (groups.contains('owners')) {
      role = 'owner';
    } else if (groups.contains('teachers')) {
      role = 'teacher';
    }
    // ← else 없음: role='student' 그대로
  }
}
// role='student'로 memberships 생성 → StudentShell로 이동
```

### After (수정된 코드)
```dart
String? role;  // ← nullable, 기본값 없음
String academyId = 'default-academy';
bool hasMembership = false;

if (appUserId != null) {
  final membership = await _getAcademyMemberByUserId(appUserId);
  if (membership != null) {
    role = membership['role'] ?? 'student';
    hasMembership = true;
    // ...
  } else {
    final groups = await _getGroups();
    if (groups.contains('owners')) {
      role = 'owner';
      hasMembership = true;
    } else if (groups.contains('teachers')) {
      role = 'teacher';
      hasMembership = true;
    }
    // ← hasMembership=false, role=null 유지
  }
}

// 소속 없으면 early return
if (!hasMembership || role == null) {
  _user = Account(memberships: []);  // ← 빈 리스트
  return;  // NoAcademyShell로 이동
}
```

---

## 5. 디버그 로그 (앱 실행)

### 핵심 로그 (maknae12@gmail.com 로그인)

```
I/flutter ( 1910): [LoginPage] 버튼 클릭: 로그인
I/flutter ( 1910): [LoginPage] 로그인 시작: username=maknae12@gmail.com
I/flutter ( 1910): [AuthState] 로그인 시도: maknae12@gmail.com

I/flutter ( 1910): [AuthState] Step 1: Cognito 사용자 조회
I/flutter ( 1910): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter ( 1910): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter ( 1910): [DEBUG] Cognito username: maknae12@gmail.com

I/flutter ( 1910): [AuthState] Step 2: AppUser 조회
I/flutter ( 1910): [DEBUG] AppUser 조회 결과: 없음

I/flutter ( 1910): [AuthState] Step 3: AcademyMember 조회
I/flutter ( 1910): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter ( 1910): [DEBUG] Cognito 그룹: []

I/flutter ( 1910): [DEBUG] hasMembership: false
I/flutter ( 1910): [DEBUG] 최종 role: null
I/flutter ( 1910): [DEBUG] 소속 없음 → memberships: []
I/flutter ( 1910): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========

I/flutter ( 1910): [LoginPage] 로그인 성공
```

### 로그 분석

✅ **수정 성공 확인**
1. AppUser 조회 결과: **없음** ✅
2. AcademyMember 조회: **스킵** (appUserId가 null) ✅
3. Cognito 그룹: **[]** (빈 배열) ✅
4. hasMembership: **false** ✅
5. 최종 role: **null** ✅
6. memberships: **[]** (빈 리스트) ✅
7. **NoAcademyShell로 이동** ✅

### 전체 로그 (앱 시작 ~ 로그인)

<details>
<summary>펼쳐보기 (클릭)</summary>

```
Launching lib\main.dart on SM A356N in debug mode...
Running Gradle task 'assembleDebug'...                             15.9s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...           5.5s

I/flutter ( 1910): [main] 진입
I/flutter ( 1910): [main] Amplify 초기화 시작
I/flutter ( 1910): [Amplify] configure: SUCCESS
I/flutter ( 1910): [main] Amplify 초기화 완료
I/flutter ( 1910): [main] DI 초기화 시작
I/flutter ( 1910): [DI] Dependencies initialized with AWS repositories
I/flutter ( 1910): [main] DI 초기화 완료
I/flutter ( 1910): [main] EVAttendanceApp 실행

I/flutter ( 1910): [Splash] Attempting auto login...
I/flutter ( 1910): [AuthState] 세션 확인 중...
I/flutter ( 1910): [AuthState] Step 1: Cognito 사용자 조회
I/flutter ( 1910): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter ( 1910): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter ( 1910): [DEBUG] Cognito username: maknae12@gmail.com
I/flutter ( 1910): [AuthState] Step 2: AppUser 조회
I/flutter ( 1910): [DEBUG] AppUser 조회 결과: 없음
I/flutter ( 1910): [AuthState] Step 3: AcademyMember 조회
I/flutter ( 1910): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter ( 1910): [DEBUG] Cognito 그룹: []
I/flutter ( 1910): [DEBUG] hasMembership: false
I/flutter ( 1910): [DEBUG] 최종 role: null
I/flutter ( 1910): [DEBUG] 소속 없음 → memberships: []
I/flutter ( 1910): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
I/flutter ( 1910): [AuthState] 자동 로그인 성공 (기존 세션)
I/flutter ( 1910): [Splash] Auto login successful, navigating to home

(NoAcademyShell 표시됨)

I/flutter ( 1910): [AuthState] 로그아웃 완료
I/flutter ( 1910): [LoginPage] 진입
I/flutter ( 1910): [LoginPage] 저장된 자격증명 로드 시작
I/flutter ( 1910): [LoginPage] 저장된 자격증명 로드 완료

(maknae12@gmail.com 로그인 시도)

I/flutter ( 1910): [LoginPage] 버튼 클릭: 로그인
I/flutter ( 1910): [LoginPage] 로그인 시작: username=maknae12@gmail.com
I/flutter ( 1910): [AuthState] 로그인 시도: maknae12@gmail.com
I/flutter ( 1910): [AuthState] Step 1: Cognito 사용자 조회
I/flutter ( 1910): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter ( 1910): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter ( 1910): [DEBUG] Cognito username: maknae12@gmail.com
I/flutter ( 1910): [AuthState] Step 2: AppUser 조회
I/flutter ( 1910): [DEBUG] AppUser 조회 결과: 없음
I/flutter ( 1910): [AuthState] Step 3: AcademyMember 조회
I/flutter ( 1910): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter ( 1910): [DEBUG] Cognito 그룹: []
I/flutter ( 1910): [DEBUG] hasMembership: false
I/flutter ( 1910): [DEBUG] 최종 role: null
I/flutter ( 1910): [DEBUG] 소속 없음 → memberships: []
I/flutter ( 1910): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
I/flutter ( 1910): [LoginPage] 로그인 성공

(NoAcademyShell 재진입 확인)
```

</details>

---

## 6. 테스트 결과

### 수정 전 동작
- maknae12@gmail.com 로그인 → **StudentShell** ❌
- 3개 탭 (홈/수업/숙제) 표시
- 학생 역할로 잘못 인식
- 기본값 `role = 'student'`가 문제

### 수정 후 실제 동작 (테스트 완료)
- ✅ maknae12@gmail.com 로그인 → **NoAcademyShell**
- ✅ "초대코드로 참여하기" 버튼 표시
- ✅ 소속 없음 상태로 올바르게 인식
- ✅ memberships: [] (빈 리스트)

### 테스트 시나리오
1. ✅ flutter analyze: **0 에러**
2. ✅ 앱 실행 성공
3. ✅ maknae12@gmail.com 로그인 성공
4. ✅ NoAcademyShell 진입 확인
5. ✅ 디버그 로그로 동작 확인

---

## 7. flutter analyze

```
Analyzing flutter_application_1...
No issues found! (ran in 42.4s)
```

✅ **에러 0개**

---

## 8. 근본 원인 분석

### 왜 이런 문제가 발생했는가?

1. **레거시 코드 잔재**
   - 이전에 Student 테이블이 있었고, 모든 유저가 기본적으로 student였을 가능성
   - 당시에는 `role = 'student'` 기본값이 합리적이었을 수 있음

2. **신규 체계 전환 미완료**
   - AppUser + AcademyMember 체계로 전환했지만
   - 기본값 로직은 업데이트하지 않음
   - "소속 없음" 케이스 처리 누락

3. **테스트 부족**
   - 기존 유저(AppUser 있음)로만 테스트
   - 신규 가입 유저(AppUser 없음) 테스트 안 함

---

## 9. 추가 개선 제안

### 9-1. 회원가입 시 AppUser 자동 생성
**현재 문제**:
- Cognito 회원가입만 하고 AppUser는 생성 안 됨
- 로그인 시 AppUser 없어서 NoAcademyShell로 이동

**개선안**:
`register_page.dart`의 `_createUserInDatabase()` 함수가 실행되도록 보장
- 현재: 회원가입 성공 후 실행
- 확인 필요: maknae12@gmail.com의 경우 이 함수가 실행되었는지?

### 9-2. Cognito 그룹 자동 추가
**현재**:
- 신규 유저는 Cognito 그룹에 자동 추가 안 됨
- Lambda 트리거 또는 수동 추가 필요

**개선안**:
- Cognito PostConfirmation Lambda 트리거 설정
- 회원가입 완료 시 자동으로 `users` 그룹에 추가

### 9-3. UserSyncService 강화
**현재**:
- `user_sync_service.dart`가 Cognito → AppUser 동기화
- 하지만 로그인 시 WARNING만 찍고 실패해도 진행

**개선안**:
- 동기화 실패 시 재시도 로직
- AppUser 없으면 자동 생성

---

## 10. 관련 이슈

### maknae12@gmail.com 계정 상태
- ✅ Cognito: 존재 (CONFIRMED)
- ❌ AppUser: 없음
- ❌ AcademyMember: 없음
- ❌ Student (레거시): TASK_006에서 삭제됨

### 왜 AppUser가 없는가?
**추정**:
1. 회원가입 시 `_createUserInDatabase()` 실행 실패했거나
2. 수동으로 Cognito에만 계정 생성했거나
3. 이전에 AppUser가 있었는데 삭제되었거나

**확인 필요**:
- maknae12@gmail.com 회원가입 로그 확인
- `register_page.dart`의 `_createUserInDatabase()` 로그 확인

---

## ✅ 완료 체크리스트

- [x] 역할 판단 코드 위치 파악
- [x] 디버그 로그 추가
- [x] 코드 수정 (기본값 'student' 제거)
- [x] flutter analyze 에러 없음
- [x] 앱 실행 후 로그 수집
- [x] 문제 원인 파악
- [x] 수정 후 테스트 (NoAcademyShell 진입 확인)
- [x] 로그 분석 및 보고서 작성

---

## 📊 작업 통계

- **수정된 파일**: 1개 (`lib/shared/services/auth_state.dart`)
- **추가된 코드**: 약 60줄 (디버그 로그 + 로직 개선)
- **삭제된 코드**: 약 20줄 (기존 잘못된 로직)
- **테스트 시간**: 약 3분
- **flutter analyze**: 에러 0개

---

**✅ 작업 완료 - maknae12@gmail.com 로그인 시 NoAcademyShell로 정상 이동 확인**
