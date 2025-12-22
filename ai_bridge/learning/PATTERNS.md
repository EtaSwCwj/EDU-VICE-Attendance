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

### 듀얼 디버깅

```markdown
## 📋 초기 명령어 (복붙용)

\`\`\`
당신은 Manager(Opus)입니다.

## 작업 목표
듀얼 디버깅: 폰 + Chrome 동시 실행

## 스몰스텝
1. Sonnet: 디바이스 확인
2. Sonnet 2개 동시: 폰 빌드 + 웹 빌드
3. 검증 후 CP 명령 대기

## Sonnet 호출
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."

## 보고서 규칙
- Sonnet: 텍스트 보고만
- Opus: 보고서 파일 작성

시작하세요.
\`\`\`
```

### 코드 수정

```markdown
## 📋 초기 명령어 (복붙용)

\`\`\`
당신은 Manager(Opus)입니다.

## 작업 목표
login_page.dart 버그 수정

## 스몰스텝
1. Sonnet: 현재 코드 확인
2. Sonnet: 버그 수정
3. Sonnet: flutter analyze
4. 검증 후 보고서

## 보고서 규칙
- Sonnet: 텍스트 보고만
- Opus: 보고서 파일 작성

시작하세요.
\`\`\`
```

---

## 📊 보고서 규칙

| 역할 | 보고 방식 |
|------|----------|
| Sonnet | 텍스트로 결과 보고 (파일 X) |
| Opus | 최종 보고서 파일 작성 |

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
