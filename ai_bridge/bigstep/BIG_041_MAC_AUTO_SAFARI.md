# BIG_041: 맥 웹 서버 + 사파리 자동 열기

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

기존 웹 서버 터미널 닫고, 새로 스크립트 실행:

```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

**성공 조건**: 새 터미널에서 Flutter 빌드 시작 + 3초 후 사파리 자동으로 열림
