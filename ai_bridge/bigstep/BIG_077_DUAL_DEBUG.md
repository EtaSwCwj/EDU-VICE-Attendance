# BIG_077: 듀얼 디버깅 테스트

> 생성일: 2025-12-23
> 버전: v7.2
> 목표: 폰 + Chrome 동시 실행 테스트

---

## 작업 목표

듀얼 디버깅: 폰 + Chrome 동시 실행

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance
- Flutter 앱: flutter_application_1/
- 폰 디바이스: RFCY40MNBLL
- 웹 포트: 8080

## 스몰스텝

1. Sonnet 호출: flutter devices로 디바이스 확인 → 로그 저장
2. Sonnet 2개 **동시** 호출:
   - Sonnet 1: flutter run -d RFCY40MNBLL (폰)
   - Sonnet 2: flutter run -d chrome --web-port=8080 (웹)
3. 각 Sonnet 결과 로그 저장 (ai_bridge/logs/big_077_step_XX.log)
4. 두 Sonnet 결과 검증
5. CP 명령 대기

## Sonnet 호출 방법

```bash
claude --model claude-sonnet-4-20250514 --dangerously-skip-permissions -p "..."
```

## 로그 저장 규칙 (v7.2)

- 저장 위치: ai_bridge/logs/
- 파일명: big_077_step_01.log, big_077_step_02.log, ...
- Opus가 Sonnet 결과 받아서 저장

## 주의사항

- 폰/웹 Sonnet을 **동시에** 호출 (순차 X)
- 각 Sonnet은 별도 프로세스라서 블로킹 안 됨
- Sonnet: 텍스트 보고만 (파일 X)
- Opus: 로그 저장 + 최종 보고서 파일 작성

## 중요 규칙

- CP 추가 명령 우선 처리
- "테스트 종료" 시 보고서 작성 후 종료
- 임의 종료 금지

## 완료 조건

1. 폰 빌드 성공
2. 웹 빌드 성공
3. 로그 파일 저장 완료
4. CP가 "테스트 종료" 입력
5. 보고서 작성 완료 (ai_bridge/report/big_077_report.md)
