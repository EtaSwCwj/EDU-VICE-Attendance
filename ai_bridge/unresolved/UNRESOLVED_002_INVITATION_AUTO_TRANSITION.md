# UNRESOLVED_002: 초대 수락 후 자동 화면 전환 UX 개선 필요

> 생성일: 2025-12-25
> 우선순위: 낮음 (기능은 동작함)
> 상태: 임시 해결책 적용됨

---

## 현재 상황

### 문제
초대 수락 후 **재로그인 없이** 바로 학원 화면으로 전환되지 않음

### 시도한 방법들 (모두 실패)
1. **Cognito 세션 강제 새로고침** (BIG_093)
   - `FetchAuthSessionOptions(forceRefresh: true)`
   - 결과: `context.go('/home')` 후 자동 로그아웃됨

2. **프로그래매틱 재로그인** (BIG_094)
   - 저장된 credential로 `signOut()` → `signIn()`
   - 결과: 앱 생명주기 문제로 백그라운드 전환됨

3. **refreshAuth + polling** (BIG_090~092)
   - Lambda 완료 대기 후 AuthState 갱신
   - 결과: GoRouter 타이밍 이슈로 화면 전환 실패

### 근본 원인 (추정)
- GoRouter의 `refreshListenable: auth` 설정
- `notifyListeners()` 호출 시 라우트 재빌드 타이밍 충돌
- Flutter/Cognito 세션 관리와 GoRouter 상태 관리 간 불일치

---

## 현재 임시 해결책 (BIG_095)

```dart
// no_academy_shell.dart - _acceptInvitation()

// 1. Invitation 업데이트
await Amplify.API.mutate(...);

// 2. Lambda 완료 대기
await Future.delayed(const Duration(seconds: 2));

// 3. 로그아웃 → 로그인 화면으로
await auth.signOut();
context.go('/login');
```

### 사용자 경험
1. 수락 클릭
2. 2초 로딩
3. "초대를 수락했습니다! 다시 로그인해주세요." 메시지
4. 로그인 화면으로 이동
5. **(수동으로 로그인 버튼 클릭 필요)**
6. 학원 홈 화면 진입

---

## 개선 방안 (향후 검토)

### Option A: 자동 로그인 트리거
로그인 화면 진입 시 자동 로그인 설정되어 있으면 바로 실행

```dart
// login_page.dart - initState()
@override
void initState() {
  super.initState();
  _checkAutoLogin();
}

Future<void> _checkAutoLogin() async {
  final prefs = await SharedPreferences.getInstance();
  final autoLogin = prefs.getBool('auto_login') ?? false;
  
  if (autoLogin) {
    // 자동으로 로그인 실행
    await _performLogin();
  }
}
```

### Option B: Splash 화면 경유
로그인 화면 대신 Splash로 보내서 자동 로그인 처리

```dart
// no_academy_shell.dart
await auth.signOut();
context.go('/splash');  // /login 대신 /splash
```

### Option C: GoRouter 구조 변경
`refreshListenable` 제거하고 수동 네비게이션으로 변경

### Option D: 앱 재시작
Flutter 엔진 레벨에서 앱 재시작 (SystemNavigator 등)

---

## 관련 파일

- `lib/features/home/no_academy_shell.dart` - 초대 수락 처리
- `lib/shared/services/auth_state.dart` - 인증 상태 관리
- `lib/app/app_router.dart` - GoRouter 설정
- `lib/features/auth/login_page.dart` - 로그인 화면

---

## 관련 보고서

- ai_bridge/report/big_090_report.md
- ai_bridge/report/big_092_report.md
- ai_bridge/report/big_093_report.md (Sonnet 거짓 보고 - 신뢰 불가)
- ai_bridge/report/big_094_report.md

---

## 결론

**기능은 정상 동작함.** 사용자가 한 번 더 로그인 버튼을 눌러야 하는 UX 이슈만 남음.

Phase 2 완료 후 시간 여유 있을 때 Option A 또는 Option B로 개선 검토.
