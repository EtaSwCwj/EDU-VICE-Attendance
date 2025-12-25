# 자주 쓰는 패턴

> "이거 어떻게 하더라?" 할 때 참고

---

## 🚀 실행 패턴

### 수동 모드 (Opus-Sonnet 체인)

```bash
npm run claude:opus
# 빅스텝 명령어 복붙
# Opus가 Sonnet 부려서 작업
# "테스트 종료" 입력으로 마무리
```

### Sonnet 호출 (Opus가 사용)

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "스몰스텝 내용"
```

---

## 🔄 듀얼 디버깅 패턴

### Sonnet 동시 호출

```bash
# Opus가 이 두 명령을 동시에 실행:

# Sonnet 1 - 폰 빌드
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "cd flutter_application_1 && flutter run -d RFCY40MNBLL"

# Sonnet 2 - 웹 빌드 (동시에!)
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "cd flutter_application_1 && flutter run -d chrome --web-port=8080"
```

### 왜 동시 호출?

- 각 `claude` 명령은 별도 프로세스
- 순차 호출하면 첫 번째가 블로킹
- 동시 호출해야 진짜 "듀얼"

---

## 📝 빅스텝 템플릿

### ⚠️ 필수 규칙 (모든 지시서에 포함)

```markdown
## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.

### Sonnet 호출 방법
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업 내용"

### 예외 (Opus가 직접 해도 되는 것)
- AWS CLI (인증 필요)
- 시스템 환경변수 접근
- 권한 필요한 명령

## 📊 진행도 업데이트 규칙
각 스몰스텝 완료 시 지시서 파일에 진행도 업데이트:

### 진행도 표시 형식
- [ ] 미완료
- [x] 완료

### 업데이트 위치
지시서 파일의 "스몰스텝" 섹션에 체크박스 추가
```

---

### 듀얼 디버깅

```markdown
# BIG_XXX: 듀얼 디버깅

## 환경
- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 폰 디바이스: RFCY40MNBLL
- 웹 포트: 8080

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."

## 스몰스텝 (진행 시 체크박스 업데이트!)
- [ ] 1. Sonnet 호출: flutter devices로 디바이스 확인
- [ ] 2. Sonnet 2개 **동시** 호출:
   - Sonnet 1: flutter run -d RFCY40MNBLL (폰)
   - Sonnet 2: flutter run -d chrome --web-port=8080 (웹)
- [ ] 3. 각 Sonnet 결과 로그 저장
- [ ] 4. 검증 후 CP 명령 대기

## 보고서 규칙
- Sonnet: 텍스트 보고만 (파일 X)
- Opus: 로그 저장 + 최종 보고서 파일 작성

## 완료 조건
1. 폰/웹 빌드 성공
2. 로그 파일 저장 완료
3. CP가 "테스트 종료" 입력
4. 보고서 작성 완료
```

---

### 코드 수정

```markdown
# BIG_XXX: [작업명]

## 환경
- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/

## ⚠️ 필수: Opus는 직접 작업 금지!
가급적 코드/파일 작업은 Sonnet 호출해서 시킬 것.
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."

## 스몰스텝 (진행 시 체크박스 업데이트!)
- [ ] 1. Sonnet: 현재 코드 확인
- [ ] 2. Sonnet: 코드 수정
- [ ] 3. Sonnet: flutter analyze
- [ ] 4. 검증 후 보고서

## 보고서 규칙
- Sonnet: 텍스트 보고만 (파일 X)
- Opus: 로그 저장 + 최종 보고서 파일 작성

## 완료 조건
1. flutter analyze 에러 없음
2. CP가 "테스트 종료" 입력
3. 보고서 작성 완료
```

---

## 📊 보고서 규칙

| 역할 | 보고 방식 |
|------|----------|
| Sonnet | 텍스트로 결과 보고 (파일 X) |
| Opus | 로그 저장 + 최종 보고서 파일 작성 |

→ **중복 방지!**

---

## 🔧 코드 패턴

### 웹 플랫폼 체크

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (!kIsWeb) {
  // 모바일/데스크톱 전용
}
```

### Cognito 사용자 정보

```dart
final user = await Amplify.Auth.getCurrentUser();
final userId = user.userId;  // Cognito sub (중요!)
```

---

## 🐛 자주 발생하는 에러

### MissingPluginException (웹)

```dart
if (!kIsWeb) {
  plugins.add(AmplifyDataStore(...));
}
```

### git index.lock

```bash
rm .git/index.lock  # Mac
del .git\index.lock  # Windows
```

---

## 📱 scrcpy (폰 화면 미러링)

### 실행 전 중복 체크 필수!

```bash
# Mac - 이미 실행 중인지 확인 후 실행
pgrep -x scrcpy || scrcpy
```

```powershell
# Windows - 이미 실행 중인지 확인 후 실행
if (-not (Get-Process -Name scrcpy -ErrorAction SilentlyContinue)) { scrcpy }
```

**⚠️ scrcpy 중복 실행하면 화면 여러 개 떠서 문제 생김!**

---

## 💡 생산성 팁

### 1. 역할 분담 기억

```
Opus = 머리 (분석, 검증, 보고서 파일)
Sonnet = 손발 (실행, 텍스트 보고)
```

### 2. 듀얼은 동시 호출

```
❌ Sonnet 1 → 대기 → Sonnet 2
✅ Sonnet 1 + Sonnet 2 동시
```

### 3. 보고서 중복 주의

```
❌ Sonnet도 파일, Opus도 파일 → 2개!
✅ Sonnet은 텍스트만, Opus만 파일 → 1개!
```
