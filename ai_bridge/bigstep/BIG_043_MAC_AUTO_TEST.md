# BIG_043: 맥 웹 서버 자동 실행 테스트

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

1. 기존 웹 서버 프로세스 종료 (8080 포트):
```bash
lsof -ti:8080 | xargs kill -9 2>/dev/null || true
```

2. 새 터미널에서 웹 서버 스크립트 실행:
```bash
osascript -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

순서대로 실행해.

**성공 조건**: 새 터미널에서 Flutter 빌드 시작 → 서버 준비되면 사파리에서 자동으로 localhost:8080 열림
