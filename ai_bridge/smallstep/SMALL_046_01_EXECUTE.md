# SMALL_046_01_EXECUTE.md

> **빅스텝**: BIG_046_WAIT_READY.md
> **작업 유형**: code

---

## 📋 작업 내용

# BIG_046: 맥 웹 서버 완전 준비 후 사파리 열기

> **작성자**: 맥선임 (Desktop Opus)
> **작성일**: 2025-12-21

---

## 📋 작업

기존 웹 서버 터미널에서 `q` 눌러서 종료하고, 새로 실행:

```bash
osascript -e 'tell app "Terminal" to activate' -e 'tell app "Terminal" to do script "/Users/cwj/gitproject/EDU-VICE-Attendance/scripts/start_web_mac.sh"'
```

**개선점**: main.dart.js 로드될 때까지 대기 + 추가 2초 안전 마진

**성공 조건**: 사파리 열리면 바로 앱 화면 나옴 (새로고침 필요 없음)


---

## 실행 지침

1. 위 빅스텝 내용을 정확히 수행하세요
2. 중간에 확인 묻지 말고 끝까지 진행하세요
3. 작업 완료 후 결과 파일 생성 필수

**결과는 `C:\gitproject\EDU-VICE-Attendance\ai_bridge\result\small_046_01_result.md`에 저장할 것.**
