# 2실린더 자동화 시스템 가이드

> **버전**: v4.0 (2025-12-21)
> **마지막 업데이트**: Worker 호출 방식으로 전환, 웹 서버 실행 자동화

---

## 🔥 핵심 컨셉

**"커피 마시고 돌아오면 일 끝나있음"**

- CP가 빅스텝 던지면 → 자동 실행 → 자동 검토 → 자동 재지시 → 완료
- Manager만 켜두면 Worker 자동 호출
- 터미널 2개 필요 없음

---

## 📐 시스템 구조 (v4)

```
┌─────────────────────────────────────────────────────────┐
│  빅스텝 (전략/방향) - 수동                               │
│  CP + Desktop Opus                                      │
│  → bigstep/BIG_XXX_xxx.md 생성                         │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Manager (계속 실행 중)                                  │
│  bigstep/ 감지 → 스몰스텝 생성 → Worker 호출             │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Worker (일회성 실행)                                    │
│  스몰스텝 실행 → result 저장 → 종료                      │
└─────────────────────┬───────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────────────┐
│  Manager (result 감지)                                   │
│  교차검증 → SUCCESS: 보고서 / FAIL: 재지시+Worker 재호출  │
└─────────────────────────────────────────────────────────┘
```

### v3 → v4 변경점

| v3 (이전) | v4 (현재) |
|-----------|-----------|
| Worker watcher 계속 켜둠 | Worker 필요할 때만 호출 |
| 터미널 2개 필요 | Manager 터미널 1개만 |
| 서버 실행 불가 | 서버 실행 후 Worker 종료 가능 |

---

## 🔍 교차검증 시스템

Manager가 Worker 결과를 **실제 코드 열어서** 검증함.

### 검증 흐름

```
Worker 보고: "파일 수정 완료!"
        ↓
Manager: 실제 파일 열어봄
        ↓
일치? → SUCCESS → 보고서 생성
불일치? → FAIL → 재지시 생성 → Worker 재호출
```

### 실제 사례 (BIG_019)

```
1차 보고: "invitation.dart 구현 완료!"
Manager: (파일 확인) "이 파일 없는데?" → FAIL
재지시: "실제 파일 확인해서 다시 보고해"
2차 보고: "확인 결과 6개 파일만 존재"
Manager: SUCCESS → 정확한 분석 보고서 생성
```

**거짓 보고 자동 탐지!**

---

## 📊 작업 유형별 판단 기준

Manager가 빅스텝 키워드로 작업 유형 자동 판단:

| 유형 | 키워드 | 판단 기준 |
|------|--------|------------|
| code | (기본) | flutter analyze 에러 0개, 코드 품질 |
| analysis | 분석, 파악, 검토, 상태 확인 | 분석 충실성, 거짓 보고 여부 |
| commit | commit, push, git add | 커밋/푸시 성공 여부 |
| cleanup | 삭제, 정리, cleanup, delete | 파일 삭제 여부 |

### 예시

```
빅스텝: "Phase 2 현재 상태 분석해"
→ Manager: "분석" 키워드 감지
→ 분석 기준 적용 (flutter analyze 안 돌림)
→ 분석 충실성으로 판단
```

---

## 📁 폴더 구조

```
ai_bridge/
├── learning/              # 학습 데이터 (AI가 읽어야 함)
│   ├── GUIDE.md           # 이 파일 - 시스템 사용법
│   ├── PRINCIPLES.md      # 핵심 원칙, 금지사항
│   ├── HISTORY.md         # 과거 대화/결정 요약
│   └── PATTERNS.md        # 자주 쓰는 패턴
│
├── bigstep/               # CP/Opus → Manager
│   └── BIG_XXX_제목.md
│
├── smallstep/             # Manager → Worker
│   └── SMALL_XXX_NN_EXECUTE.md
│
├── result/                # Worker → Manager
│   └── small_XXX_NN_result.md
│
└── report/                # Manager → CP/Opus
    └── big_XXX_report.md
```

---

## 🚀 사용법

### 1. Manager 실행 (이것만 하면 됨!)

```bash
cd C:\gitproject\EDU-VICE-Attendance
npm run watch:manager
```

### 2. 빅스텝 생성

Desktop Opus(선임)가 `ai_bridge/bigstep/BIG_XXX_제목.md` 생성

→ Manager 감지 → 스몰스텝 생성 → Worker 호출 → 실행 → 검토 → 보고

### 3. 결과 확인

- 성공: `ai_bridge/report/big_XXX_report.md`
- 삐뽀삐 소리나면 완료

---

## 📝 빅스텝 작성법

```markdown
# BIG_XXX: 제목

> **작성자**: Desktop Opus
> **작성일**: YYYY-MM-DD

---

## 📋 작업

(구체적인 작업 내용)

## 📋 주의사항 (선택)

(특별히 주의할 점)
```

---

## 🔧 태스크 규모별 접근법

| 규모 | 방법 |
|------|------|
| 간단 | 빅스텝 1개 → 바로 완료 |
| 복잡 | Desktop Opus가 빅스텝 여러 개로 분리 |

### 예시 (복잡한 작업)

```
요청: "로그인 기능 구현해"
    ↓
Opus가 분리:
  BIG_001: auth_service.dart 만들어
  BIG_002: login_page.dart 만들어
  BIG_003: state 연결해
  BIG_004: 테스트해
```

**이유**: 설계는 사람(CP) 또는 Desktop Opus가 하는 게 현실적.

---

## 🌐 웹 서버 실행

```bash
# 배치 파일로 실행 (Worker가 호출 가능)
call scripts\start_web.bat   # Windows
./scripts/start_web.sh       # Mac
```

새 창에서 서버 실행 → Worker 종료 → Manager 계속 감시

---

## 💻 Mac/Windows 호환

이미 양쪽 다 지원함:

```javascript
// 소리
if (os.platform() === 'win32') {
  // Windows beep
} else if (os.platform() === 'darwin') {
  // Mac afplay
}

// CLI
const cmd = os.platform() === 'win32'
  ? `type "${file}" | claude -p ...`
  : `cat "${file}" | claude -p ...`;
```

---

## 🔔 알림 소리

| 소리 | 의미 |
|------|------|
| 삐뽀삐 (상승음) | 성공 |
| 삐삐 (하강음) | 실패/재지시 |

**Worker는 소리 안 냄** - Manager만 최종 알림

---

## ⚠️ 한계

| 가능 | 불가능 |
|------|--------|
| 파일 생성/수정 | UI 클릭 테스트 |
| git 커밋/푸시 | 실제 로그인 |
| flutter analyze | 멀티 계정 테스트 |
| 서버 실행 (새 창) | 사진/카메라 기능 |

---

## 📌 파일 명명 규칙

| 유형 | 형식 | 예시 |
|------|------|------|
| 빅스텝 | BIG_XXX_제목.md | BIG_029_WEB_DATASTORE.md |
| 스몰스텝 | SMALL_XXX_NN_EXECUTE.md | SMALL_029_01_EXECUTE.md |
| 재지시 | SMALL_XXX_NN_RETRY.md | SMALL_019_02_RETRY.md |
| 결과 | small_XXX_NN_result.md | small_029_01_result.md |
| 보고서 | big_XXX_report.md | big_029_report.md |
