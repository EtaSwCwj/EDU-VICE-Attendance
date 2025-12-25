# BIG_038: 맥 웹 브라우저 설정 및 실행

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

1. Flutter 웹 지원 활성화:
```bash
cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter config --enable-web
```

2. 웹 디바이스 확인:
```bash
cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter devices
```

3. 웹 서버 모드로 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d web-server --web-port=8080"'
```

위 명령어들 순서대로 실행해.

**web-server 모드**: 브라우저 자동 실행 없이 서버만 띄움 → 사파리에서 localhost:8080 접속
