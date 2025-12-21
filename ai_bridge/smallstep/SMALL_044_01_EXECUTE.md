# SMALL_044_01_EXECUTE.md

> **빅스텝**: BIG_044_TERMINAL_TEST.md

---

## 📋 작업 내용

# BIG_044: 맥 터미널 열기 테스트

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

간단한 테스트 - 새 터미널 창 열고 메시지 출력:

```bash
osascript -e 'tell app "Terminal" to activate' -e 'tell app "Terminal" to do script "echo 맥후임_터미널_테스트_성공 && sleep 10"'
```

이 명령어 실행해.

**성공 조건**: 새 터미널 창이 앞으로 나오고 "맥후임_터미널_테스트_성공" 메시지 표시


---

**결과는 `/Users/cwj/gitproject/EDU-VICE-Attendance/ai_bridge/result/small_044_01_result.md`에 저장할 것.**
