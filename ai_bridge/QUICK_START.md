# 🚀 QUICK_START (새 채팅용)

> **새 채팅 시작할 때 이 파일 내용 복붙하면 바로 시작 가능**

---

## ⚠️ 먼저 읽어!

```
MCP filesystem 연결되어 있음.
"난 로컬 접속 못하는데?" 이런 소리 하지 말고 그냥 읽어.

경로: C:\gitproject\EDU-VICE-Attendance\ai_bridge\

된다.
```

---

## 프로젝트 한 줄 요약

EDU-VICE-Attendance = Flutter 학원관리앱, 핵심은 **"45p 2번 틀림 → 32p 복습"** 단위 학습관리

---

## 기술 스택

- Flutter (Windows, Android, iOS)
- AWS Amplify (Cognito 인증, DynamoDB, GraphQL)
- Clean Architecture

---

## 현재 상태

- **Phase 1**: 60% 완료 (기본 기능)
- **Phase 2**: 진행 중 (초대 시스템, 책 DB)
- **마지막 작업**: BIG_102 (책 Multi-Volume 구조)

---

## 프로젝트 경로

```
C:\gitproject\EDU-VICE-Attendance\
├── flutter_application_1\    # Flutter 앱
├── ai_bridge\                # AI 협업 폴더
│   ├── learning\            # 학습 문서 (필독!)
│   ├── templates\           # 지시서 템플릿
│   └── bigstep\             # 작업 지시서
```

---

## 작업 시작 전 필수

```
1. ai_bridge/learning/00_LEARNING_GUIDE.md 읽기
2. 체크리스트 따라 학습
3. 특히 08_CLAUDE_LIMITATIONS.md 자각하기
```

---

## CP 작업 스타일 (중요!)

```
✅ 방향은 CP가, 구체화는 Claude가
✅ 어려운 문제 → 옵션 나열 전에 CP에게 방향 먼저 물어볼 것
✅ "이거 안 해도 되는 거 아냐?" 먼저 생각
✅ 유저 입력 최소화 설계

❌ 기술로 복잡하게 해결하려 하지 말 것
❌ 옵션만 나열하고 "CP 생각은?" 금지
```

---

## 테스트 계정

- Email: maknae12@gmail.com
- AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02

---

## 자주 쓰는 명령어

```bash
# Flutter
flutter run -d RFCY40MNBLL    # 폰 빌드
flutter analyze               # 코드 분석
flutter run -d chrome --web-port=8080  # 웹 빌드

# Sonnet 호출 (Opus에서)
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "작업내용"
```

---

## 이어서 작업하려면

```
"마지막 작업 뭐였어?" 물어보거나
ai_bridge/bigstep/ 폴더에서 최신 BIG_XXX 확인
```

---

**이제 00_LEARNING_GUIDE.md 읽고 시작!**
