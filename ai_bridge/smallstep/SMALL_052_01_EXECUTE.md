# SMALL_052_01_EXECUTE.md

> **빅스텝**: BIG_052_DUAL_DEBUG.md

---

## 📋 작업 내용

# BIG_052: 맥 듀얼 디버깅 (폰 + Chrome)

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

1. 폰에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to activate' -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_phone_mac.sh"'
```

2. Chrome 웹에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

순서대로 실행해.

**성공 조건**: 터미널 2개 + 폰 앱 + Chrome localhost:8080 둘 다 실행


---

**결과는 `/Users/cwj/gitproject/EDU-VICE-Attendance/ai_bridge/result/small_052_01_result.md`에 저장할 것.**
