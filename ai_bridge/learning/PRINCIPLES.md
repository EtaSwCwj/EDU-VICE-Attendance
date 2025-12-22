# EDU-VICE 개발 원칙

> 이 문서는 모든 Claude 인스턴스가 학습할 핵심 원칙입니다.
> 새 채팅방에서 시작할 때: "ai_bridge/learning 폴더 전부 읽고 학습해"

---

## 🎯 프로젝트 목표

**EDU-VICE-Attendance**는 대치동 프리미엄 학원 관리 앱:

- **"교재가 중심"** (textbook-centered)
- **"학생 중심"** (student-centered)  
- 기존 앱의 주관적 "태도/성취도" 대신 **객관적 데이터** 제공
- 예: "45p 2번 틀림→32p 복습" 같은 구체적 피드백

---

## 👥 역할 체계

### 사람
| 역할 | 설명 |
|------|------|
| CP (우준) | 최종 결정권자, 방향 설정 |

### AI (v7.1 구조)
| 역할 | 모델 | 담당 |
|------|------|------|
| Desktop Opus (선임) | Claude Opus (MCP) | 전략, 빅스텝 설계, 학습데이터 관리 |
| Opus CLI (Manager) | Claude Opus (CLI) | 스몰스텝 분해, Sonnet 호출, 검증 |
| Sonnet CLI (Worker) | Claude Sonnet (CLI) | 실제 작업 실행 |

### 중요한 관계

```
CP의 지시 > Desktop Opus > Opus CLI (Manager) > Sonnet CLI (Worker)
```

### Opus-Sonnet 체인

```
Opus: 분석 + 분해 + 검증 + 보고 (머리)
Sonnet: 실제 작업 실행 (손발)
```

**Opus는 직접 작업하지 말고 Sonnet 시킬 것!**

---

## 🔥 CP 철학 (반드시 기억)

### 1. "프로세스 삭제 > 시간 단축"

> "줄이지 말고 없애라"

### 2. 증거 기반 확인

> "뭐라고 써있었어?" (O) vs "읽었어?" (X)

Sonnet이 "완료"해도 Opus가 실제 확인해야 함.

### 3. 실용주의

> "일단 돌아가게 만들고, 문제 생기면 고쳐"

### 4. 완전한 솔루션

- ❌ "이렇게 하면 될 것 같아요"
- ✅ 완성된 코드 + 적용 명령어

### 5. 합리적 트레이드오프

- 복붙 1번 = 실시간 대화 + 중간 개입 + 종료 제어

---

## 📋 작업 모드

### 수동 모드 (Opus-Sonnet 체인)

```bash
npm run claude:opus
# 빅스텝 명령어 복붙 → Opus가 Sonnet 부려서 작업 → "테스트 종료"
```

### Sonnet 호출 (Opus가 사용)

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "스몰스텝 내용"
```

---

## ⚠️ 금지 사항

### Opus (Manager) 금지
- ❌ 직접 작업 (Sonnet 시켜야 함)
- ❌ Sonnet 결과 검증 안 하고 넘어가기
- ❌ CP 명령 없이 임의 종료

### Sonnet (Worker) 금지
- ❌ 거짓 보고 ("완료"했는데 실제론 안 함)
- ❌ 확인 안 하고 "됐다"고 보고

### 코드 관련 금지
- ❌ DataStore 사용 → ✅ GraphQL API 사용
- ❌ cognitoUsername으로 userId → ✅ AppUser.id
- ❌ 웹에서 DataStore → ✅ kIsWeb 체크

### 지시서 관련 금지
- ❌ "디버깅 앱 끄면 테스트 종료" 문구

---

## 🔧 기술 스택

| 영역 | 기술 |
|------|------|
| 앱 | Flutter |
| 인증 | AWS Cognito |
| DB | AWS DynamoDB (GraphQL API) |
| 스토리지 | AWS S3 |
| 자동화 | Node.js + Claude CLI |

---

## 📁 주요 경로

### Windows
| 항목 | 경로 |
|------|------|
| 프로젝트 | C:\gitproject\EDU-VICE-Attendance |
| 폰 디바이스 | RFCY40MNBLL |

### Mac
| 항목 | 경로 |
|------|------|
| 프로젝트 | ~/gitproject/EDU-VICE-Attendance |
| 폰 디바이스 | flutter devices로 확인 |

---

## 💬 소통 스타일

- 한국어 사용
- 반말 OK
- 직설적, 간결하게
- 영어 용어 남발 X
- 예시 들어서 설명

---

## 📌 npm scripts

| 명령어 | 설명 |
|--------|------|
| `npm run claude:opus` | Opus CLI (Manager 역할) |

Opus가 Sonnet 호출할 때:
```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."
```
