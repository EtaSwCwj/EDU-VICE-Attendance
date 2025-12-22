# SMALL_038_01_EXECUTE.md

> **빅스텝**: BIG_038_MAC_WEB_SERVER.md
> **작업 유형**: code

---

## 📋 작업 내용

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


---

## 실행 지침

1. 위 빅스텝 내용을 정확히 수행하세요
2. 중간에 확인 묻지 말고 끝까지 진행하세요
3. 작업 완료 후 결과 파일 생성 필수

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\result\small_038_01_result.md`에 저장할 것.**
