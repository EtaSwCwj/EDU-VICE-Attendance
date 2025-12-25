# TASK_010 완료 보고서

**작성일**: 2025-12-21
**작업**: JoinByCodePage 뒤로가기 버튼 추가 및 테스트
**상태**: ✅ 완료

---

## 📋 작업 내용

### 1. 코드 수정

**파일**: `lib/features/invitation/join_by_code_page.dart`

**변경 내용**:

```dart
// 수정 전
appBar: AppBar(
  title: const Text('초대코드 입력'),
),

// 수정 후
appBar: AppBar(
  title: const Text('초대코드 입력'),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      safePrint('[JoinByCodePage] 뒤로가기 버튼 클릭');
      context.go('/home');
    },
  ),
),
```

**주요 변경점**:
1. AppBar에 `leading` 파라미터 추가
2. IconButton으로 뒤로가기 버튼 구현
3. 로그 추가: `[JoinByCodePage] 뒤로가기 버튼 클릭`
4. **중요**: `context.pop()` 대신 `context.go('/home')` 사용
   - 이유: `/join` 라우트가 GoRouter에서 독립 페이지로 등록되어 있어 스택에서 pop 불가능
   - 해결: `/home`으로 직접 이동하여 NoAcademyShell로 돌아감

---

## 2. flutter analyze

```
Analyzing flutter_application_1...
No issues found! (ran in 8.6s)
```

✅ **에러: 0개**
✅ **경고: 0개**

---

## 3. 테스트 로그

### 핵심 로그 (앱 실행 ~ 뒤로가기 테스트)

```
I/flutter (15132): [Splash] Attempting auto login...
I/flutter (15132): [AuthState] 세션 확인 중...
I/flutter (15132): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter (15132): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter (15132): [DEBUG] Cognito username: maknae12@gmail.com
I/flutter (15132): [DEBUG] AppUser 조회 결과: 없음
I/flutter (15132): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter (15132): [DEBUG] Cognito 그룹: []
I/flutter (15132): [DEBUG] hasMembership: false
I/flutter (15132): [DEBUG] 최종 role: null
I/flutter (15132): [DEBUG] 소속 없음 → memberships: []
I/flutter (15132): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
I/flutter (15132): [AuthState] 자동 로그인 성공 (기존 세션)
I/flutter (15132): [Splash] Auto login successful, navigating to home

(NoAcademyShell 표시)

I/flutter (15132): [NoAcademyShell] 초대코드 입력 버튼 클릭

(JoinByCodePage 진입)

I/flutter (15132): [JoinByCodePage] 뒤로가기 버튼 클릭

(NoAcademyShell로 돌아감)

I/flutter (15132): [NoAcademyShell] 초대코드 입력 버튼 클릭

(다시 JoinByCodePage 진입 - 뒤로가기 정상 작동 확인)

D/Activity(15132): onKeyDown(KEYCODE_BACK), activity=com.eduvice.edu_vice_attendance.MainActivity@fdabe1a

(안드로이드 백 버튼 → 앱 종료)
```

---

## 4. 테스트 결과

### ✅ 성공한 테스트

| 항목 | 상태 | 비고 |
|------|------|------|
| AppBar 뒤로가기 버튼 추가 | ✅ | Icons.arrow_back 표시 |
| 뒤로가기 버튼 클릭 | ✅ | NoAcademyShell로 정상 이동 |
| 로그 출력 | ✅ | `[JoinByCodePage] 뒤로가기 버튼 클릭` |
| 재진입 테스트 | ✅ | 뒤로가기 후 다시 진입 가능 |
| flutter analyze | ✅ | 0 에러 |

### ⚠️ 알려진 이슈

**안드로이드 백 버튼 → 앱 종료**

```
E/AndroidRuntime(15132): kotlin.UninitializedPropertyAccessException:
  lateinit property token has not been initialized
E/AndroidRuntime(15132): at com.amazonaws.amplify.amplify_datastore.DataStoreHubEventStreamHandler.onCancel
```

- **원인**: Amplify DataStore 플러그인의 초기화 문제
- **발생 위치**: JoinByCodePage에서 안드로이드 백 버튼 누를 때
- **영향**: 앱 전체 종료 (크래시)
- **TASK_010 범위**: 이 이슈는 TASK_010 범위 밖 (Amplify 플러그인 문제)
- **해결 방법**:
  1. `android:enableOnBackInvokedCallback="true"` AndroidManifest.xml에 추가 (권장)
  2. Amplify DataStore 플러그인 업데이트
  3. WillPopScope로 백 버튼 처리

---

## 5. 동작 플로우

### 정상 플로우 (AppBar 뒤로가기 버튼)

```
1. NoAcademyShell 진입
   ↓
2. "초대코드로 참여하기" 클릭
   ↓
3. JoinByCodePage 진입 (AppBar 뒤로가기 버튼 표시)
   ↓
4. 뒤로가기 버튼 클릭
   ↓
5. context.go('/home') 실행
   ↓
6. NoAcademyShell로 돌아감 ✅
```

### 문제 플로우 (안드로이드 백 버튼)

```
1. JoinByCodePage 진입
   ↓
2. 안드로이드 백 버튼 클릭
   ↓
3. GoRouter 기본 동작 (pop 시도)
   ↓
4. 앱 종료 프로세스 시작
   ↓
5. Amplify DataStore onCancel 호출
   ↓
6. token 미초기화 에러 ❌
   ↓
7. 앱 크래시
```

---

## 6. 코드 분석

### 왜 context.pop()이 실패했나?

**app_router.dart 라우트 구조**:

```dart
GoRoute(
  path: '/home',
  builder: (_, __) => NoAcademyShell(),
),

GoRoute(
  path: '/join',
  builder: (_, __) => const JoinByCodePage(),
),
```

- `/join`은 `/home`의 하위 라우트가 아님
- 독립적인 최상위 라우트로 등록됨
- GoRouter 스택에 이전 페이지가 없어서 `context.pop()` 실패
- 에러: `GoError: There is nothing to pop`

### 해결 방법

```dart
// ❌ 실패
context.pop();  // GoError: There is nothing to pop

// ✅ 성공
context.go('/home');  // /home으로 직접 이동 → NoAcademyShell
```

---

## 7. 전체 로그

<details>
<summary>펼쳐보기 (클릭)</summary>

```
Launching lib\main.dart on SM A356N in debug mode...
Running Gradle task 'assembleDebug'...                             14.1s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...           5.5s

I/flutter (15132): [main] 진입
I/flutter (15132): [main] Amplify 초기화 시작
I/flutter (15132): [Amplify] configure: SUCCESS
I/flutter (15132): [main] Amplify 초기화 완료
I/flutter (15132): [main] DI 초기화 시작
I/flutter (15132): [DI] Dependencies initialized with AWS repositories
I/flutter (15132): [main] DI 초기화 완료
I/flutter (15132): [main] EVAttendanceApp 실행

I/flutter (15132): [Splash] Attempting auto login...
I/flutter (15132): [AuthState] 세션 확인 중...
I/flutter (15132): [AuthState] Step 1: Cognito 사용자 조회
I/flutter (15132): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter (15132): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter (15132): [DEBUG] Cognito username: maknae12@gmail.com
I/flutter (15132): [AuthState] Step 2: AppUser 조회
I/flutter (15132): [DEBUG] AppUser 조회 결과: 없음
I/flutter (15132): [AuthState] Step 3: AcademyMember 조회
I/flutter (15132): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter (15132): [DEBUG] Cognito 그룹: []
I/flutter (15132): [DEBUG] hasMembership: false
I/flutter (15132): [DEBUG] 최종 role: null
I/flutter (15132): [DEBUG] 소속 없음 → memberships: []
I/flutter (15132): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
I/flutter (15132): [AuthState] 자동 로그인 성공 (기존 세션)
I/flutter (15132): [Splash] Auto login successful, navigating to home

(NoAcademyShell 표시)

I/flutter (15132): [NoAcademyShell] 초대코드 입력 버튼 클릭

(JoinByCodePage 진입)

I/flutter (15132): [JoinByCodePage] 뒤로가기 버튼 클릭

(NoAcademyShell로 돌아감)

I/flutter (15132): [NoAcademyShell] 초대코드 입력 버튼 클릭

(다시 JoinByCodePage 진입)

D/Activity(15132): onKeyDown(KEYCODE_BACK), activity=com.eduvice.edu_vice_attendance.MainActivity@fdabe1a

I/flutter (15132): handleAppVisibility mAppVisible = true visible = false

E/AndroidRuntime(15132): FATAL EXCEPTION: main
E/AndroidRuntime(15132): Process: com.eduvice.edu_vice_attendance, PID: 15132
E/AndroidRuntime(15132): java.lang.RuntimeException: Unable to destroy activity
E/AndroidRuntime(15132): Caused by: kotlin.UninitializedPropertyAccessException:
  lateinit property token has not been initialized
E/AndroidRuntime(15132): at com.amazonaws.amplify.amplify_datastore.DataStoreHubEventStreamHandler.onCancel
```

</details>

---

## ✅ 완료 체크리스트

- [x] JoinByCodePage에 AppBar leading 뒤로가기 버튼 추가
- [x] 로그 추가: `[JoinByCodePage] 뒤로가기 버튼 클릭`
- [x] flutter analyze 0 에러
- [x] 뒤로가기 버튼 클릭 → NoAcademyShell 정상 이동
- [x] 재진입 테스트 (뒤로가기 후 다시 초대코드 입력 페이지 진입)
- [x] 로그 수집 및 분석
- [ ] 안드로이드 백 버튼 → 앱 종료 안 됨 (Amplify 플러그인 이슈, TASK_010 범위 밖)

---

## 📊 작업 통계

- **수정된 파일**: 1개 (`lib/features/invitation/join_by_code_page.dart`)
- **추가된 코드**: 8줄 (AppBar leading 버튼 + 로그)
- **테스트 시간**: 약 5분
- **flutter analyze**: 0 에러
- **뒤로가기 버튼**: ✅ 정상 작동
- **안드로이드 백 버튼**: ❌ 앱 크래시 (Amplify 이슈)

---

## 🔧 후속 작업 권장 사항

### 1. AndroidManifest.xml 수정 (안드로이드 백 버튼 처리)

**파일**: `android/app/src/main/AndroidManifest.xml`

```xml
<application
    android:enableOnBackInvokedCallback="true"
    ...>
```

### 2. WillPopScope 추가 (옵션)

**파일**: `lib/features/invitation/join_by_code_page.dart`

```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: () async {
      safePrint('[JoinByCodePage] 안드로이드 백 버튼 클릭');
      context.go('/home');
      return false; // 기본 동작 방지
    },
    child: Scaffold(
      appBar: AppBar(...),
      ...
    ),
  );
}
```

---

**✅ TASK_010 완료 - JoinByCodePage 뒤로가기 버튼 정상 작동**
