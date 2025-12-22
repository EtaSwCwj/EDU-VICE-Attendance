# 2실린더 자동화 시스템 가이드

> **버전**: v7.1 (2025-12-23)
> **마지막 업데이트**: Opus-Sonnet 체인, Sonnet 동시 호출 (듀얼 디버깅)

---

## 🔥 핵심 컨셉

**"Opus는 관리자, Sonnet은 실행자"**

```
CP: 복붙 1번
      ↓
Opus (Manager): 분석 → 스몰스텝 분해 → Sonnet 호출 → 검증
      ↓
Sonnet (Worker): 실제 작업 실행 → 텍스트 보고
      ↓
Opus: 최종 보고서 파일 작성
```

---

## 📐 시스템 구조 (v7.1)

### 역할 분담

| 역할 | 모델 | 담당 |
|------|------|------|
| Manager | Opus | 분석, 분해, 검증, **보고서 파일 작성** |
| Worker | Sonnet | 작업 실행, **텍스트 보고만** |

### 보고서 중복 방지

- Sonnet: 결과를 텍스트로만 보고 (파일 X)
- Opus: 최종 보고서만 파일로 작성

---

## 🚀 사용법

### 수동 모드 실행

```bash
npm run claude:opus
# 빅스텝 명령어 복붙 → Opus가 Sonnet 부려서 작업 → "테스트 종료"
```

### Sonnet 호출 (Opus가 사용)

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "스몰스텝 내용"
```

---

## 🔄 듀얼 디버깅 (Sonnet 동시 호출)

### 왜 동시 호출?

```
❌ 순차 호출:
Opus → Sonnet 1 (폰 빌드) → 완료 대기... → Sonnet 2 (웹 빌드)
                              ↑ 블로킹!

✅ 동시 호출:
Opus → Sonnet 1 (폰 빌드) ─┐
     → Sonnet 2 (웹 빌드) ─┴→ 병렬 실행!
```

각 `claude` 명령은 별도 프로세스라서 블로킹 안 됨!

### 플로우

```
1. Opus: Sonnet 호출 (디바이스 확인) → 완료 대기
2. Opus: Sonnet 2개 동시 호출
   - Sonnet 1: flutter run -d phone
   - Sonnet 2: flutter run -d chrome --web-port=8080
3. Opus: 두 Sonnet 결과 검증
4. Opus: CP 명령 대기 ("테스트 종료" 등)
5. Opus: 보고서 작성
```

---

## 📝 빅스텝 템플릿

### 듀얼 디버깅용

```markdown
## 📋 초기 명령어 (복붙용)

\`\`\`
당신은 Manager(Opus)입니다.

## 작업 목표
듀얼 디버깅: 폰 + Chrome 동시 실행

## 당신의 역할
1. Sonnet 호출해서 디바이스 확인
2. Sonnet 2개 **동시** 호출 (폰 빌드 + 웹 빌드)
3. 두 Sonnet 결과 검증
4. CP 명령 대기

## Sonnet 호출
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."

## 보고서 규칙
- Sonnet: 텍스트 보고만 (파일 X)
- Opus: 최종 보고서 파일 작성

시작하세요.
\`\`\`
```

---

## 📁 폴더 구조

```
ai_bridge/
├── learning/              # 학습 데이터
│   ├── GUIDE.md           # 시스템 가이드 (이 파일)
│   ├── PRINCIPLES.md      # 핵심 원칙
│   ├── HISTORY.md         # 히스토리
│   ├── PATTERNS.md        # 패턴
│   └── WORKFLOW.md        # 워크플로우 상세
│
├── bigstep/               # 작업 지시서
│   └── BIG_XXX_제목.md
│
└── report/                # 보고서 (Opus만 작성)
    └── big_XXX_report.md
```

---

## 💻 npm scripts

| 명령어 | 설명 |
|--------|------|
| `npm run claude:opus` | Opus CLI (Manager 역할) |

---

## 🎯 중간 명령어 (CP → Opus)

| 명령어 | 동작 |
|--------|------|
| 테스트 종료 | 보고서 작성 + 종료 |
| 로그 확인 | Sonnet 시켜서 로그 출력 |
| 이거 고쳐줘 | Sonnet 시켜서 수정 |

---

## ⚠️ 핵심 규칙

### Opus (Manager)
- 직접 작업 금지 → Sonnet 시킬 것
- Sonnet 결과 반드시 검증
- **보고서 파일은 Opus만 작성**
- CP 명령 없이 임의 종료 금지

### Sonnet (Worker)
- 작업 실행 + **텍스트 보고만**
- 보고서 파일 생성 금지
- --dangerously-skip-permissions로 권한 안 물음

---

## 📌 버전 히스토리

| 버전 | 특징 |
|------|------|
| v6 | Opus 통합 관리 |
| v7 | 수동 모드 추가 |
| **v7.1** | **Opus-Sonnet 체인, 동시 호출, 보고서 중복 방지** |
