# SMALL_036_01 작업 결과

## 📋 작업 내용
맥에서 Flutter 웹 서버 실행 (새 터미널 창)

## ⚡ 실행 명령어
```bash
osascript -e 'tell app "Terminal" to do script "cd /Users/cwj/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d chrome --web-port=8080"'
```

## ✅ 실행 결과
- **상태**: 성공
- **출력**: `tab 1 of window id 6334`
- **결과**: 새 터미널 창(탭)이 생성되어 Flutter 웹 서버 실행 시작

## 📝 상세 내용
1. osascript가 새 터미널 탭을 성공적으로 생성
2. 터미널 window id 6334의 tab 1에서 실행 중
3. Flutter 앱이 chrome에서 포트 8080으로 실행 예정

## ⚠️ 주의사항
- 터미널에서 `/Users/cwj/.zprofile:1: command not found: ebal` 경고가 나타났지만 Flutter 명령어 실행에는 영향 없음
- 새 터미널 창에서 Flutter 빌드 진행 중

## 🎯 성공 조건 달성
✅ 새 터미널 창이 열리고 Flutter 빌드 시작됨