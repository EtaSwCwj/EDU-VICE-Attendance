# SMALL_047_01_EXECUTE.md

> **빅스텝**: BIG_047_SIMPLE_WAIT.md

---

## 📋 작업 내용

# BIG_047: 맥 웹 서버 15초 대기 후 사파리

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

기존 웹 서버 `q`로 종료 후 실행:

```bash
osascript -e 'tell app "Terminal" to activate' -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

**단순화**: 15초 고정 대기 후 localhost:8080 열기

**성공 조건**: 15초 후 사파리에서 앱 화면 바로 나옴


---

**결과는 `/Users/cwj/gitproject/EDU-VICE-Attendance/ai_bridge/result/small_047_01_result.md`에 저장할 것.**
