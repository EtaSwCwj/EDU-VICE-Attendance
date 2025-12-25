@echo off
cd /d C:\gitproject\EDU-VICE-Attendance\flutter_application_1
start "Flutter Web Server" cmd /k "flutter run -d chrome --web-port=8080"
