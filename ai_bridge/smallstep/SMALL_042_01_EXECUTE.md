# SMALL_042_01_EXECUTE.md

> **빅스텝**: BIG_042_MAC_WAIT_READY.md

---

## 📋 작업 내용

# BIG_042: 맥 웹 서버 + 사파리 자동 (빌드 완료 후)

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

기존 웹 서버 터미널 닫고 (`Ctrl+C`), 새로 실행:

```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

**개선**: 서버가 실제로 준비될 때까지 대기 후 사파리 열기 (curl로 체크)


---

**결과는 `/Users/cwj/gitproject/EDU-VICE-Attendance/ai_bridge/result/small_042_01_result.md`에 저장할 것.**
