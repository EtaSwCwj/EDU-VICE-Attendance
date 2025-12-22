# BIG_075: 듀얼 디버깅 테스트

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-23
> **작업 유형**: 수동 (Claude Code 직접 실행)

---

## 📋 초기 명령어 (복붙용)

```
ai_bridge/bigstep/BIG_075_DUAL_DEBUG_TEST.md 지시서대로 작업하세요.
```

---

## 작업 목표

듀얼 디버깅: 폰 + Chrome 동시 실행 및 테스트

---

## 당신의 역할 (Opus = Manager)

1. 이 빅스텝을 스몰스텝으로 분해
2. 각 스몰스텝마다 Sonnet 호출해서 실행
3. Sonnet 결과를 검증 (실제 파일/로그 확인)
4. 검증 실패 시 Sonnet에게 재지시
5. 모든 스몰스텝 완료 후 CP 명령 대기
6. "테스트 종료" 명령 시 보고서 작성

---

## Sonnet 호출 방법

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "스몰스텝 내용"
```

---

## 스몰스텝

1. Sonnet 호출: flutter devices로 연결된 디바이스 확인
2. Sonnet 2개 **동시** 호출:
   - Sonnet A: 폰 디바이스로 flutter run 실행 (flutter_application_1 폴더에서)
   - Sonnet B: chrome으로 flutter run --web-port=8080 실행 (flutter_application_1 폴더에서)
3. 두 Sonnet 결과 확인 (빌드 성공 여부)
4. CP에게 완료 알리고 명령 대기

---

## 검증 규칙

- Sonnet이 "완료했다"고 하면 실제 확인 (로그에 에러 없는지)
- 거짓 보고 발견 시 재지시
- 확인 안 하고 넘어가지 말 것

---

## 보고서 규칙

- Sonnet: 결과를 텍스트로만 보고 (파일 생성 X)
- Opus: 최종 보고서 파일 작성 (ai_bridge/report/big_075_report.md)

---

## 중요 규칙

- **CP의 추가 명령이 들어오면 현재 작업보다 우선 처리**
- "테스트 종료" 명령 시: 로그 요약 + 보고서 작성
- 임의로 종료하지 말고 CP 명령 대기

---

## 완료 시 알림

보고서 작성 완료 후 소리 알림 실행:

```bash
# Mac
afplay /System/Library/Sounds/Glass.aiff

# Windows
powershell -c "[console]::beep(800,300); [console]::beep(1000,300); [console]::beep(1200,300)"
```
