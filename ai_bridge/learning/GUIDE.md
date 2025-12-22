# 2실린더 자동화 시스템 가이드

> **버전**: v7.3 (2025-12-23)
> **마지막 업데이트**: 듀얼 디버깅 검증 규칙 강화

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
Opus: 로그 저장 → 최종 보고서 파일 작성
```

---

## 📐 시스템 구조 (v7.2)

### 역할 분담

| 역할 | 모델 | 담당 |
|------|------|------|
| Manager | Opus | 분석, 분해, 검증, **로그 저장**, **보고서 파일 작성** |
| Worker | Sonnet | 작업 실행, **텍스트 보고만** |

### 보고서 중복 방지

- Sonnet: 결과를 텍스트로만 보고 (파일 X)
- Opus: 로그 저장 + 최종 보고서만 파일로 작성

---

## 🆕 Sonnet 로그 저장 (v7.2)

### 왜 필요?
- Opus가 Sonnet 결과를 텍스트로만 받으면 **컨텍스트 손실**
- 나중에 디버깅할 때 로그 필요

### 규칙
| 항목 | 값 |
|------|-----|
| 저장 위치 | `ai_bridge/logs/` |
| 파일명 | `big_XXX_step_YY.log` |
| 작성자 | Opus (Sonnet 결과 받아서 저장) |

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
3. Opus: 각 Sonnet 결과 로그 저장
4. Opus: 두 Sonnet 결과 검증
5. Opus: CP 명령 대기 ("테스트 종료" 등)
6. Opus: 보고서 작성
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
├── logs/                  # Sonnet 실행 로그 (v7.2)
│   └── big_XXX_step_YY.log
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
- **Sonnet 결과 로그 파일로 저장**
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
| v7.1 | Opus-Sonnet 체인, 동시 호출, 보고서 중복 방지 |
| v7.2 | Sonnet 로그 파일 저장 추가 |
| **v7.3** | **듀얼 디버깅 검증 규칙 강화 (에러 메시지 ≠ 실패)** |
