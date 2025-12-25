# BIG_037: 맥 Flutter 듀얼 실행 (macOS + Android)

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

두 개 디바이스에서 동시 실행:

1. 먼저 Android 폰에서 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d RFCY40MNBLL"'
```

2. macOS 데스크톱 앱으로 실행 (새 터미널):
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d macos"'
```

위 두 명령어를 순서대로 실행해.

**성공 조건**: 터미널 2개 열리고 각각 빌드 시작됨
