# 워크플로우 상세 가이드

> **버전**: v7.3 (2025-12-23)
> **변경**: 듀얼 디버깅 검증 규칙 강화

---

## Opus-Sonnet 체인 구조

### 역할 분담

| 역할 | 모델 | 담당 | 비용 |
|------|------|------|------|
| Manager | Opus | 분석, 분해, 검증, 보고서 작성 | 높음 |
| Worker | Sonnet | 실제 작업 실행, 텍스트 보고 | 낮음 |

### 보고서 규칙

| 역할 | 보고 방식 |
|------|----------|
| Sonnet | 텍스트로만 결과 보고 (파일 X) |
| Opus | 최종 보고서 파일 작성 (report/big_XXX_report.md) |

→ **보고서 중복 방지!**

---

## 🆕 Sonnet 로그 저장 (v7.2)

### 왜 필요?

- Opus가 Sonnet 결과를 텍스트로만 받으면 **컨텍스트 손실**
- Sonnet이 뭘 봤는지 Opus가 직접 확인 불가
- 나중에 디버깅할 때도 로그 필요

### 로그 저장 규칙

| 항목 | 값 |
|------|-----|
| 저장 위치 | `ai_bridge/logs/` |
| 파일명 | `big_XXX_step_YY.log` |
| 작성자 | Opus (Sonnet 결과 받아서 저장) |

### 로그 형식

```markdown
# BIG_XXX Step YY 로그

- 시간: YYYY-MM-DD HH:MM:SS
- 스몰스텝: (설명)
- Sonnet 명령: (실행한 명령)

## Sonnet 출력
(Sonnet이 보고한 전체 텍스트)

## Opus 검증
- 결과: ✅ / ❌
- 비고: (있으면)
```

### 플로우 변경

```
기존:
Sonnet 실행 → 텍스트 보고 → Opus 검증 → 다음 스텝

v7.2:
Sonnet 실행 → 텍스트 보고 → Opus가 로그 파일 저장 → Opus 검증 → 다음 스텝
```

---

## 수동 모드 상세 플로우

```
1. CP: npm run claude:opus 실행
2. CP: 빅스텝 명령어 복붙
         ↓
3. Opus: 빅스텝 분석
4. Opus: 스몰스텝으로 분해
         ↓
5. Opus: Sonnet 호출 (각 스몰스텝마다)
   claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."
         ↓
6. Sonnet: 스몰스텝 실행 → 텍스트로 결과 보고
         ↓
7. Opus: 로그 파일 저장 (ai_bridge/logs/big_XXX_step_YY.log)
         ↓
8. Opus: 검증 (실제 파일/로그 확인)
   - OK → 다음 스몰스텝
   - FAIL → Sonnet에게 재지시
         ↓
9. 반복... 
         ↓
10. Opus: 모든 스몰스텝 완료 → CP 명령 대기
         ↓
11. CP: "테스트 종료"
         ↓
12. Opus: 보고서 파일 작성 → 종료
```

---

## 듀얼 디버깅 (Sonnet 동시 호출)

### 플로우

```
Opus: 스몰스텝 1 - Sonnet 호출 (디바이스 확인)
      ↓ (완료 대기)
      
Opus: 스몰스텝 2, 3 - Sonnet 2개 동시 호출
      ├── Sonnet 1: flutter run -d phone
      └── Sonnet 2: flutter run -d chrome --web-port=8080
      
      (두 Sonnet 병렬 실행, 블로킹 안 됨)
      ↓
      
Opus: 각 Sonnet 결과 로그 저장
Opus: 두 Sonnet 결과 확인
Opus: CP 명령 대기
```

### 왜 동시 호출?

- 각 `claude` 명령은 별도 프로세스
- Sonnet 1이 `flutter run`으로 블로킹되어도
- Sonnet 2는 별도로 실행 가능

### 주의사항

- 순차 호출하면 첫 번째가 끝날 때까지 대기 → 비효율
- 동시 호출해야 진짜 "듀얼" 디버깅

---

## Sonnet 호출 방법

### 기본 형식

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "스몰스텝 내용"
```

### 예시

```bash
# 디바이스 확인
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "cd flutter_application_1 && flutter devices 실행해서 연결된 디바이스 목록 알려줘"

# 폰 빌드 (동시 호출 1)
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "cd flutter_application_1 && flutter run -d RFCY40MNBLL 실행해. 빌드 완료되면 알려줘"

# 웹 빌드 (동시 호출 2)
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "cd flutter_application_1 && flutter run -d chrome --web-port=8080 실행해. 빌드 완료되면 알려줘"
```

---

## 검증 규칙

### Opus가 해야 할 검증

| Sonnet 보고 | Opus 확인 방법 |
|-------------|----------------|
| "파일 생성 완료" | ls, cat으로 실제 확인 |
| "빌드 성공" | 로그에서 에러 확인 |
| "수정 완료" | diff나 cat으로 변경 확인 |

### 거짓 보고 대응

```
Sonnet: "빌드 완료했습니다!"
Opus: (로그 확인) → 에러 발견
Opus: "에러 있어. 다시 확인해."
      → Sonnet 재호출
```

---

## 🆕 듀얼 디버깅 검증 규칙 (v7.3)

### ⚠️ 핵심: 에러 메시지 ≠ 실패

```
❌ 잘못된 판단:
Sonnet 보고에 에러 메시지 있음 → 바로 "실패" 판정

✅ 올바른 판단:
Sonnet 보고에 에러 메시지 있음 → 실제 프로세스 확인 → 판정
```

### 듀얼 디버깅 성공 판단 기준

| 확인 항목 | 확인 방법 | 성공 조건 |
|-----------|----------|-----------|
| flutter 프로세스 | `tasklist \| findstr flutter` (Win) / `ps aux \| grep flutter` (Mac) | 프로세스 실행 중 |
| 앱 실행 상태 | 폰 화면 / 브라우저 직접 확인 | 앱 화면 표시됨 |
| 포트 사용 | `netstat -an \| findstr 8080` | 포트 LISTENING |

### 검증 플로우 (듀얼 디버깅)

```
1. Sonnet 결과 받음
2. 에러 메시지 있어도 바로 실패 판정 금지!
3. 실제 확인:
   - flutter 프로세스 실행 중?
   - 앱 화면 떠 있음?
   - 포트 열려 있음?
4. 위 조건 중 하나라도 충족 → 성공
5. 모두 미충족 → 실패
```

### 왜 이렇게 해야 하나?

BIG_077 테스트에서 발생한 문제:
- Sonnet이 "streaming mode" 에러 보고
- Opus가 에러 메시지만 보고 "실패" 판정
- **실제로는 Chrome 앱이 정상 실행 중이었음!**

→ 에러 메시지만 보고 판단하면 **오판** 발생

### 교훈

```
"에러 메시지가 있어도 앱이 돌아가면 성공이다"
```

---

## 완료 시 알림 (Opus가 실행)

보고서 작성 후 소리 알림:

```bash
# Mac
afplay /System/Library/Sounds/Glass.aiff

# Windows  
powershell -c "[console]::beep(800,300); [console]::beep(1000,300); [console]::beep(1200,300)"
```

---

## 보고서 형식

```markdown
# BIG_XXX 보고서

## 테스트 개요
- 날짜: YYYY-MM-DD HH:MM
- 플랫폼: Windows / Mac

## 스몰스텝 실행 결과
| 스몰스텝 | Sonnet | 결과 | 재시도 | 로그 |
|----------|--------|------|--------|------|
| 디바이스 확인 | 1 | ✅ | 0 | big_XXX_step_01.log |
| 폰 빌드 | 1 | ✅ | 0 | big_XXX_step_02.log |
| 웹 빌드 | 2 | ✅ | 0 | big_XXX_step_03.log |

## 발견된 이슈
1. ...

## 로그 요약
...
```
