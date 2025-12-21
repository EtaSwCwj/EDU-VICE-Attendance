# SMALL_049_01_EXECUTE.md

> **빅스텝**: BIG_049_CHROME_DUAL.md

---

## 📋 작업 내용

# BIG_049: 맥 듀얼 실행 (폰 + Chrome)

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

1. 스크립트 권한 부여:
```bash
chmod +x /Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh
chmod +x /Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_phone_mac.sh
```

2. 폰에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to activate' -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_phone_mac.sh"'
```

3. Chrome 웹에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

순서대로 실행해.

**성공 조건**: 터미널 2개 + 폰 앱 + Chrome에서 localhost:8080 자동으로 열림


---

**결과는 `/Users/cwj/gitproject/EDU-VICE-Attendance/ai_bridge/result/small_049_01_result.md`에 저장할 것.**
