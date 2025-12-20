# TASK_010: JoinByCodePage 뒤로가기 버튼 추가

> **작성자**: 윈 선임 (Opus)  
> **작성일**: 2025-12-20  
> **담당**: 윈 후임 (Sonnet)  
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수. 앱 종료 = 테스트 끝.

---

## 📋 문제 상황

JoinByCodePage (초대코드 입력 페이지)에:
1. AppBar에 뒤로가기 버튼 없음
2. 안드로이드 백 버튼 누르면 앱 종료됨

---

## 📋 작업 내용

### 1단계: JoinByCodePage 수정

**파일**: `lib/features/invitation/join_by_code_page.dart`

**추가할 것:**

1. AppBar에 leading 버튼 추가:
```dart
AppBar(
  title: const Text('초대코드 입력'),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      safePrint('[JoinByCodePage] 뒤로가기 버튼 클릭');
      context.pop();  // 또는 context.go('/home');
    },
  ),
),
```

2. 로그 추가:
```dart
safePrint('[JoinByCodePage] 뒤로가기 버튼 클릭');
```

---

### 2단계: 테스트

1. maknae12@gmail.com 로그인 → NoAcademyShell
2. "초대코드로 참여하기" 클릭 → JoinByCodePage
3. **뒤로가기 버튼 클릭** → NoAcademyShell로 돌아감 확인
4. 안드로이드 백 버튼 → NoAcademyShell로 돌아감 확인 (앱 종료 안 됨)

---

### 3단계: 로그 확인

```
[JoinByCodePage] 진입
[JoinByCodePage] 뒤로가기 버튼 클릭
[NoAcademyShell] 진입
```

---

## ✅ 완료 체크리스트

- [ ] JoinByCodePage에 AppBar leading 뒤로가기 버튼 추가
- [ ] 로그 추가
- [ ] flutter analyze 0 에러
- [ ] 뒤로가기 버튼 클릭 → NoAcademyShell 돌아감
- [ ] 안드로이드 백 버튼 → 앱 종료 안 됨

---

## 📝 완료 보고

`C:\github\ai_bridge\task_010_result.md`에 결과 작성
