# BIG_036: 맥 Flutter 웹 실행

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

맥에서 Flutter 웹 서버 실행 (새 터미널 창):

```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d chrome --web-port=8080"'
```

위 명령어를 bash로 실행해. `osascript`가 새 터미널 창을 열고 그 안에서 flutter run 실행함.

**성공 조건**: 새 터미널 창이 열리고 Flutter 빌드 시작됨
