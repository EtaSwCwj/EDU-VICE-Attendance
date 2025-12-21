# BIG_039: 맥 웹 서버 스크립트 실행

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

1. 스크립트 실행 권한 부여:
```bash
chmod +x /Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh
```

2. 새 터미널에서 스크립트 실행:
```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

위 명령어 순서대로 실행해.

**성공 조건**: 새 터미널에서 Flutter 웹 서버 빌드 시작됨
