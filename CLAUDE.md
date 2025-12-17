# Claude Code 프로젝트 설정

## 언어 설정
- 모든 대화는 한국어로 진행합니다
- 고유 명령어나 기술 용어는 "한글(영어)" 형식으로 표기합니다 (예: 빌드(build), 커밋(commit))
- 질문과 설명도 모두 한국어로 작성합니다

## 프로젝트 구조
- Flutter 앱 (lib/features/)
- AWS Amplify 백엔드 (amplify/)
- Clean Architecture 패턴

## 프로젝트 경로
- Git Bash: /c/gitproject/EDU-VICE-Attendance/flutter_application_1
- PowerShell: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- flutter run 실행 시 Git Bash 경로 사용할 것

---

## 📱 Flutter 앱 실행 방법

### 디바이스 확인
```bash
flutter devices
```

### 앱 실행 (SM-A356N 스마트폰)
```bash
cd /c/gitproject/EDU-VICE-Attendance/flutter_application_1 && flutter run -d RFCY40MNBLL
```

### 실행 시 규칙
1. 백그라운드 실행하지 말고 로그 실시간 출력
2. 앱 실행 성공하면 바로 알려주기
3. 주요 로그 추출해서 정리
4. 사용자가 "중지"라고 할 때까지 로그 모니터링 계속

---

## 📝 로그 규칙

### 태그 형식
`[페이지명]` 또는 `[서비스명]` 형식 사용
- 예: [AuthState], [OwnerHome], [TeacherShell], [StudentShell], [LessonPage]

### 주요 이벤트만 로그
| 이벤트 | 형식 | 예시 |
|--------|------|------|
| 페이지 진입 | [페이지명] 진입 | [OwnerHome] 진입 |
| 데이터 로드 | [페이지명] 데이터 로드: 성공/실패, 개수 | [LessonPage] 데이터 로드: 성공, 5개 |
| 버튼 클릭 | [페이지명] 버튼 클릭: 버튼명 | [StudentList] 버튼 클릭: 학생추가 |
| API 호출 | [Repository명] 결과: 성공/실패 | [TeacherAwsRepository] 결과: 성공 |
| 에러 | [페이지명] ERROR: 에러내용 | [AuthState] ERROR: 사용자 조회 실패 |

### 로그인 플로우 (AuthState)
```
[AuthState] Step 1: Cognito 인증
[AuthState] Step 2: AppUser 조회
[AuthState] Step 3: AcademyMember 조회
[AuthState] Step 4: Academy 조회
[AuthState] Summary: user=이름, role=역할, academy=학원명
```

### 로그 정리 원칙
- 디버깅용 print문 제거
- 중복 로그 제거
- 너무 상세한 로그 제거
- [ERROR], [WARNING] 로그는 항상 유지

---

## ✅ 필수 규칙

### 파일 수정 후
- **항상 flutter analyze 실행**
- 에러 0개 확인 후 다음 단계 진행
- 에러 발생 시 바로 수정 시도

---

## 📋 작업 완료 시 보고 형식

모든 작업 완료 후 아래 형식으로 요약:

```
📋 작업 요약
- 수정된 파일:
- 생성된 파일:
- 실행한 명령어:
- 현재 상태: (에러 여부, 테스트 결과 등)
- 다음 단계: (있으면)
```

---

## 🔧 AWS 관련

### 환경
- Region: ap-northeast-2
- 테이블 suffix: -3ozlrdq2pvesbe2mcnxgs5e6nu-dev

### 주요 테이블
- AppUser-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
- Academy-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
- AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
- Teacher-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
- Student-3ozlrdq2pvesbe2mcnxgs5e6nu-dev

### 테이블 확인 명령어
```bash
aws dynamodb scan --table-name [테이블명] --region ap-northeast-2
```

---

## 🚀 배포 명령어

```bash
amplify push --yes          # 스키마 배포
amplify codegen models      # Dart 모델 생성
```

---

## 🔄 데이터 흐름 (로그인 시)

1. Cognito 인증 → username 획득
2. AppUser 테이블 → cognitoUsername으로 사용자 조회
3. AcademyMember 테이블 → userId로 멤버십 조회 (role, academyId)
4. Academy 테이블 → academyId로 학원 정보 조회
5. Fallback: Cognito 그룹으로 역할 결정

---

## ⚠️ 주의사항

1. flutter run은 인터랙티브 프로세스 - 완료 대기하지 말고 로그 스트리밍
2. 에러 발생 시 바로 분석해서 알려주기
3. amplify push는 --yes 플래그로 확인 프롬프트 스킵
