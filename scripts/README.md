# 웹 테스트 환경 실행 가이드

## 🚀 실행 방법

### 1. 웹 서버 시작
```bash
# scripts 폴더에서 실행
.\run_web_test.bat
```

또는 PowerShell에서:
```powershell
cd C:\gitproject\EDU-VICE-Attendance\scripts
.\run_web_test.bat
```

### 2. 테스트 환경 설정

#### 첫 번째 창 (일반 모드)
- URL: http://localhost:8080
- 용도: 계정 A로 로그인

#### 두 번째 창 (시크릿 모드)
1. Chrome에서 **Ctrl+Shift+N** 으로 시크릿 창 열기
2. http://localhost:8080 접속
3. 용도: 계정 B로 로그인

## 📱 테스트 시나리오

### 동시 접속 테스트
- **관리자** vs **선생님**: 같은 시간에 다른 역할로 접속
- **선생님** vs **학생**: 수업 중 실시간 출석체크
- **학부모** vs **학생**: 출석 현황 확인

### 실시간 기능 테스트
- 출석 체크 동기화
- 알림 기능
- 데이터 실시간 업데이트

## ⚠️ 주의사항

1. **포트 충돌**: 8080 포트가 사용 중이면 다른 포트 사용
2. **CORS 에러**: --disable-web-security 플래그로 해결
3. **캐시 문제**: 시크릿 모드 사용으로 해결

## 🔧 문제해결

### 포트 변경이 필요한 경우
```bash
# run_web_test.bat 파일에서 포트 번호 변경
--web-port=8081  # 다른 포트로 변경
```

### 브라우저별 시크릿 모드
- **Chrome**: Ctrl+Shift+N
- **Edge**: Ctrl+Shift+P
- **Firefox**: Ctrl+Shift+P

## 🎯 테스트 목표

✅ 다중 계정 동시 접속
✅ 실시간 데이터 동기화
✅ 역할별 기능 검증
✅ 모바일/웹 크로스 플랫폼