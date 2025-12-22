# BIG_035: 맥 Flutter 듀얼 실행

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

Flutter 앱을 두 개 디바이스에서 동시 실행:

1. 먼저 연결된 디바이스 확인:
```bash
cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter devices
```

2. 맥 Chrome에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d chrome --web-port=8080"'
```

위 명령어 순서대로 실행해.
