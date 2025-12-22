# BIG_074 테스트 보고서

## 📋 테스트 개요
- **일시**: 2025-12-22 23:58 ~ 23:59
- **테스트 플랫폼**: Android (SM A356N), Chrome Web
- **Flutter 앱 버전**: EDU-VICE Attendance

## 🎯 테스트 목표
2실린더 자동화 시스템을 활용한 크로스 플랫폼 동시 실행 및 로그 모니터링

## 📱 테스트 환경

### Android 디바이스
- **모델**: SM A356N
- **OS**: Android 15 (API 35)
- **연결**: USB (RFCY40MNBLL)
- **DevTools URL**: http://127.0.0.1:53944/Pz_yfNW2Nww=/devtools/

### Chrome 브라우저
- **버전**: Google Chrome 143.0.7499.170
- **포트**: 8081 (기본 8080 포트 충돌로 변경)
- **DevTools URL**: http://127.0.0.1:54152/lTu08NTQIS4=/devtools/

## 🔄 테스트 시나리오 및 결과

### 1. 앱 초기화
✅ **Android**: Amplify 초기화 성공
- DataStore 플러그인 추가 (오프라인 지원)
- AWS 리포지토리로 DI 완료

✅ **Chrome**: Amplify 초기화 성공
- DataStore 플러그인 건너뜀 (웹 플랫폼)
- AWS 리포지토리로 DI 완료

### 2. 로그인 테스트

#### Android - 학생 계정
- **계정**: maknae12@gmail.com (최우준)
- **역할**: student
- **소속**: 수학의 정석 학원
- **결과**: ✅ 로그인 성공

**상세 플로우**:
1. Cognito 인증: userId=a498ad1c-6011-70c6-2f00-92a2fad64b02
2. AppUser 조회: name=최우준
3. AcademyMember 조회: role=student, academyId=academy-001
4. Academy 조회: 수학의 정석 학원

#### Chrome - 원장 계정
- **계정**: owner_test1
- **역할**: owner
- **소속**: 수학의 정석 학원
- **결과**: ✅ 로그인 성공

**상세 플로우**:
1. Cognito 인증: userId=e4d84d4c-e0a1-7069-342f-fffadfcc80b6
2. AppUser 조회: name=원장님
3. AcademyMember 조회: role=owner, academyId=academy-001
4. Academy 조회: 수학의 정석 학원

### 3. 역할별 홈 화면

#### Android - StudentShell
✅ 정상 진입
- StudentHomePage: 0 lessons, 0 pending homework
- StudentLessonsPage: 0 today lessons
- StudentHomeworkPage: 0 pending, 0 completed
- ProfileAvatar: 프로필 이미지 로드 성공

#### Chrome - OwnerHomeShell
✅ 정상 진입
- TeacherClassesPage: 0 lessons
- TeacherHomeworkPageAws: 0 students, 1 books
- TeacherManagementTab: 1 teacher (본인), 0 students
- ProfileAvatar: 프로필 이미지 로드 성공

### 4. 로그아웃
- **Android**: ✅ 로그아웃 성공 → LoginPage 재진입
- **Chrome**: ✅ 로그아웃 성공 → LoginPage 재진입

## 🐛 발견된 이슈

### 1. 환경 이슈
- **Android**: gralloc4 에러 발생 (그래픽 버퍼 할당 실패)
  ```
  E/gralloc4(27023): ERROR: Unrecognized and/or unsupported format 0x3b
  ```
  → 영향: 앱 실행에는 영향 없음 (경고 수준)

- **Chrome**: 초기 포트 충돌 (8080 → 8081 변경으로 해결)

### 2. 성능 이슈
- **Android**: UI 스레드 부하로 프레임 드롭
  ```
  I/Choreographer(27023): Skipped 40 frames!
  ```
  → 권장: 무거운 작업을 비동기 처리로 이전

### 3. 설정 이슈
- **Android**: OnBackInvokedCallback 미설정 경고
  ```
  W/WindowOnBackDispatcher(27023): Set 'android:enableOnBackInvokedCallback="true"'
  ```

## 📊 로그 패턴 분석

### 정상 패턴
1. [main] 진입 → Amplify 초기화 → DI 초기화
2. [Splash] → [AuthState] 세션 확인 → [LoginPage]
3. 로그인 → UserSyncService → 역할별 Shell 진입
4. 데이터 로드 → UI 업데이트

### 로그 태그 활용도
- **우수**: AuthState, UserSyncService, 페이지별 진입 로그
- **개선 필요**: AWS Repository 응답 시간 로깅

## 🎯 테스트 결론

### 성공 사항
1. ✅ 크로스 플랫폼 동시 실행 성공
2. ✅ 역할별 인증 및 라우팅 정상 작동
3. ✅ AWS Amplify 통합 정상
4. ✅ 로그 태그 시스템 효과적

### 개선 사항
1. 📌 Android 성능 최적화 필요
2. 📌 에러 핸들링 강화 (gralloc4 등)
3. 📌 로딩 상태 표시 개선
4. 📌 데이터 없음 상태 UI 개선

## 💡 권장 사항

1. **성능 최적화**
   - 초기 로딩 시 무거운 작업 비동기 처리
   - 이미지 로딩 최적화 (캐싱 강화)

2. **로깅 개선**
   - API 응답 시간 측정 추가
   - 에러 발생 위치 상세 기록

3. **테스트 자동화**
   - 역할별 시나리오 자동화 스크립트
   - 성능 메트릭 자동 수집

---

## 📝 테스트 요약

2실린더 자동화 시스템을 통한 Android/Chrome 동시 테스트 성공적으로 완료.
주요 기능들이 양 플랫폼에서 정상 작동하며, 로그 태그 시스템이 디버깅에 효과적임을 확인.