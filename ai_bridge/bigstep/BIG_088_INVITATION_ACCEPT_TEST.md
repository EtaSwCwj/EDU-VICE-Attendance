# BIG_088: 초대 수락 테스트

> 생성일: 2025-12-25
> 목표: Lambda + Invitation update 권한 추가 후 초대 수락 기능 테스트

---

## 🎯 기대 결과 & 테스트 시나리오

> **CP 확인용**: 이 작업이 성공하면 어떻게 되는지

### 기대 결과
- maknae12@gmail.com이 초대 수락하면 학원 홈 화면으로 이동
- Lambda가 AcademyMember 자동 생성
- 에러 없이 정상 동작

### 테스트 시나리오
```
1. owner_test1 로그인 → maknae12@gmail.com에게 초대 발송
2. maknae12@gmail.com 로그인 → "받은 초대" 목록에 초대 표시됨
3. "수락" 버튼 클릭 → 성공 메시지 표시
4. 학원 홈 화면으로 자동 이동 → 테스트 성공!
```

---

## 환경

- 프로젝트: C:\gitproject\EDU-VICE-Attendance\flutter_application_1
- 테스트 계정: 
  - 초대자: owner_test1 (수학의 정석 학원 원장)
  - 피초대자: maknae12@gmail.com

---

## 스몰스텝

### 1. 테스트 계정 리셋 (AWS CLI)

```bash
# Invitation 테이블 조회
aws dynamodb scan --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "inviteeEmail = :email" --expression-attribute-values '{":email":{"S":"maknae12@gmail.com"}}' --region ap-northeast-2

# 있으면 삭제
aws dynamodb delete-item --table-name Invitation-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2

# AcademyMember 테이블 조회
aws dynamodb scan --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --filter-expression "userId = :uid" --expression-attribute-values '{":uid":{"S":"a498ad1c-6011-70c6-2f00-92a2fad64b02"}}' --region ap-northeast-2

# 있으면 삭제
aws dynamodb delete-item --table-name AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev --key '{"id":{"S":"조회된ID"}}' --region ap-northeast-2
```

### 2. 앱 빌드

```bash
cd C:\gitproject\EDU-VICE-Attendance\flutter_application_1
flutter run -d RFCY40MNBLL
```

### 3. 초대 발송 테스트

- [ ] owner_test1로 로그인
- [ ] 이메일 검색 또는 초대 버튼으로 maknae12@gmail.com 초대
- [ ] 초대 발송 성공 확인

### 4. 초대 수락 테스트

- [ ] 로그아웃
- [ ] maknae12@gmail.com으로 로그인
- [ ] "받은 초대" 목록에 초대 표시 확인
- [ ] "수락" 버튼 클릭
- [ ] 성공 메시지 확인
- [ ] 학원 홈 화면으로 이동 확인

### 5. Lambda 로그 확인 (선택)

AWS Console → CloudWatch → Log groups → `/aws/lambda/invitationAcceptTrigger-dev`

확인할 것:
- `[invitationAcceptTrigger] Status: pending -> accepted`
- `[invitationAcceptTrigger] Created: [AcademyMember ID]`

---

## 에러 발생 시

### "Not Authorized" 에러
- schema.graphql 권한 확인
- amplify push 완료됐는지 확인

### Lambda 트리거 안 됨
- AWS Console → Lambda → invitationAcceptTrigger-dev → Triggers 확인
- DynamoDB Stream 연결됐는지 확인

### 학원 화면 안 넘어감
- refreshAuth() 호출됐는지 로그 확인
- AcademyMember 테이블에 데이터 생성됐는지 확인

---

## 완료 조건

1. 초대 발송 성공
2. 초대 수락 성공 (에러 없음)
3. 학원 홈 화면으로 이동
4. CP가 "테스트 종료" 입력
5. 보고서 작성 완료 (ai_bridge/report/big_088_report.md)
