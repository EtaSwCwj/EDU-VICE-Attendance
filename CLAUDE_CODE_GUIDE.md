# Claude Code 작업 가이드

## Flutter 앱 실행 방법

### 디바이스 확인
```bash
flutter devices
```

### 앱 실행 (SM-A356N 스마트폰)
```bash
flutter run -d RFCY40MNBLL
```

### 실행 시 규칙
1. 백그라운드 실행하지 말고 로그 실시간 출력
2. 앱 실행 성공하면 바로 알려주기
3. 주요 로그 ([AuthState], [Error], [Warning] 등) 추출해서 정리
4. 사용자가 "중지"라고 할 때까지 로그 모니터링 계속

---

## 작업 완료 시 보고 형식

모든 작업 완료 후 아래 형식으로 요약:

### 1. DynamoDB 테스트 데이터 (해당 시)
| 테이블 | ID | 데이터 |
|--------|-----|--------|
| Academy | academy-001 | 학원명 (코드) |
| AppUser | user-xxx | 이름 (username) |
| AcademyMember | member-xxx | role -> academyId |

### 2. 수정된 파일들
| 파일 | 변경 내용 |
|------|-----------|
| `lib/xxx.dart` | 변경 설명 |

### 3. 주요 로그 확인
```
[AuthState] Summary: user=xxx, role=xxx, academy=xxx
```

### 4. 테스트 결과
- 앱 실행: 성공/실패
- 로그인: 성공/실패
- 데이터 조회: 성공/실패

---

## AWS CLI 명령어

### DynamoDB 테이블 스캔
```bash
aws dynamodb scan --table-name Academy-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2
aws dynamodb scan --table-name AppUser-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --region ap-northeast-2
```

### DynamoDB 데이터 추가
```bash
aws dynamodb put-item --table-name [테이블명] --item "{...}" --region ap-northeast-2
```

### Amplify 명령어
```bash
amplify push --yes          # 스키마 배포
amplify codegen models      # Dart 모델 생성
```

---

## 프로젝트 구조

```
flutter_application_1/
├── lib/
│   ├── features/           # 기능별 모듈
│   │   ├── auth/           # 인증 (로그인/회원가입)
│   │   ├── home/           # 홈 화면 (Teacher/Owner Shell)
│   │   ├── owner/          # 원장 전용 기능
│   │   └── ...
│   ├── shared/
│   │   ├── models/         # 로컬 모델 (Account, Academy 등)
│   │   └── services/       # 서비스 (AuthState 등)
│   └── models/             # Amplify 생성 모델
└── amplify/
    └── backend/
        └── api/
            └── evattendance/
                └── schema.graphql  # GraphQL 스키마
```

---

## 역할 (Role) 정의

| 역할 | Cognito 그룹 | 설명 |
|------|-------------|------|
| owner | owners | 원장 (전체 관리 권한) |
| teacher | teachers | 선생님 |
| student | students | 학생 |

---

## 데이터 흐름

```
로그인 시:
1. Cognito 인증
2. AppUser 테이블에서 cognitoUsername으로 사용자 조회
3. AcademyMember 테이블에서 userId로 멤버십 조회 (role, academyId)
4. Academy 테이블에서 academyId로 학원 정보 조회
5. AuthState에 저장 -> UI 반영
```
