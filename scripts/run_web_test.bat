@echo off
echo ======================================
echo EDU-VICE 출석 시스템 웹 테스트 실행
echo ======================================
echo.

cd /d C:\gitproject\EDU-VICE-Attendance\flutter_application_1

echo Flutter 웹 서버 시작 중...
echo 포트: 8080
echo URL: http://localhost:8080
echo.

echo ======================================
echo 테스트 환경 안내:
echo ======================================
echo 1. 첫 번째 창: http://localhost:8080 (일반 모드)
echo 2. 두 번째 창: http://localhost:8080 (시크릿 모드)
echo ======================================
echo.
echo 시크릿 모드로 두 번째 창을 열어서 다른 계정으로 테스트하세요!
echo 중지하려면 Ctrl+C를 누르세요.
echo.

flutter run -d chrome --web-port=8080 --web-browser-flag="--disable-web-security"