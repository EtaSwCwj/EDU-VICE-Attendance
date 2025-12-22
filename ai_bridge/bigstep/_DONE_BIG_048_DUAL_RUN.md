# BIG_048: 맥 듀얼 실행 (폰 + 웹)

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

기존 웹 서버 `q`로 종료 후:

1. 스크립트 권한 부여:
```bash
chmod +x /Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_phone_mac.sh
```

2. 폰에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to activate' -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_phone_mac.sh"'
```

3. 웹 서버 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

순서대로 실행해.

**성공 조건**: 터미널 2개 열리고, 폰 앱 + 25초 후 사파리에서 웹 앱 둘 다 나옴
