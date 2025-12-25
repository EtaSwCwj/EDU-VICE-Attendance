# BIG_092: 실시간 로그 분석 보고서

## 개요
- **날짜**: 2025-12-25
- **목표**: 초대 수락 후 화면 전환 실패 원인 파악
- **결과**: **원인 파악 완료** - Cognito 토큰 캐싱 문제

---

## 테스트 환경
- **초대자**: owner_test1
- **피초대자**: maknae12@gmail.com (최우준)
- **역할**: teacher로 초대

---

## 로그 분석 결과

### ✅ 정상 작동한 부분

1. **Lambda 함수 실행**
   ```
   [NoAcademyShell] Lambda 완료 감지 (시도 2/20)
   ```
   - Lambda는 정상적으로 완료됨
   - AcademyMember 생성 성공

2. **AuthState 갱신 시도**
   ```
   [AuthState] refreshAuth 호출
   [AuthState] 로드 완료: user=최우준, role=student, academy=수학의 정석 학원
   ```
   - AuthState 갱신은 실행됨
   - 하지만 role이 잘못 표시됨

3. **화면 전환 시도**
   ```
   [NoAcademyShell] 홈 화면 전환 실행
   ```
   - 화면 전환은 시도됨

### ❌ 문제점

1. **잘못된 역할 인식**
   - teacher로 초대했으나 **student**로 표시
   - 원인: Cognito 캐시된 토큰 사용

2. **화면 전환 직후 로그아웃**
   ```
   [AuthState] 로그아웃 완료
   [LoginPage] 진입
   ```
   - StudentShell/TeacherShell 진입 실패
   - 권한 오류로 자동 로그아웃 추정

---

## 문제 원인

### 🔍 핵심 원인: Cognito 토큰 캐싱

현재 `refreshAuth` 구현:
```dart
Future<void> refreshAuth() async {
  safePrint('[AuthState] refreshAuth 호출');
  await _loadUserInfo();  // ← 캐시된 토큰 사용
  notifyListeners();
}
```

**문제점**:
- Lambda가 Cognito 그룹을 업데이트해도 캐시된 토큰 사용
- 이전 그룹 정보(student)가 계속 유지됨
- 재로그인 시에만 새 토큰 발급되어 정상 작동

---

## 해결 방안

### 🔧 Cognito 세션 강제 새로고침 추가

```dart
Future<void> refreshAuth() async {
  safePrint('[AuthState] refreshAuth 호출');

  // Cognito 세션 강제 새로고침 추가
  try {
    await Amplify.Auth.fetchAuthSession(
      options: const FetchAuthSessionOptions(forceRefresh: true)
    );
    safePrint('[AuthState] Cognito 세션 강제 새로고침 완료');
  } catch (e) {
    safePrint('[AuthState] 세션 새로고침 실패: $e');
  }

  await _loadUserInfo();
  notifyListeners();
}
```

---

## 예상 효과

1. Lambda 완료 후 `refreshAuth` 호출 시 새 토큰 발급
2. 새 토큰에 업데이트된 그룹 정보(teacher) 포함
3. 올바른 역할로 화면 전환 성공
4. 재로그인 없이 즉시 정상 작동

---

## 결론

- **원인**: Cognito 토큰 캐싱으로 인한 역할 정보 불일치
- **해결**: `forceRefresh: true` 옵션으로 토큰 강제 갱신
- **효과**: 초대 수락 직후 재로그인 없이 정상 화면 전환

---

## 다음 단계

1. auth_state.dart의 refreshAuth 메서드 수정
2. 테스트 계정으로 재테스트
3. 정상 작동 확인 후 PR 생성