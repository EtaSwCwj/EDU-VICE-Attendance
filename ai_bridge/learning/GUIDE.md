# 2실린더 자동화 시스템 가이드

## 구조

```
┌─────────────────────────────────────────────────────────┐
│  빅스텝 (전략/방향) - 수동                               │
│  CP + Desktop Opus                                      │
│  → bigstep/BIG_001_xxx.md 생성                         │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  watch:manager (중간관리자 - Opus)                       │
│  bigstep/ 감시 → 스몰스텝 분해 → smallstep/ 생성         │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  watch:worker (후임 - Sonnet)                           │
│  smallstep/ 감시 → 실행 → result/ 저장                  │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  watch:manager (중간관리자)                              │
│  result/ 감시 → 검토 → 재지시 or report/ 최종 보고       │
└─────────────────────────────────────────────────────────┘
```

---

## 태스크 규모별 접근법

| 규모 | 방법 |
|------|------|
| 간단한 거 | 빅스텝 1개 → 스몰스텝 1개 → 완료 |
| 복잡한 거 | Desktop Opus가 빅스텝 여러 개로 나눠서 줄 |

**예시 (복잡한 작업)**:
```
빅스텝: "로그인 기능 구현해"
    ↓
Opus가 분리:
  BIG_001: auth_service.dart 만들어
  BIG_002: login_page.dart 만들어
  BIG_003: state 연결해
  BIG_004: 테스트해
```

**이유**: Manager가 진짜 분해하려면 프로젝트 구조/아키텍처 이해 필요 → 오버헤드. 
설계는 사람(CP) 또는 Desktop Opus가 하는 게 현실적.

---

## 폴더 구조

```
ai_bridge/
├── learning/          # 학습 데이터
│   ├── PRINCIPLES.md  # 핵심 원칙
│   ├── HISTORY.md     # 과거 대화 요약
│   └── PATTERNS.md    # 자주 쓰는 패턴
│
├── bigstep/           # CP/Opus → 중간관리자
│   └── BIG_001_xxx.md
│
├── smallstep/         # 중간관리자 → 후임
│   └── SMALL_001_01_xxx.md
│
├── result/            # 후임 → 중간관리자
│   └── small_001_01_result.md
│
└── report/            # 중간관리자 → CP/Opus
    └── big_001_report.md
```

---

## 사용법

### 1. 설치

```bash
cd C:\gitproject\EDU-VICE-Attendance
npm install
```

### 2. 실행 (터미널 2개)

**터미널 1: 중간관리자**
```bash
npm run watch:manager
```

**터미널 2: 후임**
```bash
npm run watch:worker
```

**또는 한 번에:**
```bash
npm run watch:all
```

### 3. 빅스텝 생성

Desktop Opus(나)가 `ai_bridge/bigstep/BIG_001_xxx.md` 생성

→ 중간관리자 감지 → 스몰스텝 분해 → 후임 실행 → 검토 → 보고

---

## 파일 명명 규칙

| 유형 | 형식 | 예시 |
|------|------|------|
| 빅스텝 | BIG_XXX_제목.md | BIG_001_LOGIN_FLOW.md |
| 스몰스텝 | SMALL_XXX_NN_제목.md | SMALL_001_01_SIGNUP_PAGE.md |
| 결과 | small_XXX_NN_result.md | small_001_01_result.md |
| 보고 | big_XXX_report.md | big_001_report.md |

---

## 학습 데이터 업데이트

채팅방 바뀔 때 Desktop Opus가 `ai_bridge/learning/` 폴더 업데이트:
- PRINCIPLES.md: 핵심 원칙
- HISTORY.md: 과거 대화 요약
- PATTERNS.md: 자주 쓰는 패턴

중간관리자는 매번 학습 데이터를 읽고 판단함.
