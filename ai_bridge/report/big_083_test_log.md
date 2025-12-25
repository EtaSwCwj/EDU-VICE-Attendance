# BIG_083 초대 기능 테스트 로그

## 테스트 일시
2025-12-23 12:13 ~ 12:15

## 주요 로그

### 1. 초기 앱 시작
```
[AuthState] 세션 확인 중...
[AuthState] 자동 로그인 비활성화
[LoginPage] 진입
[LoginPage] 저장된 자격증명 로드 시작
[LoginPage] 저장된 자격증명 로드 완료
```

### 2. Owner 계정 로그인 (owner_test1)
```
[LoginPage] 버튼 클릭: 로그인
[LoginPage] 로그인 시작: username=owner_test1
[AuthState] 로그인 시도: owner_test1
[AuthState] Step 1: Cognito 사용자 조회
[AuthState] Step 2: AppUser 조회
[AuthState]   AppUser: 원장님
[AuthState] Step 3: AcademyMember 조회
[AuthState]   role=owner, academyId=academy-001
[AuthState] Step 4: Academy 조회
[AuthState]   Academy: 수학의 정석 학원
[AuthState] Summary: user=원장님, role=owner, academy=수학의 정석 학원
[LoginPage] 로그인 성공
```

### 3. 초대 기능 사용
```
[OwnerManagementPage] 초대 관리 탭 진입
[InvitationManagementPage] 초대 메일 발송: user=최우준, role=student
```
- **초대 대상**: 최우준 (maknae12@gmail.com)
- **역할**: student

### 4. 로그아웃 및 재로그인 시도
```
[AuthState] 로그아웃 완료
[LoginPage] 진입
```

### 5. maknae12@gmail.com 계정 로그인 시도
```
[LoginPage] 버튼 클릭: 로그인
[LoginPage] 로그인 시작: username=maknae12@gmail.com
[AuthState] 로그인 시도: maknae12@gmail.com
[AuthState] Step 1: Cognito 사용자 조회
[AuthState] Step 2: AppUser 조회
[AuthState]   AppUser: 최우준
[AuthState] Step 3: AcademyMember 조회
[LoginPage] 로그인 성공
[AuthState] 로그아웃 완료
```
- AcademyMember가 없어서 자동 로그아웃됨

### 6. 에러 로그
```
[OwnerManagementPage] ERROR: currentMembership is null
```
- 로그아웃 후 OwnerManagementPage 접근 시 에러

## 상세 디버그 로그 (UserSyncService)
```
[UserSyncService] syncCurrentUser: START
[UserSyncService] Time: 2025-12-23 12:13:45.393076
[UserSyncService] Step 1: Getting current user...
[UserSyncService] ✓ Cognito user: username=maknae12@gmail.com, userId=a498ad1c-6011-70c6-2f00-92a2fad64b02
[UserSyncService] Step 2: Fetching user attributes...
[UserSyncService] ✓ Found 4 attributes
[UserSyncService]   - email: maknae12@gmail.com
[UserSyncService]   - email_verified: true
[UserSyncService]   - name: 최우준
[UserSyncService]   - sub: a498ad1c-6011-70c6-2f00-92a2fad64b02
[UserSyncService] ✓ Resolved email: maknae12@gmail.com, name: 최우준
[UserSyncService] Step 3: Checking if AppUser exists...
[UserSyncService] ✓ AppUser already exists: id=a498ad1c-6011-70c6-2f00-92a2fad64b02
```

## 역할 판단 로그 (maknae12@gmail.com)
```
[DEBUG] ========== 역할 판단 시작 ==========
[DEBUG] Cognito userId: a498ad1c-6011-70c6-2f00-92a2fad64b02
[DEBUG] Cognito username: maknae12@gmail.com
[DEBUG] AppUser 조회 결과: 있음 (id=a498ad1c-6011-70c6-2f00-92a2fad64b02, name=최우준)
[DEBUG] AcademyMember 조회 결과: 없음
[DEBUG] Cognito 그룹: []
[DEBUG] hasMembership: false
[DEBUG] 최종 role: null
[DEBUG] 소속 없음 → memberships: []
[DEBUG] ========== 역할 판단 끝 (NoAcademyShell) ==========
```

## 분석

### 성공한 부분
1. Owner 계정(owner_test1)으로 정상 로그인
2. 초대 관리 페이지 진입 성공
3. 초대 메일 발송 로직 실행 (UI상 성공)

### 문제점
1. maknae12@gmail.com 계정은 AcademyMember가 없어서 로그인 불가
2. currentMembership null 에러 발생 (로그아웃 후 페이지 접근 시)
3. 실제 이메일은 전송되지 않음

## 앱 빌드 정보
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
Running Gradle task 'assembleDebug'... 116.8s
```