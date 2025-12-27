# go_router 사용 패턴

> 이 프로젝트는 go_router 사용. Navigator API 아님!

---

## 🚨 절대 사용 금지

```dart
// ❌ 동작 안 함
Navigator.pushNamed(context, '/path')
Navigator.of(context).push(...)
Navigator.of(context).pop()
```

---

## ✅ 올바른 사용법

```dart
import 'package:go_router/go_router.dart';

// 스택에 추가 (뒤로가기 가능)
context.push('/path')

// 스택 교체 (뒤로가기 불가)
context.go('/path')

// 뒤로가기
context.pop()

// 파라미터 전달
context.push('/user/123')
context.go('/settings/teacher')
```

---

## ⚠️ 라우터 순서 주의

### 문제 상황
```dart
routes: [
  GoRoute(path: '/settings/:role', ...),   // 와일드카드
  GoRoute(path: '/settings/api-key', ...),  // 구체적 경로
]
```
→ `/settings/api-key` 요청 시 `:role = 'api-key'`로 매칭됨!

### 해결책
```dart
routes: [
  GoRoute(path: '/settings/api-key', ...),  // 구체적 경로 먼저!
  GoRoute(path: '/settings/:role', ...),    // 와일드카드 나중
]
```

---

## 📁 라우터 파일 위치

```
lib/app/app_router.dart
```

---

## 🔧 파라미터 접근

```dart
GoRoute(
  path: '/user/:userId',
  builder: (context, state) {
    final userId = state.pathParameters['userId'] ?? '';
    return UserPage(userId: userId);
  },
),
```

---

## 💡 팁

1. **redirect에서 null 반환** = 리다이렉트 안 함
2. **refreshListenable** = AuthState 변경 시 자동 리프레시
3. **debugLogDiagnostics: true** = 라우팅 디버그 로그
