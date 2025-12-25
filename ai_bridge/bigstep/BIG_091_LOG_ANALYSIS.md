# BIG_091: 초대 수락 후 화면 전환 로그 분석

> 생성일: 2025-12-25
> 목표: 초대 수락 후 화면 전환이 안 되는 원인 파악 (로그 분석)

---

## 🎯 기대 결과 & 테스트 시나리오

### 기대 결과
- 로그를 통해 화면 전환 실패 원인 파악
- Lambda 완료 감지 여부 확인
- AuthState 갱신 여부 확인

### 테스트 시나리오
```
1. 테스트 계정 리셋
2. 앱 빌드 (flutter run)
3. owner_test1로 초대 발송
4. maknae12@gmail.com으로 로그인 → 수락 클릭
5. 콘솔 로그 캡쳐
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 테스트 계정:
  - 초대자: owner_test1
  - 피초대자: maknae12@gmail.com (AppUser ID: a498ad1c-6011-70c6-2f00-92a2fad64b02)

---

## 스몰스텝

### 1. 테스트 계정 리셋

**Invitation 삭제:**
```bash
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2
```
→ 결과 있으면 삭제

**AcademyMember 삭제:**
```bash
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2
```
→ 결과 있으면 삭제

### 2. 앱 빌드

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL
```

### 3. 테스트 진행

- [ ] owner_test1로 로그인 → maknae12@gmail.com에게 초대 발송 → 로그아웃
- [ ] maknae12@gmail.com으로 로그인
- [ ] "수락" 버튼 클릭
- [ ] **콘솔 로그 캡쳐** (중요!)

### 4. 로그에서 확인할 것 (필수!)

**✅ 이 메시지들이 나오는지 확인:**

```
[NoAcademyShell] 초대 수락 클릭: {invitation_id}
[NoAcademyShell] Invitation 업데이트 성공: {id}, status=accepted
[NoAcademyShell] Lambda 대기 중... (시도 1/20)
[NoAcademyShell] Lambda 대기 중... (시도 2/20)
...
[NoAcademyShell] Lambda 완료 감지: AcademyMember 생성됨 (시도 X/20)   ← 이거 나오는지!
[AuthState] Summary: user=최우준, role=student, academy=수학의 정석 학원  ← 이거 나오는지!
[NoAcademyShell] GoRouter를 사용한 홈 화면 전환 실행
[NoAcademyShell] 홈 화면 전환 완료
```

**❌ 이런 메시지가 나오면 문제:**

```
[NoAcademyShell] Lambda 대기 중... (시도 20/20)
[NoAcademyShell] ERROR: 초대 수락 실패 - Exception: Lambda 처리 시간 초과
```

또는:

```
[DEBUG] AcademyMember 조회 결과: 없음
[DEBUG] 소속 없음 → memberships: []
```

---

## 로그 저장

- [ ] ai_bridge/logs/big_091_console.log (콘솔 로그 전체)

---

## 분석 후 다음 단계

### 케이스 A: "Lambda 완료 감지" 메시지 없음
→ Lambda가 AcademyMember 생성 안 함 or 느림
→ CloudWatch 로그 확인 필요

### 케이스 B: "Lambda 완료 감지" 있는데 화면 전환 안 됨
→ GoRouter redirect 로직 문제
→ app_router.dart 수정 필요

### 케이스 C: AuthState Summary에 role/academy 없음
→ _loadUserInfo() 에서 AcademyMember 조회 실패
→ auth_state.dart 수정 필요

---

## 완료 조건

1. 테스트 실행 완료
2. 콘솔 로그 저장 (ai_bridge/logs/big_091_console.log)
3. 위 체크포인트 메시지 확인 결과 보고
4. 보고서 작성 완료 (ai_bridge/report/big_091_report.md)
