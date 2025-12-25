# BIG_089: 초대 수락 후 자동 화면 전환

> 생성일: 2025-12-25
> 목표: 초대 수락 성공 후 재로그인 없이 바로 학원 홈 화면으로 이동

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 초대 수락 성공 후 **재로그인 없이** 바로 학원 홈 화면으로 이동
- 사용자 경험 개선

### 테스트 시나리오
```
1. maknae12@gmail.com 로그인 → "받은 초대" 화면
2. "수락" 버튼 클릭
3. 성공 메시지 표시
4. 바로 학원 홈 화면으로 자동 이동 (재로그인 필요 없음!)
```

---

## 문제 상황

**현재 동작:**
```
수락 클릭 → 성공 → 그대로 NoAcademyShell에 머무름 → 로그아웃 → 재로그인 → 학원 화면
```

**기대 동작:**
```
수락 클릭 → 성공 → 바로 학원 화면으로 자동 이동
```

---

## ⚠️ 필수: Opus는 직접 작업 금지!

### Sonnet 호출 방법
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 수정 파일: lib/features/home/no_academy_shell.dart

---

## 원인 분석

`_acceptInvitation()` 함수에서:
1. Invitation 업데이트 ✅
2. Lambda가 AcademyMember 생성 ✅
3. `auth.refreshAuth()` 호출 ✅
4. **화면 전환 안 됨** ❌

`refreshAuth()` 호출해도 현재 위젯(NoAcademyShell)이 자동으로 교체되지 않음.

---

## 스몰스텝

### 1. 코드 확인 (Sonnet)

- [ ] `lib/features/home/no_academy_shell.dart` 의 `_acceptInvitation()` 확인
- [ ] `refreshAuth()` 후 화면 전환 로직 확인

### 2. 수정 방안

**방안 A: Navigator로 강제 이동**
```dart
await auth.refreshAuth();

// 성공 시 홈으로 강제 이동
if (mounted) {
  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
}
```

**방안 B: Consumer/Provider로 자동 감지**
- AuthState 변경 시 자동으로 화면 전환되도록 설정
- 상위 위젯에서 처리

### 3. 수정 구현 (Sonnet)

- [ ] 파일: `lib/features/home/no_academy_shell.dart`
- [ ] `_acceptInvitation()` 함수에서 `refreshAuth()` 후 화면 전환 추가
- [ ] safePrint 로그 추가

### 4. flutter analyze

```bash
flutter analyze
```
- [ ] 에러 0개 확인

---

## 로그 저장 (필수!)

- [ ] ai_bridge/logs/big_089_step_01.log (코드 확인)
- [ ] ai_bridge/logs/big_089_step_03.log (수정 완료)
- [ ] ai_bridge/logs/big_089_step_04.log (flutter analyze)

---

## 완료 조건

1. 코드 수정 완료
2. flutter analyze 에러 0개
3. 보고서 작성 완료 (ai_bridge/report/big_089_report.md)

**⚠️ 테스트는 CP가 별도로 진행 (이 지시서에서는 코드 수정만!)**
