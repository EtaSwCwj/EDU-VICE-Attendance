# TASK_013 완료 보고서

**작성일**: 2025-12-21
**작업**: JoinByCodePage 안드로이드 백 버튼 처리 (PopScope)
**상태**: ✅ 완료

---

## 📋 작업 내용

### 1. 코드 수정

**파일**: `lib/features/invitation/join_by_code_page.dart`

**변경 내용**: `Scaffold`를 `PopScope`로 감싸기

```dart
// 수정 전
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    appBar: AppBar(...),
    body: ...,
  );
}

// 수정 후
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        safePrint('[JoinByCodePage] 안드로이드 백 버튼 클릭');
        context.go('/home');
      }
    },
    child: Scaffold(
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
      body: ...,
    ),
  );
}
```

**주요 변경점**:
1. `PopScope` 위젯으로 Scaffold 감싸기
2. `canPop: false` - 기본 pop 동작 비활성화
3. `onPopInvokedWithResult` - 백 버튼 감지 시 `/home`으로 이동
4. 로그 추가: `[JoinByCodePage] 안드로이드 백 버튼 클릭`

---

## 2. flutter analyze

```bash
cd /c/gitproject/EDU-VICE-Attendance/flutter_application_1
flutter analyze
```

**결과**:
```
Analyzing flutter_application_1...
No issues found! (ran in 8.4s)
```

✅ **에러**: 0개
✅ **경고**: 0개

---

## 3. 테스트 로그

### 핵심 로그

```
I/flutter (16054): [Splash] Attempting auto login...
I/flutter (16054): [AuthState] 세션 확인 중...
I/flutter (16054): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter (16054): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter (16054): [DEBUG] Cognito username: maknae12@gmail.com
I/flutter (16054): [DEBUG] AppUser 조회 결과: 없음
I/flutter (16054): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter (16054): [DEBUG] Cognito 그룹: []
I/flutter (16054): [DEBUG] hasMembership: false
I/flutter (16054): [DEBUG] 최종 role: null
I/flutter (16054): [DEBUG] 소속 없음 → memberships: []
I/flutter (16054): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
I/flutter (16054): [AuthState] 자동 로그인 성공 (기존 세션)
I/flutter (16054): [Splash] Auto login successful, navigating to home

(NoAcademyShell 표시)

I/flutter (16054): [NoAcademyShell] 초대코드 입력 버튼 클릭

(JoinByCodePage 진입)

I/flutter (16054): [JoinByCodePage] 뒤로가기 버튼 클릭

(AppBar 뒤로가기 버튼 → NoAcademyShell 복귀)

I/flutter (16054): [NoAcademyShell] 초대코드 입력 버튼 클릭

(다시 JoinByCodePage 진입)

D/Activity(16054): onKeyDown(KEYCODE_BACK), activity=com.eduvice.edu_vice_attendance.MainActivity@fdabe1a
I/flutter (16054): [JoinByCodePage] 안드로이드 백 버튼 클릭

✅ 앱 종료 안 됨 (NoAcademyShell로 복귀)
✅ Amplify DataStore 에러 발생 안 함
✅ 정상 동작
```

---

## 4. 테스트 결과

### ✅ 성공한 테스트

| 항목 | 상태 | 비고 |
|------|------|------|
| PopScope 추가 | ✅ | Scaffold 감싸기 완료 |
| canPop: false 설정 | ✅ | 기본 pop 동작 비활성화 |
| onPopInvokedWithResult | ✅ | context.go('/home') 정상 작동 |
| 로그 출력 | ✅ | `[JoinByCodePage] 안드로이드 백 버튼 클릭` |
| flutter analyze | ✅ | 0 에러 |
| AppBar 뒤로가기 버튼 | ✅ | 정상 작동 (이전과 동일) |
| **안드로이드 백 버튼** | ✅ | **NoAcademyShell 복귀 (앱 종료 안 됨)** |

---

## 5. TASK_010 vs TASK_013 비교

### TASK_010 (이전)

**문제**: 안드로이드 백 버튼 → 앱 크래시
```
D/Activity: onKeyDown(KEYCODE_BACK)
E/AndroidRuntime: FATAL EXCEPTION: main
E/AndroidRuntime: kotlin.UninitializedPropertyAccessException:
  lateinit property token has not been initialized
E/AndroidRuntime: at com.amazonaws.amplify.amplify_datastore.DataStoreHubEventStreamHandler.onCancel
```

**동작**:
- AppBar 뒤로가기 버튼 → ✅ 정상 (context.go('/home'))
- 안드로이드 백 버튼 → ❌ 앱 종료 (Amplify 에러)

### TASK_013 (현재)

**해결**: PopScope로 안드로이드 백 버튼 처리
```
D/Activity: onKeyDown(KEYCODE_BACK)
I/flutter: [JoinByCodePage] 안드로이드 백 버튼 클릭
(앱 정상 동작, NoAcademyShell 복귀)
```

**동작**:
- AppBar 뒤로가기 버튼 → ✅ 정상 (context.go('/home'))
- 안드로이드 백 버튼 → ✅ 정상 (PopScope → context.go('/home'))

---

## 6. 동작 플로우

### 정상 플로우 (안드로이드 백 버튼)

```
1. JoinByCodePage 진입
   ↓
2. 사용자가 안드로이드 백 버튼 클릭
   ↓
3. PopScope.onPopInvokedWithResult 호출
   ↓
4. didPop = false (canPop: false이므로)
   ↓
5. if (!didPop) 조건 만족
   ↓
6. 로그 출력: "[JoinByCodePage] 안드로이드 백 버튼 클릭"
   ↓
7. context.go('/home') 실행
   ↓
8. NoAcademyShell로 이동 ✅
```

---

## 7. PopScope vs WillPopScope

### WillPopScope (Deprecated)

```dart
// ❌ Deprecated (Flutter 3.12 이후)
return WillPopScope(
  onWillPop: () async {
    safePrint('[JoinByCodePage] 백 버튼 클릭');
    context.go('/home');
    return false;
  },
  child: Scaffold(...),
);
```

### PopScope (권장)

```dart
// ✅ 최신 방법 (Flutter 3.12 이후)
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (!didPop) {
      safePrint('[JoinByCodePage] 안드로이드 백 버튼 클릭');
      context.go('/home');
    }
  },
  child: Scaffold(...),
);
```

**차이점**:
- `WillPopScope`: 비동기 콜백 (`Future<bool>`)
- `PopScope`: 동기 콜백 + `canPop` 플래그로 명확한 제어
- `onPopInvokedWithResult`: pop 성공 여부(`didPop`)와 결과(`result`) 제공

---

## 8. 코드 분석

### canPop: false의 의미

```dart
PopScope(
  canPop: false,  // pop 불가능 → 기본 뒤로가기 동작 비활성화
  onPopInvokedWithResult: (didPop, result) {
    // didPop = false (canPop이 false이므로 실제 pop은 발생 안 함)
    if (!didPop) {
      // 여기서 커스텀 동작 수행
      context.go('/home');
    }
  },
  ...
)
```

- `canPop: true` → 기본 pop 동작 허용, `onPopInvokedWithResult`는 pop 후 호출
- `canPop: false` → 기본 pop 차단, `onPopInvokedWithResult`에서 커스텀 동작

---

## 9. 전체 로그 (요약)

<details>
<summary>펼쳐보기 (클릭)</summary>

```
Launching lib\main.dart on SM A356N in debug mode...
Running Gradle task 'assembleDebug'...                             15.1s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...           5.2s

I/flutter (16054): [main] 진입
I/flutter (16054): [main] Amplify 초기화 시작
I/flutter (16054): [Amplify] configure: SUCCESS
I/flutter (16054): [main] Amplify 초기화 완료
I/flutter (16054): [main] DI 초기화 시작
I/flutter (16054): [DI] Dependencies initialized with AWS repositories
I/flutter (16054): [main] DI 초기화 완료
I/flutter (16054): [main] EVAttendanceApp 실행

I/flutter (16054): [Splash] Attempting auto login...
I/flutter (16054): [AuthState] 세션 확인 중...
I/flutter (16054): [DEBUG] ========== 역할 판단 시작 ==========
I/flutter (16054): [DEBUG] Cognito userId: 24e80dbc-b091-7097-6825-b6bf1e5331ca
I/flutter (16054): [DEBUG] Cognito username: maknae12@gmail.com
I/flutter (16054): [DEBUG] AppUser 조회 결과: 없음
I/flutter (16054): [DEBUG] appUserId가 null이므로 AcademyMember 조회 스킵
I/flutter (16054): [DEBUG] Cognito 그룹: []
I/flutter (16054): [DEBUG] hasMembership: false
I/flutter (16054): [DEBUG] 최종 role: null
I/flutter (16054): [DEBUG] 소속 없음 → memberships: []
I/flutter (16054): [DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
I/flutter (16054): [AuthState] 자동 로그인 성공 (기존 세션)
I/flutter (16054): [Splash] Auto login successful, navigating to home

I/flutter (16054): [NoAcademyShell] 초대코드 입력 버튼 클릭
I/flutter (16054): [JoinByCodePage] 뒤로가기 버튼 클릭
I/flutter (16054): [NoAcademyShell] 초대코드 입력 버튼 클릭

D/Activity(16054): onKeyDown(KEYCODE_BACK), activity=com.eduvice.edu_vice_attendance.MainActivity@fdabe1a
I/flutter (16054): [JoinByCodePage] 안드로이드 백 버튼 클릭

(앱 계속 실행 중, NoAcademyShell로 복귀)

Lost connection to device.  ← 사용자가 홈 버튼 눌러서 앱 백그라운드로 이동
```

</details>

---

## ✅ 완료 체크리스트

- [x] JoinByCodePage에 PopScope 추가
- [x] canPop: false 설정
- [x] onPopInvokedWithResult에서 context.go('/home') 호출
- [x] 로그 추가: `[JoinByCodePage] 안드로이드 백 버튼 클릭`
- [x] flutter analyze 0 에러
- [x] 안드로이드 백 버튼 → NoAcademyShell 복귀 (앱 종료 안 됨)
- [x] AppBar 뒤로가기 버튼 정상 작동 (이전과 동일)
- [x] Amplify DataStore 에러 발생 안 함

---

## 📊 작업 통계

- **수정된 파일**: 1개 (`lib/features/invitation/join_by_code_page.dart`)
- **추가된 코드**: 10줄 (PopScope 래핑 + 로그)
- **테스트 시간**: 약 5분
- **flutter analyze**: 0 에러
- **안드로이드 백 버튼**: ✅ 정상 작동 (앱 종료 안 됨)
- **AppBar 뒤로가기**: ✅ 정상 작동 (이전과 동일)

---

## 🎯 TASK_010 vs TASK_013 결과 비교

| 항목 | TASK_010 | TASK_013 |
|------|----------|----------|
| AppBar 뒤로가기 | ✅ 정상 | ✅ 정상 |
| 안드로이드 백 버튼 | ❌ 앱 크래시 | ✅ 정상 복귀 |
| Amplify 에러 | ❌ 발생 | ✅ 없음 |
| 사용자 경험 | ⚠️ 불량 | ✅ 양호 |

---

**✅ TASK_013 완료 - 안드로이드 백 버튼 정상 처리 (PopScope)**
