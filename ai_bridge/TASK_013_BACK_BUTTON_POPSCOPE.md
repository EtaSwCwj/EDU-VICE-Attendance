# TASK_013: JoinByCodePage 안드로이드 백 버튼 처리

> **작성자**: 윈선임 (메인 개발 4)
> **작성일**: 2025-12-21
> **담당**: 윈후임 (Sonnet)
> **결과 파일**: `C:\github\ai_bridge\task_013_result.md`
> **원칙**: 묻지 말고 끝까지 진행. 로그 필수. 앱 종료 = 테스트 끝.

---

## 📋 문제 상황

TASK_010에서 AppBar 뒤로가기 버튼은 수정됨.
하지만 **안드로이드 백 버튼 (◁)** 누르면 앱 크래시 발생.

```
E/AndroidRuntime: kotlin.UninitializedPropertyAccessException:
  lateinit property token has not been initialized
  at com.amazonaws.amplify.amplify_datastore.DataStoreHubEventStreamHandler.onCancel
```

**원인**: GoRouter 스택에 이전 페이지 없어서 pop 실패 → 앱 종료 → Amplify DataStore 에러

---

## 📋 작업 내용

### 1단계: JoinByCodePage에 PopScope 추가

**파일**: `lib/features/invitation/join_by_code_page.dart`

**수정할 것:**

`Scaffold`를 `PopScope`로 감싸기:

```dart
@override
Widget build(BuildContext context) {
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
      // ... 나머지 body 그대로
    ),
  );
}
```

**주의**: `WillPopScope`는 deprecated됨. `PopScope` 사용할 것.

---

### 2단계: flutter analyze

```bash
cd C:\github\EDU-VICE-Attendance\flutter_application_1
flutter analyze
```

0 에러 확인

---

### 3단계: 테스트

1. `flutter run` 실행
2. maknae12@gmail.com 로그인 → NoAcademyShell
3. "초대코드로 참여하기" 클릭 → JoinByCodePage
4. **안드로이드 백 버튼 (◁) 클릭**
5. **확인**: NoAcademyShell로 돌아가는가? (앱 종료 아님)

---

## 📝 로그 확인 포인트

```
[NoAcademyShell] 초대코드 입력 버튼 클릭
[JoinByCodePage] 안드로이드 백 버튼 클릭
[NoAcademyShell] 진입
```

**실패 시 (앱 종료):**
```
D/Activity: onKeyDown(KEYCODE_BACK)
E/AndroidRuntime: FATAL EXCEPTION
```

---

## ✅ 완료 체크리스트

- [ ] JoinByCodePage에 PopScope 추가
- [ ] canPop: false 설정
- [ ] onPopInvokedWithResult에서 context.go('/home') 호출
- [ ] 로그 추가: `[JoinByCodePage] 안드로이드 백 버튼 클릭`
- [ ] flutter analyze 0 에러
- [ ] 안드로이드 백 버튼 → NoAcademyShell 복귀 (앱 종료 안 됨)

---

## 📝 결과 보고 템플릿

```markdown
# TASK_013 결과: 안드로이드 백 버튼 처리

## 작업 내용
- 수정한 파일:
- 추가한 코드:

## flutter analyze
- 에러:
- 경고:

## 테스트 결과

### 안드로이드 백 버튼 (◁)
- 결과: (NoAcademyShell 복귀 / 앱 종료)

## 로그 (관련 부분)
```
(터미널 로그)
```

## 완료 체크리스트
- [ ] PopScope 추가
- [ ] flutter analyze 0 에러
- [ ] 백 버튼 → NoAcademyShell 복귀
```

---

**테스트 완료 후 `C:\github\ai_bridge\task_013_result.md`에 결과 저장할 것.**
