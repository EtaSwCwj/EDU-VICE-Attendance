# BIG_032: 맥 Flutter 듀얼 실행 테스트

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

Flutter 앱을 두 개 디바이스에서 동시 실행:

1. 먼저 연결된 디바이스 확인:
```bash
cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1
flutter devices
```

2. 폰(Android)에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d android"'
```

3. 맥 Chrome에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d chrome --web-port=8080"'
```

**성공 조건**: 터미널 2개 열리고 각각 빌드 시작됨
